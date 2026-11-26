import 'dart:ui' as ui;

import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _pumpApp(WidgetTester tester) async {
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
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<int> _noiseRow(WidgetTester tester) async {
  final painter =
      tester.renderObject<RenderCustomPaint>(_key('pixel-noise-band'));
  final boundary = painter.parent! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final pixels =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      for (var y = 0; y < image.height; y++) {
        if (pixels.getUint8(y * image.width * 4 + 3) != 0) return y;
      }
      return -1;
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  testWidgets('themes build upwards and Pixel sweeps a short CRT noise band',
      (tester) async {
    await _pumpApp(tester);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _tap(tester, find.byTooltip('open menu'));
    await _tap(tester, _key('settings-toggle'));
    await _tap(tester, _key('settings-themes'));
    final workspace = _key('workspace-surface');
    final clip =
        find.descendant(of: workspace, matching: _key('theme-build-clip'));
    Rect visible() =>
        tester.widget<ClipRect>(clip).clipper!.getClip(tester.getSize(clip));

    await tester.tap(_key('theme-pixel'));
    await tester.pump(const Duration(milliseconds: 61));
    final start = visible();
    await tester.pump(const Duration(milliseconds: 135));
    final halfway = visible();
    expect(halfway.top, lessThan(start.top));
    expect(halfway.top, greaterThan(0));
    expect(halfway.bottom, start.bottom);
    await tester.pumpAndSettle();
    expect(visible().top, 0);

    expect(await _noiseRow(tester), -1);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 130));
    final first = await _noiseRow(tester);
    await tester.pump(const Duration(milliseconds: 170));
    final second = await _noiseRow(tester);
    expect(first, greaterThan(0));
    expect(second, greaterThan(0));
    expect((second - first).abs(), greaterThan(100));
    await tester.pump(const Duration(milliseconds: 270));
    expect(await _noiseRow(tester), -1);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(_key('pixel-noise-band'), findsNothing);
    await _tap(tester, _key('theme-pencil'));
    expect(visible().top, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Settings fades and collapses the version in Notes',
      (tester) async {
    await _pumpApp(tester);
    await _tap(tester, find.byTooltip('open menu'));
    await _tap(tester, find.bySemanticsLabel('NOTES'));
    final space = _key('settings-version-space');
    final fade = _key('settings-version-fade');
    final label = find.text('settings');
    expect(tester.getSize(space).height, greaterThan(0));
    expect(tester.widget<Opacity>(fade).opacity, 1);

    await tester.tap(_key('settings-chevron'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(fade).opacity, 0);
    expect(tester.getSize(space).height, 0);
    final menuGap = tester.getTopLeft(_key('settings-themes')).dy -
        tester.getBottomLeft(label).dy;
    expect(menuGap, lessThan(24));

    await _tap(tester, _key('settings-chevron'));
    expect(tester.widget<Opacity>(fade).opacity, 1);
    expect(tester.getSize(space).height, greaterThan(0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
