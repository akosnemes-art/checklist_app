import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('welcome release metadata stays aligned with pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();

    final release = RegExp(
      r'^version:\s*([^+\s]+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(release, isNotNull);
    expect(
      mainSource,
      contains("const _appVersion = '${release!.group(1)}';"),
    );
    expect(
      mainSource,
      contains("const _appBuildNumber = '${release.group(2)}';"),
    );
  });
}
