import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renaming a checklist closes the dialog cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('checklist options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('rename').last);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final nameField = find.descendant(
      of: dialog,
      matching: find.byType(TextField),
    );
    await tester.enterText(nameField, 'Release checklist');
    await tester.tap(find.widgetWithText(FilledButton, 'save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Release checklist'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rename note dialog uses a pale pastel blue background', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.notes.v1':
          '[{"id":"rename-note","name":"Draft note","createdAt":"2026-11-21T10:00:00.000Z","content":"","categoryId":null}]',
      'checklist.selectedNote.v1': 'rename-note',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sidebar-note-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('rename').last);
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(
      find.byKey(const ValueKey('note-details-dialog')),
    );
    expect(dialog.backgroundColor, const Color(0xFFD9EAF7));
    expect(find.text('rename note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
