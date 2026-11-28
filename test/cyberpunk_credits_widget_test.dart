import 'dart:ui' as ui;

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'checklist.welcome.v1': true,
    'checklist.lastSeenVersion.v1': checklistRelease,
  });
  tester.view.physicalSize = const Size(400, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const ChecklistApp());
  await tester.pumpAndSettle();
  await _tap(tester, find.byTooltip('open menu'));
  await _tap(tester, _key('settings-toggle'));
}

void main() {
  testWidgets(
      'Cyberpunk reveals the workspace immediately and uses animated circuitry',
      (tester) async {
    await _openSettings(tester);
    await _tap(tester, _key('settings-themes'));
    final choice = _key('theme-cyberpunk');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump(const Duration(milliseconds: 65));
    await tester.pump();
    final intro = _key('cyberpunk-intro');
    expect(intro, findsNothing);
    final workspace = _key('workspace-surface');
    final reveal =
        find.descendant(of: workspace, matching: _key('theme-build-clip'));
    Rect visible() => tester
        .widget<ClipRect>(reveal)
        .clipper!
        .getClip(tester.getSize(reveal));
    expect(visible().height, 0);
    await tester.pump(const Duration(milliseconds: 170));
    expect(intro, findsNothing);
    expect(visible().height, greaterThan(0));
    expect(visible().top, greaterThan(0));
    await tester.pumpAndSettle();
    expect(intro, findsNothing);
    expect(visible().top, 0);

    final theme = Theme.of(tester.element(workspace));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xFFFF7881));
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Rajdhani');
    final circuits = _key('cyberpunk-circuit-background');
    expect(circuits, findsNWidgets(2));
    expect(find.descendant(of: circuits, matching: find.byType(Text)),
        findsNothing);
    final signals = find.descendant(
      of: find.descendant(of: workspace, matching: circuits),
      matching:
          find.byWidgetPredicate((w) => w is RepaintBoundary && w.key == null),
    );
    Future<Uint8List> pixels() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(signals);
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 0.25);
        try {
          return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
              .buffer
              .asUint8List();
        } finally {
          image.dispose();
        }
      }))!;
    }

    final first = await pixels();
    await tester.pump(const Duration(milliseconds: 320));
    expect(await pixels(), isNot(orderedEquals(first)));

    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    final still = await pixels();
    await tester.pump(const Duration(milliseconds: 480));
    expect(await pixels(), orderedEquals(still));

    final settings = await SharedPreferences.getInstance();
    expect(settings.getString('checklist.theme.v1'), 'cyberpunk');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Saved Cyberpunk opens directly with its circuit background',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'cyberpunk',
      'checklist.projects.v1':
          '[{"id":"saved","name":"Saved checklist","createdAt":"2026-11-26T12:00:00.000Z","tasks":[]}]',
    });
    await tester.pumpWidget(const ChecklistApp());
    final frames = await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(frames, lessThan(20));
    expect(find.text('Saved checklist'), findsOneWidget);
    expect(_key('cyberpunk-intro'), findsNothing);
    expect(_key('cyberpunk-circuit-background'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'The red checklist button has a right bevel and occasional split glitch',
      (tester) async {
    await _openSettings(tester);
    await _tap(tester, _key('settings-themes'));
    final choice = _key('theme-cyberpunk');
    await tester.ensureVisible(choice);
    await _tap(tester, choice);

    final create = _key('sidebar-create-button');
    final ghost = _key('cyberpunk-create-ghost');
    final style = tester.widget<FilledButton>(create).style!;
    expect(style.backgroundColor!.resolve({}), const Color(0xFFD91432));
    expect(style.foregroundColor!.resolve({}), const Color(0xFFF8F7FF));
    final shape = style.shape!.resolve({})!;
    final buttonSize = tester.getSize(create);
    final path = shape.getOuterPath(Offset.zero & buttonSize);
    expect(path.contains(Offset(buttonSize.width - 2, buttonSize.height - 2)),
        isFalse);
    expect(path.contains(Offset(2, buttonSize.height - 2)), isTrue);
    expect(path.contains(Offset(buttonSize.width - 2, 2)), isTrue);
    expect(find.text('NEW CHECKLIST'), findsOneWidget);
    expect(ghost, findsNothing);

    // The delay starts after the shared theme reveal has finished.
    await tester.pump(const Duration(seconds: 4));
    expect(ghost, findsNothing);
    for (var tick = 0; tick < 112 && ghost.evaluate().isEmpty; tick++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ghost, findsOneWidget);
    await tester.pumpAndSettle();
    expect(ghost, findsNothing);

    final press = await tester.startGesture(tester.getCenter(create));
    await tester.pump();
    expect(ghost, findsOneWidget);
    await press.cancel();
    await tester.pumpAndSettle();

    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    final reducedPress = await tester.startGesture(tester.getCenter(create));
    await tester.pump();
    expect(ghost, findsNothing);
    await reducedPress.cancel();
    await tester.pump(const Duration(seconds: 16));
    expect(ghost, findsNothing);

    await _tap(tester, create);
    expect(find.text('checklist name'), findsOneWidget);
    await _tap(tester, find.text('cancel'));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk new note shares the checklist bevel and glitches',
      (tester) async {
    await _openSettings(tester);
    await _tap(tester, _key('settings-themes'));
    final choice = _key('theme-cyberpunk');
    await tester.ensureVisible(choice);
    await _tap(tester, choice);

    final create = _key('sidebar-create-button');
    final checklistButton = tester.widget<FilledButton>(create);
    final checklistSize = tester.getSize(create);
    await _tap(tester, find.bySemanticsLabel('NOTES'));
    expect(find.text('NEW NOTE'), findsOneWidget);
    final noteButton = tester.widget<FilledButton>(create);
    final style = noteButton.style!;
    expect(style.shape!.resolve({}), checklistButton.style!.shape!.resolve({}));
    expect(noteButton.clipBehavior, Clip.antiAlias);
    expect(style.backgroundColor!.resolve({}), const Color(0xFF165AC8));
    expect(style.side!.resolve({})!.color, const Color(0xFF379BFF));
    expect(style.foregroundColor!.resolve({}), const Color(0xFFF8F7FF));
    expect(tester.getSize(create), checklistSize);
    expect(tester.getSize(_key('sidebar-filter-frame')).height,
        checklistSize.height);

    final press = await tester.startGesture(tester.getCenter(create));
    await tester.pump();
    expect(_key('cyberpunk-create-ghost'), findsOneWidget);
    await press.cancel();
    await tester.pumpAndSettle();
    expect(_key('cyberpunk-create-ghost'), findsNothing);
    await _tap(tester, create);
    expect(find.text('make a note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Cyberpunk has a flat blue track and glowing yellow fill',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.theme.v1': 'cyberpunk',
    });
    tester.view.physicalSize = const Size(400, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    const blue = Color(0xFF379BFF);
    const yellow = Color(0xFFF3ED23);
    final track = _key('cyberpunk-progress-track');
    final fill = _key('cyberpunk-progress-fill');
    final indicator = find.byType(LinearProgressIndicator);
    final reminder = tester
        .widget<OutlinedButton>(_key('checklist-reminder-button'))
        .style!
        .shape!
        .resolve({})! as BeveledRectangleBorder;
    expect(
      reminder.borderRadius,
      const BorderRadius.only(bottomRight: Radius.circular(16)),
    );

    LinearProgressIndicator progress() =>
        tester.widget<LinearProgressIndicator>(indicator);
    expect(progress().value, 0);
    expect(progress().color, yellow);
    expect(progress().backgroundColor, blue);
    BoxShadow shadow(Finder layer) =>
        (tester.widget<DecoratedBox>(layer).decoration as BoxDecoration)
            .boxShadow!
            .single;
    expect(track, findsNothing);
    expect(fill, findsNothing);

    final priority = _key('priority-chip-normal');
    final chip =
        tester.widget<Container>(priority).decoration! as BoxDecoration;
    const medium = Color(0xFFF184C5);
    expect(chip.boxShadow!.single.color, medium.withValues(alpha: 0.38));
    await _tap(tester, priority);
    for (final level in ['low', 'normal', 'high']) {
      final marker = tester.widget<Container>(_key('priority-menu-$level'));
      final decoration = marker.decoration! as BoxDecoration;
      expect(decoration.boxShadow!.single.blurRadius, 9);
    }
    await _tap(tester, _key('priority-menu-high'));

    for (final label in ['first task', 'second task']) {
      await tester.enterText(find.byType(TextField), label);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    final tasks = find.byType(Checkbox);
    expect(tasks, findsNWidgets(2));
    await tester.tap(tasks.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(progress().value, inExclusiveRange(0, 0.5));
    await tester.pumpAndSettle();
    expect(progress().value, 0.5);
    expect(progress().backgroundColor, blue);
    expect(shadow(fill).color, yellow.withValues(alpha: 0.60));
    expect(shadow(fill).blurRadius, 9);
    expect(tester.getSize(fill).width,
        closeTo(tester.getSize(indicator).width / 2, 0.1));
    expect(track, findsNothing);

    await _tap(tester, tasks.last);
    expect(progress().value, 1);
    expect(track, findsNothing);
    expect(tester.getSize(fill).width, tester.getSize(indicator).width);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('About credits roll and identify the fonts and their themes',
      (tester) async {
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    final opened = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(launcher, (call) async {
      opened.add(call.arguments['url'] as String);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(launcher, null));
    await _openSettings(tester);
    await _tap(tester, _key('settings-about'));
    expect(find.textContaining('designed by Ákos Nemes'), findsOneWidget);
    expect(find.text('Codex AI'), findsNothing);
    expect(find.text('akosnemes@proton.me'), findsNothing);

    final button = _key('about-credits');
    expect(
        tester.widget<TextButton>(button).style!.foregroundColor!.resolve({}),
        const Color(0xFFF3ED23));
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final roll = tester.widget<SingleChildScrollView>(_key('credits-roll'));
    final scroll = roll.controller!;
    expect(scroll.offset, 0);
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.offset, greaterThan(10));
    expect(find.text('Codex AI'), findsOneWidget);
    expect(find.text('akosnemes@proton.me'), findsOneWidget);
    expect(find.text('Allan Ferreira'), findsNothing);
    expect(find.text('Roboto font design for Boi / Pencil'), findsOneWidget);
    expect(find.text('Christian Robertson'), findsOneWidget);
    expect(find.text('Noto Serif font design for Copper / Black Metal'),
        findsOneWidget);
    expect(find.textContaining('Steve Matteson'), findsOneWidget);
    expect(find.text('Manrope font design for Blue milk'), findsOneWidget);
    expect(find.text('Nunito font design for Blue milk / SV'), findsOneWidget);
    expect(find.text('Mikhail Sharanda, Mirko Velimirovic'), findsOneWidget);
    expect(find.text('Pixelify Sans font design for Pixel'), findsOneWidget);
    expect(find.text('Stefie Justprince'), findsOneWidget);
    expect(find.text('Press Start 2P font design for SV'), findsOneWidget);
    expect(find.text('CodeMan38'), findsOneWidget);
    expect(find.text('VT323 font design for SV'), findsOneWidget);
    expect(find.text('Peter Hull'), findsOneWidget);
    expect(find.text('Rajdhani font design for Cyberpunk'), findsOneWidget);
    expect(find.textContaining('Shiva Nalleperumal'), findsOneWidget);
    expect(find.textContaining('Indian Type Foundry'), findsOneWidget);

    final font = _key('credits-font-Rajdhani');
    expect(
        find.descendant(
            of: font, matching: find.text('font source · Google Fonts')),
        findsOneWidget);
    await tester.ensureVisible(font);
    await _tap(tester, font);
    expect(opened, ['https://fonts.google.com/specimen/Rajdhani']);
    await _tap(tester, find.widgetWithText(TextButton, 'close'));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
