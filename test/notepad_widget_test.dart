import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates, categorises, colours, and writes a note',
      (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    expect(find.text('new note'), findsOneWidget);
    expect(find.text('YOUR NOTES'), findsOneWidget);
    expect(find.text('your notes'), findsNothing);
    expect(find.text('notes'), findsNothing);
    expect(find.text('create a note from the sidebar'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'make a note'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'new note'));
    await tester.pumpAndSettle();
    var dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Worldbuilding',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'save'));
    await tester.pumpAndSettle();

    expect(find.text('Worldbuilding'), findsWidgets);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('sidebar-item-count')),
          )
          .data,
      '1',
    );
    expect(find.text('start writing…'), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).width, greaterThan(700));

    await tester.tap(find.byTooltip('change category'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'new'));
    await tester.pumpAndSettle();

    dialog = find.byType(AlertDialog);
    for (var index = 1; index <= 18; index++) {
      expect(find.bySemanticsLabel('colour $index'), findsOneWidget);
    }
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'Lore',
    );
    await tester.tap(find.bySemanticsLabel('colour 8'));
    await tester.tap(find.widgetWithText(FilledButton, 'create'));
    await tester.pumpAndSettle();

    expect(find.text('Lore'), findsWidgets);
    final sidebarNote = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('notes-sidebar-list')),
        matching: find.text('Worldbuilding'),
      ),
    );
    expect(sidebarNote.style?.color, const Color(0xFF05E1E6));
    final editorScope = find.byKey(const ValueKey('note-editor'));
    final editorTitle = find.descendant(
      of: editorScope,
      matching: find.text('Worldbuilding'),
    );
    final editorDate = find.descendant(
      of: editorScope,
      matching: find.textContaining(DateTime.now().year.toString()),
    );
    final editorCategory = find.descendant(
      of: editorScope,
      matching: find.text('Lore'),
    );
    expect(tester.getTopLeft(editorTitle).dy,
        lessThan(tester.getTopLeft(editorDate).dy));
    expect(tester.getTopLeft(editorDate).dy,
        lessThan(tester.getTopLeft(editorCategory).dy));
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.style.color, const Color(0xFFF8F7FF));
    final noteInput = tester.widget<TextField>(find.byType(TextField));
    expect(noteInput.decoration?.hintStyle?.color, const Color(0xFF9AA0AA));

    await tester.enterText(find.byType(TextField), 'The city floats at dawn.');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('The city floats at dawn.'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.notes.v1'),
      contains('The city floats at dawn.'),
    );
    expect(tester.takeException(), isNull);
  });
}
