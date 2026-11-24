import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'note_links.dart';

enum OcrImageSource { picture, camera }

class CameraText {
  CameraText({required String text, String? qrText})
      : text = restorePhotoWebLinks(text.trim()),
        qrLink = _readQrLink(qrText);

  final String text;
  final Uri? qrLink;

  List<NoteLink> get textLinks => findNoteLinks(text);

  String get noteText {
    final link = qrLink;
    if (link == null || textLinks.any((match) => match.uri == link)) {
      return text;
    }
    return text.isEmpty ? link.toString() : '$text\n$link';
  }

  static Uri? _readQrLink(String? value) {
    if (value == null) return null;
    final payload = value.trim();
    final links = findNoteLinks(payload);
    if (links.length != 1 ||
        links.single.start != 0 ||
        links.single.end != payload.length) {
      return null;
    }
    return links.single.uri;
  }
}

class OcrService {
  static const channelName = 'checklist/ocr';
  static const _channel = MethodChannel(channelName);

  Future<String?> recognisePicture() {
    return _channel.invokeMethod<String>(
      'pickAndRecognise',
      {'source': OcrImageSource.picture.name},
    );
  }

  Future<String> recognisePhoto(String path) async =>
      (await _readCameraText('recognisePhoto', {'path': path})).noteText;

  Future<CameraText> scanFrame(
    CameraImage image, {
    required int rotation,
    required double aspectRatio,
  }) {
    final luma = image.planes.first;
    return _readCameraText('scanCameraFrame', {
      'luma': luma.bytes,
      'width': image.width,
      'height': image.height,
      'rowStride': luma.bytesPerRow,
      'pixelStride': luma.bytesPerPixel ?? 1,
      'rotation': rotation,
      'aspectRatio': aspectRatio,
    });
  }

  Future<CameraText> _readCameraText(
    String method,
    Map<String, Object> arguments,
  ) async {
    final result = await _channel.invokeMapMethod<String, String>(
      method,
      arguments,
    );
    return CameraText(text: result?['text'] ?? '', qrText: result?['qr']);
  }
}
