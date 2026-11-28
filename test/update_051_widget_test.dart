import 'dart:convert';
import 'dart:io';

import 'package:checklist_app/main.dart';
import 'package:checklist_app/services/website_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

void _desktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openNotes(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('NOTES'));
  await tester.pumpAndSettle();
}

void main() {
  for (final (theme, frame, surface) in [
    (
      'pencil',
      const BorderSide(color: Color(0xFF858C94), width: 2),
      const Color(0xFFE7E6E3)
    ),
    ('pastel', BorderSide.none, const Color(0xFFE8FDF6)),
  ]) {
    testWidgets(
        'create-note popup follows $theme and reveals content after the frame',
        (tester) async {
      _desktopSize(tester);
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.theme.v1': theme,
      });
      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
      await _openNotes(tester);
      await tester.tap(_key('sidebar-create-button'));
      await tester.pump();

      final finder = _key('note-details-dialog');
      final route = ModalRoute.of(tester.element(finder))!;
      expect(
          route.transitionDuration.inMilliseconds, inInclusiveRange(1, 1500));
      double titleOpacity() =>
          (tester.widget<AlertDialog>(finder).title as FadeTransition)
              .opacity
              .value;

      expect(titleOpacity(), 0);
      await tester.pump(const Duration(milliseconds: 100));
      final dialog = tester.widget<AlertDialog>(finder);
      expect((dialog.shape! as RoundedRectangleBorder).side, frame);
      expect(dialog.backgroundColor, surface);
      expect(titleOpacity(), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(titleOpacity(), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(titleOpacity(), 1);
    });
  }

  testWidgets('German and Simplified Chinese localize and persist',
      (tester) async {
    _desktopSize(tester);
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.notes.v1':
          '[{"id":"note","name":"Original title","createdAt":"2026-11-13T12:00:00","content":"","categoryId":null}]',
    });
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await _openNotes(tester);
    await tester.tap(_key('settings-toggle'));
    await tester.pumpAndSettle();
    await tester.tap(_key('settings-language'));
    await tester.pumpAndSettle();

    await tester.tap(_key('language-german'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('13.11.2026'), findsWidgets);
    expect(find.text('Original title'), findsWidgets);

    await tester.tap(_key('language-chinese'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('2026年11月13日'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('checklist.language.v1'), 'chinese');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('manual web links are captured and open from the Notes gallery',
      (tester) async {
    _desktopSize(tester);
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.notes.v1':
          '[{"id":"note","name":"Websites","createdAt":"2026-11-13T12:00:00","content":"","categoryId":null}]',
    });
    final cache = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('checklist-gallery-test-'),
    ))!;
    const previews = MethodChannel(WebsitePreviews.channelName);
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    const url = 'https://example.org/preview';
    final messenger = tester.binding.defaultBinaryMessenger;
    final captures = <String>[];
    final opens = <String>[];
    messenger.setMockMethodCallHandler(paths, (_) async => cache.path);
    messenger.setMockMethodCallHandler(previews, (call) async {
      expect(call.method, 'capture');
      captures.add(call.arguments as String);
      return base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jR4YAAAAASUVORK5CYII=');
    });
    messenger.setMockMethodCallHandler(launcher, (call) async {
      opens.add(call.arguments['url'] as String);
      return true;
    });
    addTearDown(() {
      for (final channel in [previews, paths, launcher]) {
        messenger.setMockMethodCallHandler(channel, null);
      }
      cache.deleteSync(recursive: true);
    });

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    expect(_key('note-website-gallery'), findsNothing);
    await _openNotes(tester);
    final button = _key('note-website-gallery');
    expect(button, findsNothing);
    await tester.enterText(_key('note-content-field'), url);
    await tester.pump(const Duration(seconds: 1));
    final bold = _key('note-format-bold');
    expect(
        tester.getTopRight(button).dx, closeTo(tester.getTopLeft(bold).dx, 1));
    expect(tester.getCenter(button).dy, tester.getCenter(bold).dy);
    for (var steps = 0; steps < 30 && captures.isEmpty; steps++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(captures, [url]);

    await tester.tap(button);
    await tester.pumpAndSettle();
    final gallery = _key('website-gallery-dialog');
    final link = find.descendant(of: gallery, matching: find.text(url));
    for (var steps = 0;
        steps < 30 &&
            find
                .descendant(of: gallery, matching: find.byType(Image))
                .evaluate()
                .isEmpty;
        steps++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(find.descendant(of: gallery, matching: find.byType(Image)),
        findsOneWidget);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(opens, [url]);
    expect(captures, [url]);
    Navigator.of(tester.element(gallery)).pop();
    await tester.pumpAndSettle();
    await tester.enterText(_key('note-content-field'), 'Plain text');
    await tester.pumpAndSettle();
    expect(button, findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
