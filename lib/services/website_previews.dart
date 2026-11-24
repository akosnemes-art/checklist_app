import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

bool isWebsiteLink(Uri uri) =>
    (uri.scheme == 'https' || uri.scheme == 'http') &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty;

class WebsitePreviews {
  static const channelName = 'checklist/website_previews';
  static const _channel = MethodChannel(channelName);

  final _pending = <Uri, Future<Uint8List?>>{};
  Future<void> _queue = Future.value();

  Future<Uint8List?> load(Uri uri) {
    if (!isWebsiteLink(uri)) return Future.value();
    return _pending.putIfAbsent(uri, () {
      final next = _queue.then((_) => _loadOrCapture(uri));
      _queue = next.then((_) {
        _pending.remove(uri);
      });
      return next;
    });
  }

  Future<Uint8List?> _loadOrCapture(Uri uri) async {
    try {
      final cache = await getApplicationCacheDirectory();
      final id = sha256.convert(utf8.encode(uri.toString()));
      final file = File('${cache.path}/website_previews/$id.image');
      if (await file.exists()) return await file.readAsBytes();

      final bytes = await _channel.invokeMethod<Uint8List>(
        'capture',
        uri.toString(),
      );
      if (bytes == null || bytes.isEmpty) return null;
      await file.parent.create(recursive: true);
      final temporary = await File('${file.path}.pending').writeAsBytes(bytes);
      await temporary.rename(file.path);
      return bytes;
    } catch (_) {
      // An uncached page remains an ordinary, usable link while offline.
      return null;
    }
  }
}
