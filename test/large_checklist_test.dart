import 'dart:convert';
import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [10, 100, 1000, 10000]) {
    testWidgets('task list opens, scrolls and toggles with $size tasks',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({
        'checklist.welcome.v1': true,
        'checklist.lastSeenVersion.v1': checklistRelease,
        'checklist.projects.v1': jsonEncode([
          {
            'id': 'p',
            'name': 'Load test',
            'createdAt': '2026-01-01',
            'tasks':
                List.generate(size, (i) => {'id': 't$i', 'text': 'Buy item $i'})
          }
        ])
      });
      await tester.pumpWidget(const ChecklistApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-checkbox-t0')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final tasks = jsonDecode(prefs.getString('checklist.projects.v1')!)[0]
          ['tasks'] as List;
      expect(tasks.length, size);
      expect(tasks[0]['isDone'], true);
      final scrollable = find
          .ancestor(
              of: find.text('Buy item 0').first,
              matching: find.byType(Scrollable))
          .first;
      await tester.drag(scrollable, const Offset(0, -190));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
