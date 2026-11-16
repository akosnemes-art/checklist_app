import 'package:flutter/services.dart';

enum OcrImageSource { picture, camera }

class OcrService {
  static const channelName = 'checklist/ocr';
  static const _channel = MethodChannel(channelName);

  Future<String?> recognise(OcrImageSource source) {
    return _channel.invokeMethod<String>(
      'pickAndRecognise',
      {'source': source.name},
    );
  }
}
