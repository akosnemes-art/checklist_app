import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'welcome window expands changes and persists the current version',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('welcome-dialog')), findsOneWidget);
      expect(find.textContaining('CHECKLIST version $checklistVersion'),
          findsOneWidget);
      expect(
          find.textContaining('build $checklistBuildNumber'), findsOneWidget);
      expect(
        find.textContaining('Designed by Ákos Nemes using Codex AI.'),
        findsOneWidget,
      );
      expect(find.text('read more'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('implemented-changes-title')),
        findsNothing,
      );
      final welcomeDialog = find.byKey(const ValueKey('welcome-dialog'));
      final expandingContent = find.descendant(
        of: welcomeDialog,
        matching: find.byType(AnimatedSize),
      );
      final initialContentHeight = tester.getSize(expandingContent).height;
      final readMore = tester.widget<TextButton>(
        find.byKey(const ValueKey('welcome-read-more')),
      );
      expect(
        readMore.style?.foregroundColor?.resolve(<WidgetState>{}),
        const Color(0xFF922FD0),
      );

      await tester.tap(find.byKey(const ValueKey('welcome-read-more')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('implemented-changes-title')),
        findsOneWidget,
      );
      expect(find.textContaining('detected bold, italic, and underlined text'),
          findsOneWidget);
      expect(find.text('read less'), findsOneWidget);
      expect(
        tester.getSize(expandingContent).height,
        greaterThan(initialContentHeight),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'continue'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome-dialog')), findsNothing);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('checklist.welcome.v1'), isTrue);
      expect(preferences.getString('checklist.lastSeenVersion.v1'),
          checklistRelease);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome-dialog')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('welcome window returns after the internal build changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': '0.4.2+25',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-dialog')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('checklist.lastSeenVersion.v1'),
        checklistRelease);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing legacy installs migrate without a repeat welcome', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'checklist.welcome.v1': true});
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('welcome-dialog')), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('checklist.lastSeenVersion.v1'),
        checklistRelease);
    expect(tester.takeException(), isNull);
  });
}
