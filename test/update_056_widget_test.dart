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
    {String linkedText = 'Linked task'}) async {
  SharedPreferences.setMockInitialValues({
    'checklist.welcome.v1': true,
    'checklist.lastSeenVersion.v1': checklistRelease,
    'checklist.theme.v1': theme,
    'checklist.notes.v1': _notes,
    'checklist.projects.v1':
        '[{"id":"project","name":"My checklist","createdAt":"2026-11-11T10:00:00.000Z","tasks":['
            '{"id":"linked","text":${jsonEncode(linkedText)},"isDone":false,"linkedNoteId":"note"},'
            '{"id":"unlinked","text":"Unlinked task","isDone":false}]}]',
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
        matching: find.byType(RepaintBoundary),
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

  testWidgets('Cyberpunk has yellow frames and half-opacity task dividers',
      (tester) async {
    await _load(tester, 'cyberpunk');
    const yellow = Color(0xFFF3ED23);
    final theme = Theme.of(tester.element(_key('workspace-surface')));
    expect(theme.colorScheme.outline, yellow);
    expect((theme.popupMenuTheme.shape! as OutlinedBorder).side.color, yellow);
    expect(tester.widget<Divider>(_key('checklist-task-divider')).color,
        yellow.withValues(alpha: .5));
    final reminder =
        tester.widget<OutlinedButton>(_key('checklist-reminder-button'));
    expect(reminder.style!.side!.resolve({})!.color, yellow);
    await _tap(tester, find.byTooltip('open menu'));
    final create = tester.widget<FilledButton>(_key('sidebar-create-button'));
    expect(create.style!.side!.resolve({})!.color, yellow);
    await _tap(tester, _key('sidebar-create-button'));
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect((dialog.shape! as OutlinedBorder).side.color, yellow);
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
    final surface = lifted.first.decoration as BoxDecoration;
    expect(surface.borderRadius, corners);
    expect(surface.boxShadow, hasLength(3));
    expect(_key('checklist-task-divider'), findsNothing);
    final taskPlate = lifted.singleWhere((widget) => find
        .descendant(
          of: find.byWidget(widget),
          matching: _key('task-note-opener-linked'),
        )
        .evaluate()
        .isNotEmpty);
    expect((taskPlate.decoration as BoxDecoration).gradient, isNotNull);
    expect(theme.dialogTheme.elevation, 10);
    final raised = theme.filledButtonTheme.style!.elevation!;
    expect(raised.resolve({}), 3);
    expect(raised.resolve({WidgetState.pressed}), 0);
    expect(theme.iconButtonTheme.style!.backgroundBuilder, isNull);
    expect(theme.filledButtonTheme.style!.side!.resolve({}), BorderSide.none);
    final ring = tester
        .widget<DecoratedBox>(_key('pastel-drawer-button-ring'))
        .decoration as BoxDecoration;
    expect(ring.shape, BoxShape.circle);
    expect(ring.border!.top.color, Colors.white);
    expect(ring.boxShadow!.single.blurRadius, greaterThan(0));

    await _tap(tester, find.byTooltip('open menu'));
    final create = tester.widget<FilledButton>(_key('sidebar-create-button'));
    expect(create.style!.backgroundColor!.resolve({}), const Color(0xFFF2AED3));
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

  for (final theme in AppTheme.values) {
    testWidgets('Task controls align to the text and row in ${theme.name}',
        (tester) async {
      await _load(tester, theme == AppTheme.copper ? 'goth' : theme.name,
          linkedText: 'A longer linked task that wraps over multiple lines '
              'so its menu has a different centre from the first text line.');
      final task = _key('task-note-opener-linked');
      final editor = tester.state<EditableTextState>(
          find.descendant(of: task, matching: find.byType(EditableText)));
      final firstLine = editor.renderEditable.preferredLineHeight;
      expect(tester.getSize(task).height, greaterThan(firstLine));
      expect(tester.getCenter(_task('linked')).dy,
          closeTo(tester.getTopLeft(task).dy + firstLine / 2, 1));
      expect(tester.getCenter(_menu(0)).dy,
          closeTo(tester.getCenter(_key('task-row-linked')).dy, .001));
      expect(tester.getCenter(_menu(1)).dy,
          closeTo(tester.getCenter(_key('task-row-unlinked')).dy, .001));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}
