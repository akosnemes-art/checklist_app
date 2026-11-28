import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'note_links.dart';

enum OcrImageSource { picture, camera }

class CameraText {
  CameraText({required String text, String? qrText})
      : this._(text: restorePhotoWebLinks(text.trim()), qrText: qrText);

  CameraText._({
    required this.text,
    String? qrText,
    List<int> styles = const [],
  })  : _styles = styles,
        qrLink = _readQrLink(qrText);

  factory CameraText.fromNative(Object? data) {
    if (data is String) return CameraText(text: data);
    if (data is! Map) return CameraText(text: '');
    final raw = data['text'] as String? ?? '';
    final qrText = data['qr'] as String?;
    final regions = data['styles'];
    if (regions is! List || regions.isEmpty) {
      return CameraText(text: raw, qrText: qrText);
    }

    final flags = List.filled(raw.length, 0);
    for (final region in regions) {
      if (region is! List || region.length != 3) continue;
      final [start, end, style] = region;
      if (start is! int ||
          end is! int ||
          style is! int ||
          start < 0 ||
          end <= start ||
          end > flags.length) {
        continue;
      }
      flags.fillRange(start, end, style & 7);
    }

    final styles = <int>[];
    var last = 0;
    final repaired =
        restorePhotoWebLinks(raw, onRewrite: (start, end, replacement) {
      styles.addAll(flags.getRange(last, start));
      // A repaired address can combine several regions. Keep it intact and
      // use the Notes editor's ordinary link styling.
      styles.addAll(List.filled(replacement.length, 0));
      last = end;
    });
    styles.addAll(flags.getRange(last, flags.length));
    final trimmed = repaired.trim();
    final leading = repaired.length - repaired.trimLeft().length;
    return CameraText._(
      text: trimmed,
      qrText: qrText,
      styles: styles.sublist(leading, leading + trimmed.length),
    );
  }

  final String text;
  final Uri? qrLink;
  final List<int> _styles;

  int styleAt(int offset) => offset < _styles.length ? _styles[offset] : 0;

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

  Future<CameraText?> recognisePicture() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final picture = await FilePicker.pickFile(type: FileType.image);
      if (picture == null) return null;
      final path = picture.path;
      if (path == null) throw PlatformException(code: 'invalid_image');
      return recognisePhoto(path);
    }
    final result = await _channel.invokeMethod<Object>(
      'pickAndRecognise',
      {'source': OcrImageSource.picture.name},
    );
    return result == null ? null : CameraText.fromNative(result);
  }

  Future<CameraText> recognisePhoto(String path) =>
      _readCameraText('recognisePhoto', {'path': path});

  Future<CameraText> scanFrame(
    CameraImage image, {
    required int rotation,
    required double aspectRatio,
    bool mirrored = false,
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
      if (mirrored) 'mirrored': true,
    });
  }

  Future<CameraText> _readCameraText(
    String method,
    Map<String, Object> arguments,
  ) async {
    final result = await _channel.invokeMethod<Object>(
      method,
      arguments,
    );
    return CameraText.fromNative(result);
  }
}
