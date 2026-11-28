import 'dart:ui' as ui;

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  testWidgets('Copper restores the previous Goth preference and palette',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'goth',
      'checklist.projects.v1':
          '[{"id":"test-list","name":"Testing Checklist","createdAt":"2026-11-21T10:00:00.000Z","tasks":[{"id":"task-1","text":"Verify Copper","isDone":true}]}]',
      'checklist.selectedProject.v1': 'test-list',
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Testing Notes","createdAt":"2026-11-21T10:00:00.000Z","content":"Before https://example.org"}]',
      'checklist.selectedNote.v1': 'note-1',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Color sidebarColour() =>
        (tester.widget<AnimatedContainer>(_key('sidebar-surface')).decoration!
                as BoxDecoration)
            .color!;

    ThemeData sidebarTheme() =>
        Theme.of(tester.element(_key('sidebar-surface')));

    RadialGradient backdrop() =>
        (tester.widget<AnimatedContainer>(_key('workspace-surface')).decoration!
                as BoxDecoration)
            .gradient! as RadialGradient;

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tap(find.byTooltip('open menu'));
    expect(sidebarColour(), const Color(0xFF24161D));
    await tap(_key('settings-toggle'));
    await tap(_key('settings-themes'));
    for (final theme in [
      'Boi',
      'Pencil',
      'Blue milk',
      'Copper',
      'Black Metal',
      'Pixel',
      'Cyberpunk',
      'SV',
    ]) {
      expect(find.text(theme), findsOneWidget);
    }
    expect(find.text('Goth'), findsNothing);
    expect(_key('black-metal-texture'), findsNothing);
    expect(
      tester.widget<AnimatedContainer>(_key('workspace-surface')).child,
      isNot(isA<CustomPaint>()),
    );
    await tap(_key('theme-boi'));
    expect(sidebarColour(), const Color(0xFF26102F));
    await tap(_key('theme-copper'));

    const gold = Color(0xFFD6B583);
    const rose = Color(0xFFDA9EA9);
    const ink = Color(0xFFF3E8DC);
    const surface = Color(0xFF1B161B);
    expect(sidebarColour(), const Color(0xFF24161D));
    expect(sidebarTheme().scaffoldBackgroundColor, const Color(0xFF100D10));
    expect(sidebarTheme().colorScheme.primary, gold);
    expect(backdrop().colors.first, const Color(0xFF24161D));
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .color,
        gold);
    expect(
        tester
            .widget<AnimatedDefaultTextStyle>(_key('checklist-word-style'))
            .style
            .fontFamily,
        'serif');
    final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        _key('edge-to-edge-system-ui'));
    expect(overlay.value.systemNavigationBarIconBrightness, Brightness.light);
    final saved = await SharedPreferences.getInstance();
    expect(saved.getString('checklist.theme.v1'), 'goth');
    expect(saved.getBool('checklist.darkMode.v1'), isTrue);

    await tap(find.bySemanticsLabel('NOTES'));
    expect(sidebarColour(), const Color(0xFF201925));
    expect(backdrop().colors.first, const Color(0xFF201925));
    expect(sidebarTheme().colorScheme.primary, rose);
    await tap(_key('sidebar-create-button'));
    final dialog = tester.widget<AlertDialog>(_key('note-details-dialog'));
    expect(dialog.backgroundColor, surface);
    expect((dialog.shape! as RoundedRectangleBorder).side,
        const BorderSide(color: gold, width: 2));
    await tap(find.widgetWithText(TextButton, 'cancel'));

    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();
    final editor = _key('note-content-field');
    final field = tester.widget<TextField>(editor);
    expect(field.decoration!.fillColor, surface);
    expect(field.style!.color, ink);
    final text = field.controller!.buildTextSpan(
      context: tester.element(editor),
      style: field.style,
      withComposing: false,
    );
    final link = text.children!.whereType<TextSpan>().last;
    expect(link.text, 'https://example.org');
    expect(link.style!.color, rose);
    expect(link.style!.decoration, TextDecoration.underline);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tap(find.byTooltip('open menu'));
    expect(sidebarColour(), const Color(0xFF24161D));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'Black Metal wears and polishes both panels without blocking taps',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'boi',
      'checklist.notes.v1':
          '[{"id":"metal-1","name":"Set list","createdAt":"2026-11-21T10:00:00.000Z","content":"https://example.org"}]',
      'checklist.selectedNote.v1': 'metal-1',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    ThemeData theme() => Theme.of(tester.element(_key('sidebar-surface')));
    Color sidebarColor() =>
        (tester.widget<AnimatedContainer>(_key('sidebar-surface')).decoration!
                as BoxDecoration)
            .color!;

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tap(find.byTooltip('open menu'));
    await tap(_key('settings-toggle'));
    await tap(_key('settings-themes'));
    await tap(_key('theme-black-metal'));

    expect(theme().brightness, Brightness.dark);
    expect(theme().scaffoldBackgroundColor, const Color(0xFF09090C));
    expect(theme().colorScheme.primary, const Color(0xFFDA7781));
    expect(sidebarColor(), const Color(0xFF211217));
    expect(_key('black-metal-texture'), findsNWidgets(2));
    expect(_key('black-metal-sheen'), findsNWidgets(2));
    expect(_key('black-metal-button-finish'), findsOneWidget);
    Color createButtonColor() => tester
        .widget<FilledButton>(_key('sidebar-create-button'))
        .style!
        .backgroundColor!
        .resolve({})!;
    expect(createButtonColor(), const Color(0xFF751823));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.theme.v1'), 'blackMetal');

    final workspaceSheen = find.descendant(
      of: _key('workspace-surface'),
      matching: _key('black-metal-sheen'),
    );
    Future<int> centreAlpha() async {
      final boundary = tester
          .renderObject<RenderCustomPaint>(workspaceSheen)
          .parent! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          return data.getUint8(
              ((image.height ~/ 2) * image.width + image.width ~/ 2) * 4 + 3);
        } finally {
          image.dispose();
        }
      }))!;
    }

    expect(await centreAlpha(), 0);
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 320));
    expect(await centreAlpha(), inInclusiveRange(90, 0x9A));
    await tester.pump(const Duration(milliseconds: 330));
    expect(await centreAlpha(), 0);

    final chip = tester.widget<Container>(_key('priority-chip-normal'));
    expect((chip.decoration! as BoxDecoration).color, const Color(0xFF492453));
    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();
    await tap(find.byTooltip('Set priority'));
    expect(tester.widget<Container>(_key('priority-menu-low')).color,
        const Color(0xFFA8A4AF));
    final medium = tester.widget<Container>(_key('priority-menu-normal'));
    expect(
        (medium.decoration! as BoxDecoration).color, const Color(0xFF492453));
    await tap(find.text('low'));
    expect(
        ((tester.widget<Container>(_key('priority-chip-low')).decoration!)
                as BoxDecoration)
            .border,
        Border.all(color: const Color(0xFFA8A4AF), width: 2));
    await tap(find.byTooltip('open menu'));

    await tap(find.bySemanticsLabel('NOTES'));
    expect(theme().colorScheme.primary, const Color(0xFFBDC8D3));
    expect(sidebarColor(), const Color(0xFF18191F));
    expect(createButtonColor(), const Color(0xFF66121D));
    tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
    await tester.pumpAndSettle();
    final note = _key('note-content-field');
    final field = tester.widget<TextField>(note);
    expect(field.decoration!.fillColor, const Color(0xFF131216));
    expect(field.style!.color, const Color(0xFFECE9E8));
    final rendered = field.controller!.buildTextSpan(
        context: tester.element(note),
        style: field.style,
        withComposing: false);
    expect((rendered.children!.single as TextSpan).style!.color,
        const Color(0xFFBDC8D3));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(_key('black-metal-texture'), findsOneWidget);
    expect(_key('black-metal-sheen'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tap(find.byTooltip('open menu'));
    expect(sidebarColor(), const Color(0xFF211217));
    expect(_key('black-metal-texture'), findsNWidgets(2));
    expect(_key('black-metal-sheen'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
