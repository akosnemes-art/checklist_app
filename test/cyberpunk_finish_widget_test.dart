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

Future<ByteData> _pixels(WidgetTester tester, Finder target) async {
  final render = tester.renderObject<RenderRepaintBoundary>(target);
  return (await tester.runAsync(() async {
    final image = await render.toImage();
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    } finally {
      image.dispose();
    }
  }))!;
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

  testWidgets(
      'Cyberpunk refreshes fine TV noise and sweeps a faint horizontal band',
      (tester) async {
    await _openApp(tester, 'cyberpunk');
    final finish = _key('cyberpunk-surface-finish');
    expect(finish, findsNWidgets(2));
    final surface = find.descendant(
      of: _key('workspace-surface'),
      matching: finish,
    );
    final first = await _pixels(tester, surface);
    final width = tester.getSize(surface).width.round();
    int alpha(int x, int y) => first.getUint8((y * width + x) * 4 + 3);
    int rowAlpha(int y) =>
        List.generate(width, (x) => alpha(x, y)).reduce((a, b) => a + b);
    expect(rowAlpha(12), greaterThan(rowAlpha(150)));
    final grain = find.descendant(
      of: _key('workspace-surface'),
      matching: _key('cyberpunk-background-grain'),
    );
    final initial = await _pixels(tester, grain);
    double difference(ByteData other) {
      var total = 0;
      for (var i = 3; i < initial.lengthInBytes; i += 4) {
        total += (initial.getUint8(i) - other.getUint8(i)).abs();
      }
      return total * 4 / initial.lengthInBytes;
    }

    await tester.pump(const Duration(milliseconds: 40));
    final near = difference(await _pixels(tester, grain));
    await tester.pump(const Duration(milliseconds: 720));
    final later = difference(await _pixels(tester, grain));
    expect(near, inExclusiveRange(0, 4));
    expect(later, inExclusiveRange(0, 4));
    expect((await _pixels(tester, surface)).buffer.asUint8List(),
        orderedEquals(first.buffer.asUint8List()));

    final layer = tester.widget<RepaintBoundary>(grain).child! as CustomPaint;
    final dynamic noise = layer.painter!;
    final int tick = noise.frame.value;
    await tester.pump(Duration(milliseconds: ((70 - tick) % 1440) * 40));
    final sweep = await _pixels(tester, grain);
    final size = tester.getSize(grain);
    final centre = size.height ~/ 2;
    int bandAlpha(int y) =>
        List.generate(width, (x) => sweep.getUint8((y * width + x) * 4 + 3))
            .reduce((a, b) => a + b);
    expect(bandAlpha(centre), greaterThan(bandAlpha(centre - 12)));

    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    final still = await _pixels(tester, grain);
    await tester.pump(const Duration(seconds: 2));
    expect((await _pixels(tester, grain)).buffer.asUint8List(),
        orderedEquals(still.buffer.asUint8List()));
  });

  testWidgets('Cyberpunk task field glows blue while focused', (tester) async {
    await _openApp(tester, 'cyberpunk');
    await tester.tapAt(const Offset(380, 320));
    await tester.pumpAndSettle();
    final composer = find.byType(TextField);
    final field = tester.widget<TextField>(composer);
    final paint =
        find.ancestor(of: composer, matching: find.byType(CustomPaint));
    final border = tester.widget<CustomPaint>(paint.first).foregroundPainter!;
    expect(field.decoration!.focusedBorder!.borderSide.color,
        const Color(0xFF379BFF));
    expect(field.decoration!.focusedBorder!.borderSide.width,
        greaterThan(field.decoration!.enabledBorder!.borderSide.width));

    Future<int> intensity() async => (await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          const size = Size(120, 48);
          border.paint(Canvas(recorder), size);
          final picture = recorder.endRecording();
          final image = await picture.toImage(120, 48);
          picture.dispose();
          try {
            final data = (await image.toByteData())!;
            return data.getUint8((24 * 120 + 2) * 4 + 3);
          } finally {
            image.dispose();
          }
        }))!;

    final idle = await intensity();
    await tester.tap(composer);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);
    expect(await intensity(), greaterThan(idle * 2));
    field.focusNode!.unfocus();
    await tester.pump();
    expect(await intensity(), idle);
  });

  testWidgets('Cyberpunk reminder opens in red and flashes the selected date',
      (tester) async {
    await _openApp(tester, 'cyberpunk');
    await tester.tapAt(const Offset(380, 320));
    await tester.pumpAndSettle();
    await tester.tap(_key('checklist-reminder-button'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 36));
    expect(_frameBounds(tester).height, 3);
    expect(_contentOpacity(tester), 0);
    await tester.pumpAndSettle();
    const red = Color(0xFFFF2349);
    final dialog =
        tester.widget<AlertDialog>(_key('checklist-reminder-dialog'));
    final frame = dialog.shape! as OutlinedBorder;
    expect(frame.side.color, red);
    const panel = Rect.fromLTWH(0, 0, 400, 200);
    expect(frame.getOuterPath(panel).contains(const Offset(398, 198)), isFalse);

    final calendar = _key('checklist-reminder-calendar');
    const selected = {WidgetState.selected};
    DatePickerThemeData style() => DatePickerTheme.of(tester.element(calendar));
    final day = style().dayShape!.resolve(selected)!;
    expect(day.side.color.toARGB32(), red.toARGB32());
    expect(day.side.width, lessThan(1));
    final square = day.getOuterPath(const Rect.fromLTWH(0, 0, 38, 44));
    expect(square.getBounds().height, square.getBounds().width);
    expect(square.contains(const Offset(37, 40)), isFalse);
    final idle = style().dayBackgroundColor!.resolve(selected)!;

    await tester.tap(find.descendant(of: calendar, matching: find.text('15')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 86));
    final flash = style().dayBackgroundColor!.resolve(selected)!;
    expect(flash.g, greaterThan(.8));
    expect(flash.a, greaterThan(idle.a));
    await tester.pumpAndSettle();
    expect(style().dayBackgroundColor!.resolve(selected), idle);
    expect(find.bySemanticsLabel(RegExp(r'^15, ')), findsOneWidget);
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
