import 'dart:convert';

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _task(String id) => _key('task-checkbox-$id');
Finder _menu(int index) => _key('task-settings').at(index);

const _notes =
    '[{"id":"note","name":"My note","createdAt":"2026-11-11T10:00:00.000Z","content":"Note body"}]';

Future<void> _load(WidgetTester tester, String theme,
    {String linkedText = 'Linked task',
    Map<String, Object> saved = const {}}) async {
  SharedPreferences.setMockInitialValues({
    'checklist.welcome.v1': true,
    'checklist.lastSeenVersion.v1': checklistRelease,
    'checklist.theme.v1': theme,
    'checklist.notes.v1': _notes,
    'checklist.projects.v1':
        '[{"id":"project","name":"My checklist","createdAt":"2026-11-11T10:00:00.000Z","tasks":['
            '{"id":"linked","text":${jsonEncode(linkedText)},"isDone":false,"linkedNoteId":"note"},'
            '{"id":"unlinked","text":"Unlinked task","isDone":false}]}]',
    ...saved,
  });
  tester.view.physicalSize = const Size(400, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const ChecklistApp());
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('The task menu unlinks a note while keeping it in Notes',
      (tester) async {
    await _load(tester, 'boi');
    await _tap(tester, _menu(1));
    expect(find.text('- note'), findsNothing);
    await tester.tapAt(const Offset(8, 20));
    await tester.pumpAndSettle();

    expect(_key('task-note-below-checkbox-linked'), findsOneWidget);
    await _tap(tester, _menu(0));
    await _tap(tester, find.text('- note'));
    expect(_key('task-note-below-checkbox-linked'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.notes.v1'), _notes);
    final projects =
        jsonDecode(prefs.getString('checklist.projects.v1')!) as List;
    expect(projects.single['tasks'][0]['linkedNoteId'], isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'Pixel glows on completion and keeps its square dots lit in menus',
      (tester) async {
    await _load(tester, 'pixel');
    final checked = _task('linked');
    final glow =
        find.descendant(of: checked, matching: _key('task-checkbox-glow'));
    final progress = _key('pixel-progress-fill');
    expect(glow, findsNothing);
    expect(progress, findsNothing);
    await _tap(tester, checked);
    expect(glow, findsOneWidget);
    expect(progress, findsOneWidget);
    final fill =
        tester.widget<DecoratedBox>(progress).decoration as BoxDecoration;
    expect(fill.boxShadow!.single.color,
        const Color(0xFFA9FF42).withValues(alpha: .60));

    final dots =
        find.descendant(of: _menu(0), matching: _key('pixel-settings-dots'));
    CustomPainter painter() => tester.widget<CustomPaint>(dots).painter!;
    final idle = painter();
    await _tap(tester, _menu(0));
    expect(find.text('edit'), findsOneWidget);
    expect(painter().shouldRepaint(idle), isTrue);
    await tester.tapAt(const Offset(8, 20));
    await tester.pumpAndSettle();
    expect(painter().shouldRepaint(idle), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk checkbox and menu flash yellow then settle to red',
      (tester) async {
    await _load(tester, 'cyberpunk');
    final checkbox =
        find.descendant(of: _task('linked'), matching: find.byType(Checkbox));
    Checkbox box() => tester.widget<Checkbox>(checkbox);
    Color fill() => box().fillColor!.resolve({WidgetState.selected})!;
    expect(
        box().shape,
        const BeveledRectangleBorder(
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
        ));
    const red = Color(0xFFFF2349);
    const yellow = Color(0xFFF3ED23);
    expect(fill(), red);
    expect(box().side!.width, 1);
    expect(box().checkColor, Colors.transparent);
    final tick = find.descendant(
        of: _task('linked'), matching: _key('cyberpunk-thin-tick'));
    expect(tick, findsNothing);
    await tester.tap(checkbox);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(fill(), yellow);
    final pulse = find.descendant(
        of: _task('linked'), matching: _key('cyberpunk-control-glitch'));
    expect(
        tester
            .widget<Transform>(find
                .descendant(of: pulse, matching: find.byType(Transform))
                .first)
            .transform
            .getTranslation()
            .x,
        isNot(0));
    await tester.pumpAndSettle();
    expect(fill(), red);
    expect(tick, findsOneWidget);

    final dots = find.descendant(
        of: _menu(0), matching: find.byIcon(Icons.more_vert_rounded));
    Icon icon() => tester.widget<Icon>(dots);
    expect(icon().color, red);
    expect(icon().shadows, isNull);
    await tester.tap(_menu(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(icon().color, yellow);
    await tester.pumpAndSettle();
    expect(icon().color, red);
    expect(icon().shadows, isNotEmpty);
    expect(find.text('edit'), findsOneWidget);
    await tester.tapAt(const Offset(8, 20));
    await tester.pumpAndSettle();
    expect(icon().shadows, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk moving signals repaint after applying an HSV colour',
      (tester) async {
    await _load(tester, 'cyberpunk');
    final background = find.descendant(
      of: _key('workspace-surface'),
      matching: _key('cyberpunk-circuit-background'),
    );
    CustomPainter signals() {
      final boundary = tester.widget<RepaintBoundary>(find.descendant(
        of: background,
        matching: find
            .byWidgetPredicate((w) => w is RepaintBoundary && w.key == null),
      ));
      return (boundary.child! as CustomPaint).painter!;
    }

    final original = signals();
    await _tap(tester, find.byTooltip('open menu'));
    await _tap(tester, _key('settings-toggle'));
    await _tap(tester, _key('settings-themes'));
    final customise = _key('theme-customise');
    await tester.ensureVisible(customise);
    await _tap(tester, customise);
    await _tap(tester, _key('theme-colour-background'));
    tester.widget<Slider>(_key('theme-hsv-hue')).onChanged!(210);
    tester.widget<Slider>(_key('theme-hsv-saturation')).onChanged!(.7);
    tester.widget<Slider>(_key('theme-hsv-value')).onChanged!(.6);
    await tester.pump();
    await _tap(tester, find.widgetWithText(FilledButton, 'save'));
    expect(signals().shouldRepaint(original), isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk has blue frames and half-opacity task dividers',
      (tester) async {
    await _load(tester, 'cyberpunk');
    const blue = Color(0xFF379BFF);
    final theme = Theme.of(tester.element(_key('workspace-surface')));
    expect(theme.colorScheme.outline, blue);
    expect((theme.popupMenuTheme.shape! as OutlinedBorder).side.color, blue);
    expect(tester.widget<Divider>(_key('checklist-task-divider')).color,
        blue.withValues(alpha: .5));
    final reminder =
        tester.widget<OutlinedButton>(_key('checklist-reminder-button'));
    expect(reminder.style!.side!.resolve({})!.color, blue);
    await _tap(tester, find.byTooltip('open menu'));
    final create = tester.widget<FilledButton>(_key('sidebar-create-button'));
    expect(create.style!.side!.resolve({})!.color, blue);
    await _tap(tester, _key('sidebar-create-button'));
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect((dialog.shape! as OutlinedBorder).side.color, blue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Pastel uses Android corner geometry and credits its two fonts',
      (tester) async {
    const display = MethodChannel('checklist/display');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(display, (call) async {
      expect(call.method, 'roundedCornerRadius');
      return 24.0;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(display, null));
    await _load(tester, 'pastel');
    final theme = Theme.of(tester.element(_key('workspace-surface')));
    const corners = BorderRadius.all(Radius.circular(24));
    final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, corners);
    expect(shape.side, BorderSide.none);
    expect(
        (theme.inputDecorationTheme.border! as OutlineInputBorder).borderRadius,
        corners);
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Coiny');
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Nunito');
    expect(_key('pastel-workspace-backdrop'), findsOneWidget);
    final lifted =
        tester.widgetList<DecoratedBox>(_key('pastel-beveled-surface'));
    expect(lifted, isNotEmpty);
    expect(_key('checklist-task-divider'), findsNothing);
    final taskPlate = lifted.singleWhere((widget) => find
        .descendant(
          of: find.byWidget(widget),
          matching: _key('task-note-opener-linked'),
        )
        .evaluate()
        .isNotEmpty);
    final surface = taskPlate.decoration as BoxDecoration;
    expect(surface.borderRadius, corners);
    expect(surface.boxShadow, hasLength(2));
    expect(surface.boxShadow!.first.offset.dx, greaterThan(0));
    expect(surface.boxShadow!.last.offset.dx, lessThan(0));
    expect(theme.dialogTheme.elevation, 7);
    expect(theme.iconButtonTheme.style!.backgroundBuilder, isNotNull);
    expect(theme.filledButtonTheme.style!.side!.resolve({}), BorderSide.none);
    final drawer = _key('pastel-drawer-button');
    final drawerGlyph =
        find.descendant(of: drawer, matching: find.byIcon(Icons.menu_rounded));
    final icon = tester.widget<Icon>(drawerGlyph);
    expect(icon.color, Colors.white);
    expect(icon.shadows!.first.color, Colors.white);
    expect(icon.shadows!.first.blurRadius, greaterThan(0));
    final travel =
        find.ancestor(of: drawer, matching: _key('pastel-press-travel'));
    double depth() =>
        tester.widget<Transform>(travel).transform.getTranslation().y;
    expect(depth(), 0);
    final press = await tester.startGesture(tester.getCenter(drawer));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(depth(), inExclusiveRange(0, 1.2));
    await press.cancel();
    await tester.pumpAndSettle();
    expect(depth(), 0);

    await _tap(tester, _key('checklist-reminder-button'));
    final calendar = _key('checklist-reminder-calendar');
    expect(
        find.ancestor(of: calendar, matching: _key('pastel-beveled-surface')),
        findsOneWidget);
    final calendarDialog =
        tester.widget<AlertDialog>(_key('checklist-reminder-dialog'));
    expect(calendarDialog.scrollable, isTrue);
    expect(tester.getSize(calendar).width, greaterThanOrEqualTo(300));
    expect(tester.getSize(_key('checklist-reminder-time')).height,
        greaterThanOrEqualTo(48));
    final date = Theme.of(tester.element(calendar)).datePickerTheme;
    expect(date.todayBorder, BorderSide.none);
    expect(date.dayBackgroundColor!.resolve({WidgetState.selected}), isNotNull);
    expect(
      theme.outlinedButtonTheme.style!.foregroundColor!.resolve({}),
      const Color(0xFF75445F),
    );
    await _tap(tester, find.text('cancel'));

    await _tap(tester, find.byTooltip('open menu'));
    final create = tester.widget<FilledButton>(_key('sidebar-create-button'));
    expect(create.style!.backgroundColor!.resolve({}), const Color(0xFFE5E0F2));
    await _tap(tester, _key('settings-toggle'));
    await _tap(tester, _key('settings-about'));
    await _tap(tester, _key('about-credits'));
    expect(find.text('Marcelo Magalhães'), findsOneWidget);
    expect(
        find.text('Vernon Adams, Cyreal, Jacques Le Bailly'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Pixel settings use pixel glyphs with an active glow',
      (tester) async {
    await _load(tester, 'pixel');
    await _tap(tester, find.byTooltip('open menu'));
    final gear =
        _key('pixel-settings-glyph-${Icons.settings_outlined.codePoint}');
    final closed = tester.widget<CustomPaint>(gear).painter!;
    await _tap(tester, _key('settings-toggle'));
    final opened = tester.widget<CustomPaint>(gear).painter!;
    expect(opened.shouldRepaint(closed), isTrue);
    expect(_key('pixel-settings-glyph-${Icons.palette_outlined.codePoint}'),
        findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Pastel Settings is flat apart from its aligned arrow',
      (tester) async {
    await _load(tester, 'pastel');
    await _tap(tester, find.byTooltip('open menu'));
    final chevron = _key('settings-chevron');
    double x(Finder target) => tester.getCenter(target).dx;
    expect(x(chevron), closeTo(x(_key('sidebar-checklist-settings')), .001));
    final bevel = _key('pastel-press-depth');
    expect(find.descendant(of: chevron, matching: bevel), findsOneWidget);
    await tester.tap(_key('settings-toggle'));
    await tester.pump();
    expect(tester.widget<Text>(find.text('settings')).style!.shadows, isNull);
    await tester.pumpAndSettle();
    expect(find.descendant(of: _key('settings-panel'), matching: bevel),
        findsOneWidget);
    await _tap(tester, _key('settings-about'));
    expect(find.descendant(of: _key('settings-panel'), matching: bevel),
        findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('NOTES'));
    expect(x(chevron), closeTo(x(_key('sidebar-note-settings')), .001));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Milk retains the saved preference and SV has its own finish',
      (tester) async {
    await _load(tester, 'pastel');
    expect(_key('pastel-workspace-backdrop'), findsOneWidget);
    expect(_key('sv-landscape'), findsNothing);
    await _tap(tester, find.byTooltip('open menu'));
    await _tap(tester, _key('settings-toggle'));
    await _tap(tester, _key('settings-themes'));
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Pastel'), findsNothing);
    await tester.ensureVisible(_key('theme-sv'));
    await _tap(tester, _key('theme-sv'));
    expect(_key('sv-landscape'), findsOneWidget);
    expect(_key('pastel-workspace-backdrop'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.theme.v1'), 'sv');
    final theme = Theme.of(tester.element(_key('workspace-surface')));
    expect(theme.brightness, Brightness.light);
    expect(theme.textTheme.headlineMedium!.fontFamily, 'VT323');
    expect(theme.textTheme.bodyMedium!.fontFamily, 'VT323');
    expect(
        tester
            .widget<AnimatedDefaultTextStyle>(_key('checklist-word-style'))
            .style
            .fontFamily,
        'Press Start 2P');
    await tester.tapAt(const Offset(375, 130));
    await tester.pumpAndSettle();
    final cards = _key('sv-task-card');
    expect(cards, findsNWidgets(2));
    final face =
        tester.widget<DecoratedBox>(cards.first).decoration as ShapeDecoration;
    expect(face.color, const Color(0xFFFFECC8));
    expect((face.shape as OutlinedBorder).side.color, const Color(0xFF764330));
    await _tap(tester, _key('checklist-reminder-button'));
    final popup = tester.widget<AlertDialog>(_key('checklist-reminder-dialog'));
    expect(popup.shape, theme.dialogTheme.shape);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Milk category popup keeps labels and actions apart on mobile',
      (tester) async {
    await _load(tester, 'pastel', saved: {
      'checklist.noteCategories.v1': jsonEncode([
        for (var index = 0; index < 12; index++)
          {
            'id': 'category-$index',
            'name': 'An unusually long category name $index',
            'colorValue': 0xFF3977E3,
          }
      ]),
    });
    await _tap(tester, find.byTooltip('open menu'));
    await _tap(tester, find.bySemanticsLabel('NOTES'));
    await tester.tapAt(const Offset(375, 135));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 540);
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await _tap(tester, find.byTooltip('change category'));
    final popup = _key('category-picker-dialog');
    final dialog = tester.widget<AlertDialog>(popup);
    expect(dialog.scrollable, isTrue);
    expect(dialog.clipBehavior, Clip.antiAlias);
    expect(Theme.of(tester.element(popup)).popupMenuTheme.menuPadding,
        const EdgeInsets.symmetric(horizontal: 5, vertical: 8));
    final title =
        find.descendant(of: popup, matching: find.text('change category'));
    final first = find.text('An unusually long category name 0');
    expect(tester.getRect(title).bottom, lessThan(tester.getRect(first).top));
    final buttons = [
      for (final label in ['cancel', 'new', 'remove'])
        tester.getRect(find.text(label)),
    ];
    expect(buttons[0].right, lessThan(buttons[1].left));
    expect(buttons[1].right, lessThan(buttons[2].left));
    await _tap(tester, _key('category-cancel-button'));
    expect(popup, findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk Settings icons are red and glow while open',
      (tester) async {
    await _load(tester, 'cyberpunk');
    await _tap(tester, find.byTooltip('open menu'));
    const red = Color(0xFFFF2349);
    final gear = find.descendant(
        of: _key('settings-toggle'),
        matching: find.byIcon(Icons.settings_outlined));
    final arrow = find.descendant(
        of: _key('settings-chevron'),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded));
    for (final finder in [gear, arrow]) {
      final icon = tester.widget<Icon>(finder);
      expect(icon.color, red);
      expect(icon.shadows, isNull);
    }
    await _tap(tester, _key('settings-toggle'));
    for (final finder in [
      gear,
      arrow,
      find.byIcon(Icons.translate_rounded),
      find.byIcon(Icons.info_outline_rounded),
    ]) {
      final icon = tester.widget<Icon>(finder);
      expect(icon.color, red);
      expect(icon.shadows!.single.blurRadius, greaterThan(0));
    }
    await _tap(tester, _key('settings-chevron'));
    expect(tester.widget<Icon>(gear).shadows, isNull);
    expect(tester.widget<Icon>(arrow).shadows, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'Pastel progress fills its recess and priority controls are larger',
      (tester) async {
    await _load(tester, 'pastel');
    final track = _key('pastel-progress-track');
    final fill = _key('pastel-progress-fill');
    expect(track, findsOneWidget);
    expect(fill, findsNothing);
    final dynamic recess = tester.widget<CustomPaint>(track).painter;
    expect(recess.colour, isNull);
    expect(recess.depth, 1);

    await _tap(tester, _task('linked'));
    BoxDecoration face(Finder widget) =>
        tester.widget<DecoratedBox>(widget).decoration as BoxDecoration;
    final row = find.ancestor(
      of: _key('task-row-linked'),
      matching: _key('pastel-beveled-surface'),
    );
    expect(face(fill).color, const Color(0xFFCFE8DA));
    expect(face(fill).color, face(row).color);
    expect(tester.getSize(fill).width,
        closeTo(tester.getSize(track).width / 2, 1));
    final dynamic raised = tester
        .widget<CustomPaint>(
            find.descendant(of: fill, matching: find.byType(CustomPaint)))
        .foregroundPainter;
    expect(raised.depth, 0);

    final priority = _key('priority-chip-normal');
    expect(tester.getSize(priority).height, greaterThanOrEqualTo(44));
    await _tap(tester, priority);
    final option = find.ancestor(
      of: _key('priority-menu-high'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    expect(tester.getSize(option).height, 54);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'Pastel uses readable ink on light surfaces and priority controls',
      (tester) async {
    const yellow = Color(0xFFF3ED23);
    await _load(tester, 'pastel', saved: {
      'checklist.notes.v1':
          '[{"id":"note","name":"My note","createdAt":"2026-11-11T10:00:00.000Z","content":"Note body","categoryId":"bright"}]',
      'checklist.noteCategories.v1': jsonEncode([
        {'id': 'bright', 'name': 'Sunshine', 'colorValue': yellow.toARGB32()},
      ]),
    });
    const muted = Color(0xFF5E5267);
    final composer = tester.widget<TextField>(find.byType(TextField));
    expect(composer.decoration!.hintStyle!.color, muted);
    final dots = find.descendant(
        of: _menu(0), matching: find.byIcon(Icons.more_vert_rounded));
    expect(tester.widget<Icon>(dots).color, muted);

    Color textColour(Finder target) =>
        tester.widget<Text>(target).style!.color!;
    double contrast(Color ink, Color surface) =>
        (surface.computeLuminance() + .05) / (ink.computeLuminance() + .05);
    final priority = _key('priority-chip-normal');
    final tint =
        (tester.widget<Container>(priority).decoration as BoxDecoration).color!;
    final priorityText =
        find.descendant(of: priority, matching: find.text('medium'));
    const clay = Color(0xFFE8EFF5);
    expect(contrast(textColour(priorityText), Color.alphaBlend(tint, clay)),
        greaterThanOrEqualTo(4.5));

    await _tap(tester, find.byTooltip('open menu'));
    expect(textColour(_key('sidebar-item-count')), muted);
    await _tap(tester, find.bySemanticsLabel('NOTES'));
    final row = find.widgetWithText(ListTile, 'My note');
    final title = find.descendant(of: row, matching: find.text('My note'));
    expect(contrast(textColour(title), clay), greaterThanOrEqualTo(4.5));
    final dot = (tester.widget<ListTile>(row).leading! as dynamic);
    expect(dot.color, yellow);
    await tester.tapAt(const Offset(375, 120));
    await tester.pumpAndSettle();
    expect(contrast(textColour(find.text('Sunshine')), clay),
        greaterThanOrEqualTo(4.5));
    expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .decoration!
            .hintStyle!
            .color,
        muted);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final appearance in ['pixel', 'pastel', 'cyberpunk', 'sv']) {
    testWidgets(
        'Notes formatting, category and camera controls use $appearance',
        (tester) async {
      const categoryInk = Color(0xFF229FE3);
      await _load(tester, appearance, saved: {
        'checklist.notes.v1':
            '[{"id":"note","name":"My note","createdAt":"2026-11-11T10:00:00.000Z","content":"Note body","categoryId":"custom"}]',
        'checklist.noteCategories.v1': jsonEncode([
          {
            'id': 'custom',
            'name': 'Custom colour',
            'colorValue': categoryInk.toARGB32()
          },
        ]),
      });
      await _tap(tester, find.byTooltip('open menu'));
      await _tap(tester, find.bySemanticsLabel('NOTES'));
      await tester.tapAt(const Offset(375, 120));
      await tester.pumpAndSettle();
      if (appearance == 'pixel') {
        for (final icon in [
          Icons.format_bold_rounded,
          Icons.format_italic_rounded,
          Icons.format_underlined_rounded,
          Icons.label_outline_rounded,
          Icons.add_rounded,
        ]) {
          expect(_key('pixel-note-glyph-${icon.codePoint}'), findsOneWidget);
        }
        Color glyphColour(IconData icon) {
          final glyph = _key('pixel-note-glyph-${icon.codePoint}');
          final dynamic painter = tester.widget<CustomPaint>(glyph).painter;
          return painter.colour as Color;
        }

        expect(glyphColour(Icons.label_outline_rounded), categoryInk);
        expect(glyphColour(Icons.add_rounded), categoryInk);
        final bold =
            _key('pixel-note-glyph-${Icons.format_bold_rounded.codePoint}');
        final idle = tester.widget<CustomPaint>(bold).painter!;
        await _tap(tester, _key('note-format-bold'));
        expect(tester.widget<CustomPaint>(bold).painter!.shouldRepaint(idle),
            isTrue);
      } else if (appearance == 'pastel') {
        for (final button in [
          find.byTooltip('change category'),
          _key('note-ocr-button'),
          _key('note-format-bold'),
        ]) {
          expect(
              find
                      .descendant(
                          of: button, matching: _key('pastel-press-depth'))
                      .evaluate()
                      .isNotEmpty ||
                  find
                      .ancestor(
                          of: button, matching: _key('pastel-press-depth'))
                      .evaluate()
                      .isNotEmpty,
              isTrue);
        }
        final bold = _key('note-format-bold');
        Icon glyph() => tester.widget<Icon>(find.descendant(
            of: bold, matching: find.byIcon(Icons.format_bold_rounded)));
        expect(glyph().shadows, isNull);
        await _tap(tester, bold);
        expect(glyph().shadows!.single.blurRadius, greaterThan(0));
        await _tap(tester, bold);
        expect(glyph().shadows, isNull);
      } else if (appearance == 'sv') {
        const edge = Color(0xFF764330);
        for (final (format, letter) in [
          ('bold', 'B'),
          ('italic', 'i'),
          ('underline', 'U'),
        ]) {
          final button = _key('note-format-$format');
          final label =
              find.descendant(of: button, matching: find.text(letter));
          expect(
              tester.widget<Text>(label).style!.fontFamily, 'Press Start 2P');
          final style = tester.widget<IconButton>(button).style!;
          expect(style.side!.resolve({})!.color, edge);
          expect(style.backgroundColor!.resolve({}), const Color(0xFFE5A867));
        }
        final bold = _key('note-format-bold');
        await _tap(tester, bold);
        expect(tester.widget<IconButton>(bold).isSelected, isTrue);
        expect(
            tester.widget<IconButton>(bold).style!.backgroundColor!.resolve({}),
            const Color(0xFFE7EDBA));
        final category = find.byWidgetPredicate((widget) =>
            widget is IconButton && widget.tooltip == 'change category');
        expect(
            tester.widget<IconButton>(category).style!.side!.resolve({})!.color,
            edge);
        final plus = _key('note-ocr-button');
        expect(
            find.descendant(
                of: plus,
                matching: _key('sv-note-glyph-${Icons.add_rounded.codePoint}')),
            findsOneWidget);
        expect(
            find.descendant(
                of: category,
                matching: _key(
                    'sv-note-glyph-${Icons.label_outline_rounded.codePoint}')),
            findsOneWidget);
      } else {
        final plus = _key('note-ocr-button');
        final field = tester.widget<Container>(plus);
        expect((field.decoration! as BoxDecoration).border!.top.color,
            const Color(0xFF379BFF));
        final icon =
            find.descendant(of: plus, matching: find.byIcon(Icons.add_rounded));
        expect(tester.widget<Icon>(icon).color, const Color(0xFFFF2349));
      }
      await _tap(tester, _key('note-ocr-button'));
      expect(find.text('take a photo'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  for (final theme in AppTheme.values) {
    testWidgets('Task checkboxes align to the top of the text in ${theme.name}',
        (tester) async {
      await _load(tester, theme == AppTheme.copper ? 'goth' : theme.name,
          linkedText: 'A longer linked task that wraps over multiple lines '
              'so its menu has a different centre from the first text line.');
      final task = _key('task-note-opener-linked');
      final editor = tester.state<EditableTextState>(
          find.descendant(of: task, matching: find.byType(EditableText)));
      final firstLine = editor.renderEditable.preferredLineHeight;
      expect(tester.getSize(task).height, greaterThan(firstLine));
      expect(tester.getTopLeft(_task('linked')).dy,
          closeTo(tester.getTopLeft(task).dy, .001));
      expect(tester.getTopLeft(_task('unlinked')).dy,
          closeTo(tester.getTopLeft(_key('task-text-unlinked')).dy, .001));
      expect(tester.getCenter(_menu(0)).dy,
          closeTo(tester.getCenter(_key('task-row-linked')).dy, .001));
      expect(tester.getCenter(_menu(1)).dy,
          closeTo(tester.getCenter(_key('task-row-unlinked')).dy, .001));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}
