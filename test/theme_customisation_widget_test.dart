import 'dart:convert';

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  testWidgets('Pixel replaces Newsprint and stores its palette separately',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'newsprint',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    ThemeData theme() => Theme.of(tester.element(_key('workspace-surface')));
    Future<void> openThemes() async {
      await tap(find.byTooltip('open menu'));
      await tap(_key('settings-toggle'));
      await tap(_key('settings-themes'));
    }

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.theme.v1'), 'pixel');
    expect(theme().scaffoldBackgroundColor, const Color(0xFF060C09));
    expect(theme().textTheme.headlineMedium!.fontFamily, 'Pixelify Sans');
    final chip = tester.widget<Container>(_key('priority-chip-normal'));
    final decoration = chip.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.color, const Color(0xFFA9FF42));
    expect(decoration.boxShadow!.single.blurRadius, 7);

    await openThemes();
    expect(find.text('Newsprint'), findsNothing);
    expect(_key('theme-pixel'), findsOneWidget);
    expect(_key('theme-glass'), findsNothing);
    await tap(_key('theme-customise'));
    final swatch = _key('theme-colour-background');
    expect(swatch, findsOneWidget);
    expect(_key('theme-hsv-hue'), findsNothing);
    await tap(swatch);
    void adjust(String label, double value) {
      tester.widget<Slider>(_key('theme-hsv-$label')).onChanged!(value);
    }

    expect(_key('theme-hsv-saturation'), findsOneWidget);
    expect(_key('theme-hsv-value'), findsOneWidget);
    adjust('hue', 270);
    adjust('saturation', 1);
    adjust('value', .5);
    await tester.pump();
    final purple = const HSVColor.fromAHSV(1, 270, 1, .5).toColor();
    final preview = tester.widget<Container>(
      find.descendant(of: swatch, matching: find.byType(Container)),
    );
    expect((preview.decoration! as BoxDecoration).color, purple);

    await tap(find.widgetWithText(FilledButton, 'save'));
    expect(theme().scaffoldBackgroundColor, purple);
    expect(theme().textTheme.headlineMedium!.fontFamily, 'Pixelify Sans');
    expect(jsonDecode(prefs.getString('checklist.themeColours.v1')!), {
      'pixel': {'background': purple.toARGB32()}
    });

    await tap(_key('theme-pencil'));
    expect(theme().scaffoldBackgroundColor, const Color(0xFFF7F5F2));
    await tap(_key('theme-customise'));
    await tap(_key('theme-colour-background'));
    adjust('value', .2);
    await tester.pump();
    await tap(find.widgetWithText(TextButton, 'cancel'));
    expect(theme().scaffoldBackgroundColor, const Color(0xFFF7F5F2));
    await tap(_key('theme-pixel'));
    expect(theme().scaffoldBackgroundColor, purple);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    expect(theme().scaffoldBackgroundColor, purple);
    await openThemes();
    await tap(_key('theme-customise'));
    await tap(find.widgetWithText(TextButton, 'reset colours'));
    await tap(find.widgetWithText(FilledButton, 'save'));
    expect(theme().scaffoldBackgroundColor, const Color(0xFF060C09));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'Glass migrates to Pencil and compact headers respect the safe area',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'glass',
      'checklist.darkMode.v1': true,
      'checklist.themeColours.v1': '{"glass":{"background":4281545523}}',
      'checklist.notes.v1':
          '[{"id":"glass-note","name":"Glass note","createdAt":"2026-11-21T12:00:00.000Z","content":"Editable note"}]',
      'checklist.selectedNote.v1': 'glass-note',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.theme.v1'), 'pencil');
    expect(prefs.getBool('checklist.darkMode.v1'), false);
    expect(prefs.getString('checklist.themeColours.v1'),
        '{"glass":{"background":4281545523}}');
    final workspace = _key('workspace-surface');
    expect(Theme.of(tester.element(workspace)).scaffoldBackgroundColor,
        const Color(0xFFF7F5F2));
    final header = tester.widget<SliverPadding>(_key('checklist-header'));
    expect(header.padding.resolve(TextDirection.ltr).top, 11);
    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();
    final drawer = tester.widget<AnimatedContainer>(_key('sidebar-surface'));
    expect(drawer.padding!.resolve(TextDirection.ltr).top, 43.5);
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(workspace).dy, 0);
    expect(tester.getTopLeft(_key('note-editor')).dy, 32);
    final editor = tester.widget<Padding>(_key('note-editor'));
    expect(editor.padding.resolve(TextDirection.ltr).top, 14);

    final noteField = _key('note-content-field');
    final field = tester.widget<TextField>(noteField);
    expect(field.decoration!.fillColor!.a, 1);
    await tester.enterText(noteField, 'Still editable');
    await tester.pumpAndSettle();
    expect(field.controller!.text, 'Still editable');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('All themes fill system insets while keeping controls in place',
      (tester) async {
    await tester.runAsync(() async {
      final fonts = FontLoader('Rajdhani')
        ..addFont(rootBundle.load('assets/fonts/Rajdhani-Medium.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Rajdhani-Bold.ttf'));
      await fonts.load();
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    const screenBounds = Rect.fromLTWH(0, 0, 400, 780);
    final workspace = _key('workspace-surface');
    final editor = _key('note-editor');
    for (final appearance in AppTheme.values) {
      final reason = appearance.name;
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.lastSeenVersion.v1': checklistRelease,
        'checklist.theme.v1':
            appearance == AppTheme.copper ? 'goth' : appearance.name,
        'checklist.projects.v1':
            '[{"id":"layout-checklist","name":"Layout checklist","createdAt":"2026-11-26T12:00:00.000Z","tasks":[]}]',
        'checklist.notes.v1':
            '[{"id":"layout-note","name":"Layout note","createdAt":"2026-11-26T12:00:00.000Z","content":"Note text"}]',
      });
      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();

      expect(tester.getRect(workspace), screenBounds, reason: reason);
      expect(tester.getTopLeft(_key('layout-checklist')).dy, 32,
          reason: reason);
      final header = tester.widget<SliverPadding>(_key('checklist-header'));
      expect(header.padding.resolve(TextDirection.ltr).top, 11, reason: reason);
      expect(tester.getTopLeft(find.byTooltip('open menu')).dy,
          greaterThanOrEqualTo(43),
          reason: reason);
      expect(tester.getBottomLeft(find.byType(TextField)).dy, 734,
          reason: reason);

      await tester.tap(find.byTooltip('open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('NOTES'));
      await tester.pumpAndSettle();
      tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
      await tester.pumpAndSettle();

      expect(tester.getRect(workspace), screenBounds, reason: reason);
      expect(tester.getTopLeft(editor).dy, 32, reason: reason);
      expect(tester.getBottomLeft(editor).dy, 756, reason: reason);
      expect(tester.takeException(), isNull, reason: reason);

      if (appearance == AppTheme.cyberpunk) {
        tester.view.physicalSize = const Size(1200, 780);
        await tester.pumpAndSettle();
        final sidebar = _key('sidebar-surface');
        expect(
            tester.getRect(workspace), const Rect.fromLTWH(282, 0, 918, 780));
        expect(tester.getRect(sidebar), const Rect.fromLTWH(0, 0, 282, 780));
        final padding = tester.widget<AnimatedContainer>(sidebar).padding!;
        expect(padding.resolve(TextDirection.ltr).top, 43);
        expect(tester.getBottomLeft(_key('settings-panel')).dy, 742);
        expect(tester.getTopLeft(editor).dy, 32);
        expect(tester.getBottomLeft(editor).dy, 756);
        expect(tester.takeException(), isNull, reason: 'wide Cyberpunk');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
