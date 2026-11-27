import 'dart:async';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:checklist_app/app_version.dart';
import 'package:checklist_app/main.dart';
import 'package:checklist_app/services/ocr_service.dart';
import 'package:checklist_app/services/website_previews.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ocrChannel = MethodChannel(OcrService.channelName);

class _TestCamera extends CameraPlatform {
  _TestCamera(this.path);
  final String path;
  final operations = <String>[];
  late StreamController<CameraImageData> _frames;
  final _orientation =
      StreamController<DeviceOrientationChangedEvent>.broadcast(
    sync: true,
  );

  void orient(DeviceOrientation orientation) =>
      _orientation.add(DeviceOrientationChangedEvent(orientation));

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
        CameraDescription(
          name: 'rear',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription camera,
    MediaSettings settings,
  ) async {
    expect(settings.enableAudio, isFalse);
    operations.add('open ${camera.name}');
    return camera.lensDirection == CameraLensDirection.back ? 1 : 2;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    expect(imageFormatGroup, ImageFormatGroup.yuv420);
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(CameraInitializedEvent(
        cameraId,
        640,
        480,
        ExposureMode.auto,
        false,
        FocusMode.auto,
        false,
      ));

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => Stream.multi((_) {});

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      _orientation.stream;

  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) async =>
      operations.add('lock $cameraId ${orientation.name}');

  @override
  Future<void> unlockCaptureOrientation(int cameraId) async =>
      operations.add('unlock $cameraId');

  @override
  Widget buildPreview(int cameraId) => const SizedBox.expand();

  @override
  bool supportsImageStreaming() => true;

  @override
  Stream<CameraImageData> onStreamedFrameAvailable(
    int cameraId, {
    CameraImageStreamOptions? options,
  }) {
    _frames = StreamController(
      sync: true,
      onListen: () => operations.add('startImageStream'),
      onCancel: () async {
        operations.add('stopImageStream');
      },
    );
    return _frames.stream;
  }

  Future<void> sendFrame(WidgetTester tester) async {
    _frames.add(CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
      width: 2,
      height: 2,
      planes: [
        CameraImagePlane(bytes: Uint8List(8), bytesPerRow: 4, bytesPerPixel: 1),
      ],
    ));
    await tester.pump();
    await tester.pump();
  }

  @override
  Future<XFile> takePicture(int cameraId) async {
    operations.add('capture $cameraId');
    return XFile(path);
  }

  @override
  Future<void> dispose(int cameraId) async {
    operations.add('dispose $cameraId');
    unawaited(_frames.close());
  }
}

_TestCamera _mockCamera(WidgetTester tester, String path) {
  final previous = CameraPlatform.instance;
  final camera = _TestCamera(path);
  CameraPlatform.instance = camera;
  addTearDown(() {
    CameraPlatform.instance = previous;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_ocrChannel, null);
  });
  return camera;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android picture menu inserts offline OCR text into a note', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
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
      const text = 'English text\nMagyar ő és ű';
      return {
        'text': text,
        'styles': [
          [0, 7, 1],
          [8, 12, 2],
          [13, text.length, 4],
        ],
      };
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

    expect(find.textContaining('English'), findsOneWidget);
    expect(find.textContaining('Magyar ő és ű'), findsOneWidget);
    final field = find.byType(EditableText);
    final editable = tester.widget<EditableText>(field);
    final formatted = editable.controller.buildTextSpan(
      context: tester.element(field),
      style: editable.style,
      withComposing: false,
    );
    final spans = {
      for (final span in formatted.children!.cast<TextSpan>())
        span.text: span.style,
    };
    expect(spans['English']!.fontWeight, FontWeight.w700);
    expect(spans['text']!.fontStyle, FontStyle.italic);
    expect(spans['Magyar ő és ű']!.decoration, TextDecoration.underline);
    await tester.pump(const Duration(milliseconds: 300));
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('checklist.notes.v1'),
      contains('Magyar ő és ű'),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the Notes camera detects written and QR links and can switch lenses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
      'checklist.notes.v1':
          '[{"id":"note-1","name":"Photo note","createdAt":"2026-11-12T10:00:00.000Z","content":"","categoryId":null}]',
      'checklist.selectedNote.v1': 'note-1',
    });
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const launchChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = tester.binding.defaultBinaryMessenger;
    final opened = <MethodCall>[];
    final photo = (await tester.runAsync(() async {
      final directory =
          await Directory.systemTemp.createTemp('checklist-photo-');
      return File('${directory.path}/capture.jpg').writeAsBytes([0]);
    }))!;
    addTearDown(() => photo.parent.deleteSync(recursive: true));
    final platform = _mockCamera(tester, photo.path);
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    const previews = MethodChannel(WebsitePreviews.channelName);
    final capturedLinks = <String>[];
    messenger.setMockMethodCallHandler(paths, (_) async => photo.parent.path);
    messenger.setMockMethodCallHandler(previews, (call) async {
      expect(call.method, 'capture');
      capturedLinks.add(call.arguments as String);
      return null;
    });
    addTearDown(() {
      for (final channel in [paths, previews]) {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });
    var scans = 0;
    const qrUrl = 'https://example.org/qr';
    const ocrUrl = 'https://example.org/Docs?x=1';
    messenger.setMockMethodCallHandler(_ocrChannel, (call) async {
      if (call.method == 'scanCameraFrame') {
        expect(call.arguments['rowStride'], 4);
        expect(call.arguments['width'], 2);
        expect(call.arguments['height'], 2);
        expect(call.arguments['aspectRatio'], 3 / 4);
        expect(call.arguments['rotation'], scans == 0 ? 90 : 270);
        return scans++ == 0
            ? {'text': 'https : / / example . org /Docs?x=1'}
            : {'qr': qrUrl};
      }
      expect(call.method, 'recognisePhoto');
      expect(call.arguments, {'path': photo.path});
      return {
        'text': 'Magyar ő és ű\n$ocrUrl',
        'qr': qrUrl,
        'styles': [
          [0, 'Magyar'.length, 1],
        ],
      };
    });
    messenger.setMockMethodCallHandler(launchChannel, (call) async {
      opened.add(call);
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(launchChannel, null);
    });

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('NOTES'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-ocr-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('take a photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final camera = find.byKey(const ValueKey('note-camera-dialog'));
    final switchButton = find.byKey(const ValueKey('switch-camera'));
    expect(camera, findsOneWidget);
    expect(find.byTooltip('switch to front camera'), findsOneWidget);
    await platform.sendFrame(tester);
    expect(find.text('link detected'), findsOneWidget);
    expect(find.text(ocrUrl), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-camera-link')));
    await tester.pump();
    expect(opened.single.arguments['url'], ocrUrl);
    expect(opened.single.arguments['useWebView'], isFalse);
    opened.clear();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('link detected'), findsNothing);

    await tester.tap(switchButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byTooltip('switch to back camera'), findsOneWidget);
    expect(platform.operations, [
      'open rear',
      'startImageStream',
      'stopImageStream',
      'dispose 1',
      'open front',
      'startImageStream',
    ]);
    await platform.sendFrame(tester);
    expect(find.text('QR link detected'), findsOneWidget);
    expect(find.text(qrUrl), findsOneWidget);
    expect(opened, isEmpty);
    expect(capturedLinks, isEmpty);

    platform.orient(DeviceOrientation.landscapeRight);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('take-note-photo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 50; attempt++) {
        if (!await photo.exists()) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('The temporary camera photo was not deleted');
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(camera, findsNothing);
    expect(
        platform.operations,
        containsAllInOrder([
          'stopImageStream',
          'lock 2 landscapeRight',
          'capture 2',
          'unlock 2',
          'dispose 2',
        ]));

    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    final imported = editable.widget.controller.text;
    expect(imported, '\uE000Magyar\uE001 ő és ű\n$ocrUrl\n$qrUrl');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('checklist.notes.v1'), contains(qrUrl));
    expect(opened, isEmpty);

    final render = editable.renderEditable;
    final qrStart = imported.indexOf(qrUrl);
    final linkBox = render
        .getBoxesForSelection(
          TextSelection(
            baseOffset: qrStart,
            extentOffset: qrStart + 5,
          ),
        )
        .first;
    await tester.tapAt(render.localToGlobal(linkBox.toRect().center));
    await tester.pumpAndSettle();
    expect(opened.single.method, 'launch');
    expect(opened.single.arguments['url'], qrUrl);
    expect(opened.single.arguments['useWebView'], isFalse);
    expect(editable.widget.focusNode.hasFocus, isFalse);
    await tester.pump(const Duration(seconds: 1));
    for (var steps = 0; steps < 30 && capturedLinks.length < 2; steps++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(capturedLinks, [ocrUrl, qrUrl]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the cover camera detects QR links and releases on cancel', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
    });
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final platform = _mockCamera(tester, 'unused');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_ocrChannel,
        (call) async {
      expect(call.method, 'scanCameraFrame');
      expect(call.arguments['aspectRatio'], 16 / 9);
      return {'qr': 'https://example.org/cover'};
    });

    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cover-source-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('camera'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('switch-camera')), findsOneWidget);
    await platform.sendFrame(tester);
    expect(find.text('QR link detected'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-camera-link')), findsNothing);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(platform.operations, [
      'open rear',
      'startImageStream',
      'stopImageStream',
      'dispose 1',
    ]);
    expect(find.text('QR link detected'), findsNothing);
    expect(find.byKey(const ValueKey('cover-camera-dialog')), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  test('camera QR payloads must be links and are added only once', () {
    expect(
      CameraText(text: 'plain text', qrText: 'Wi-Fi network').noteText,
      'plain text',
    );
    expect(
      CameraText(text: '', qrText: 'https://example.org').noteText,
      'https://example.org',
    );
    expect(
      CameraText(text: 'See example.org', qrText: 'https://example.org')
          .noteText,
      'See example.org',
    );
  });

  test('repairing photo links keeps style offsets in the surrounding text', () {
    const raw = '  Bold https : / / example . org /Notes?q=1 Italic  ';
    final italic = raw.indexOf('Italic');
    final scanned = CameraText.fromNative({
      'text': raw,
      'qr': 'https://example.org/QR',
      'styles': [
        [2, 6, 1],
        [italic, italic + 6, 2],
      ],
    });

    expect(scanned.noteText,
        'Bold https://example.org/Notes?q=1 Italic\nhttps://example.org/QR');
    expect(scanned.styleAt(0), 1);
    expect(scanned.styleAt(scanned.noteText.indexOf('Italic')), 2);
    expect(
        scanned.styleAt(scanned.noteText.indexOf('https://example.org/QR')), 0);
  });

  testWidgets('picture button remains Android-only', (tester) async {
    SharedPreferences.setMockInitialValues({
      'checklist.welcome.v1': true,
      'checklist.lastSeenVersion.v1': checklistRelease,
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
