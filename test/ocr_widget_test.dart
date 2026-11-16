import 'package:checklist_app/main.dart';
import 'package:checklist_app/services/ocr_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android picture menu inserts offline OCR text into a note',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': '0.4.3+26',
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const channel = MethodChannel(OcrService.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickAndRecognise');
      expect(call.arguments, {'source': 'picture'});
      return 'English text\nMagyar ő és ű';
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'new note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Scanned note',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'save'));
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('note-ocr-button'));
    expect(button, findsOneWidget);
    expect(tester.getSize(button), const Size(40, 40));
    final decoration =
        tester.widget<Container>(button).decoration! as BoxDecoration;
    expect(decoration.border!.top.color, const Color(0xFFF8F7FF));
    expect(decoration.border!.top.width, 2);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('add picture'), findsOneWidget);
    expect(find.text('take a photo'), findsOneWidget);
    await tester.tap(find.text('add picture'));
    await tester.pumpAndSettle();

    expect(find.textContaining('English text'), findsOneWidget);
    expect(find.textContaining('Magyar ő és ű'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.notes.v1'),
      contains('Magyar ő és ű'),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('picture button remains Android-only', (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': '0.4.3+26',
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Linux note","createdAt":"2026-11-12T10:00:00.000Z","content":"","categoryId":null}]',
      'checklist.selectedNote.v1': 'note-1',
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note-ocr-button')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });
}
