import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _openApp(WidgetTester tester, String theme) async {
  SharedPreferences.setMockInitialValues({
    'checklist.welcome.v1': true,
    'checklist.lastSeenVersion.v1': checklistRelease,
    'checklist.theme.v1': theme,
  });
  tester.view.physicalSize = const Size(400, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const ChecklistApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('open menu'));
  await tester.pumpAndSettle();
}

Rect _frameBounds(WidgetTester tester) {
  final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
  return dialog.shape!
      .getOuterPath(const Rect.fromLTWH(0, 0, 400, 200))
      .getBounds();
}

double _contentOpacity(WidgetTester tester) {
  final fade = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

void main() {
  testWidgets('Cyberpunk popup expands from a rail before fading in content',
      (tester) async {
    await _openApp(tester, 'cyberpunk');
    await tester.tap(_key('sidebar-create-button'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 36));

    final rail = _frameBounds(tester);
    expect(rail.width, inExclusiveRange(0, 400));
    expect(rail.height, 3);
    expect(rail.center.dx, closeTo(200, .001));
    expect(rail.center.dy, closeTo(100, .001));
    expect(_contentOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 56));
    expect(_frameBounds(tester).width, 400);
    expect(_frameBounds(tester).height, inExclusiveRange(3, 200));
    expect(_contentOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 94));
    expect(_frameBounds(tester).size, const Size(400, 200));
    expect(_contentOpacity(tester), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 94));
    expect(_contentOpacity(tester), 1);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Cyberpunk dialogs and menus skip motion with reduced motion',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await _openApp(tester, 'cyberpunk');
    final menu = tester.widget<PopupMenuButton<ProjectSort>>(
      find.byWidgetPredicate(
          (widget) => widget is PopupMenuButton<ProjectSort>),
    );
    expect(menu.popUpAnimationStyle, AnimationStyle.noAnimation);
    await tester.tap(_key('sidebar-create-button'));
    await tester.pump();
    expect(_frameBounds(tester).size, const Size(400, 200));
    expect(_contentOpacity(tester), 1);
  });

  testWidgets('Cyberpunk paints fine stationary grain and accent lighting',
      (tester) async {
    await _openApp(tester, 'cyberpunk');
    final finish = _key('cyberpunk-surface-finish');
    expect(finish, findsNWidgets(2));
    final surface = find.descendant(
      of: _key('workspace-surface'),
      matching: finish,
    );
    Future<ByteData> pixels() async {
      final render = tester.renderObject<RenderRepaintBoundary>(surface);
      return (await tester.runAsync(() async {
        final image = await render.toImage();
        try {
          return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        } finally {
          image.dispose();
        }
      }))!;
    }

    final first = await pixels();
    final width = tester.getSize(surface).width.round();
    int alpha(int x, int y) => first.getUint8((y * width + x) * 4 + 3);
    int rowAlpha(int y) =>
        List.generate(width, (x) => alpha(x, y)).reduce((a, b) => a + b);
    expect(rowAlpha(12), greaterThan(rowAlpha(150)));
    final grain = {for (var x = 0; x < width; x++) alpha(x, 150)};
    expect(grain.length, greaterThan(1));
    expect(grain.every((value) => value <= 64), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect((await pixels()).buffer.asUint8List(),
        orderedEquals(first.buffer.asUint8List()));
  });

  testWidgets('Boi keeps its existing popup shape and visual treatment',
      (tester) async {
    await _openApp(tester, 'boi');
    expect(_key('cyberpunk-surface-finish'), findsNothing);
    final menu = tester.widget<PopupMenuButton<ProjectSort>>(
      find.byWidgetPredicate(
          (widget) => widget is PopupMenuButton<ProjectSort>),
    );
    expect(menu.popUpAnimationStyle, isNull);
    await tester.tap(_key('sidebar-create-button'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 36));
    expect(_frameBounds(tester).size, const Size(400, 200));
    expect(_contentOpacity(tester), 0);
  });
}
