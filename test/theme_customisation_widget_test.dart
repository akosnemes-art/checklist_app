import 'dart:convert';
import 'dart:ui' as ui;

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
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
    expect(_key('theme-glass'), findsOneWidget);
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

    await tap(_key('theme-glass'));
    expect(theme().scaffoldBackgroundColor, const Color(0xFFE4ECFB));
    expect(theme().colorScheme.surface.a, lessThan(1));
    expect(_key('glass-wallpaper'), findsNWidgets(2));
    await tap(_key('theme-customise'));
    await tap(_key('theme-colour-background'));
    adjust('value', .2);
    await tester.pump();
    await tap(find.widgetWithText(TextButton, 'cancel'));
    expect(theme().scaffoldBackgroundColor, const Color(0xFFE4ECFB));
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

  testWidgets('Glass packages its refraction shader and keeps editing usable',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'glass',
      'checklist.notes.v1':
          '[{"id":"glass-note","name":"Glass note","createdAt":"2026-11-21T12:00:00.000Z","content":"Editable note"}]',
      'checklist.selectedNote.v1': 'glass-note',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final program = await tester
        .runAsync(() => ui.FragmentProgram.fromAsset('shaders/glass.frag'));
    expect(program, isNotNull);
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    expect(_key('glass-wallpaper'), findsOneWidget);
    await tester.tap(find.byTooltip('open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();

    final noteField = _key('note-content-field');
    final field = tester.widget<TextField>(noteField);
    expect(field.decoration!.fillColor!.a, inExclusiveRange(0, 1));
    await tester.enterText(noteField, 'Still editable');
    await tester.pumpAndSettle();
    expect(field.controller!.text, 'Still editable');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
