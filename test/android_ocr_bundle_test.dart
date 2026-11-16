import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cover camera does not add microphone permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
    expect(manifest, contains('tools:node="remove"'));
  });

  test('Android OCR runtime and models remain bundled for offline use', () {
    final detector = File(
      'android/app/src/main/assets/models/det/inference.onnx',
    );
    final recogniser = File(
      'android/app/src/main/assets/models/rec/inference.onnx',
    );
    final recogniserConfig = File(
      'android/app/src/main/assets/models/rec/inference.yml',
    );
    final paddleBridge = File('android/app/libs/ppocr-sdk-release.aar');
    final openCvJava = File('android/app/libs/opencv-java-4.5.3.aar');

    expect(detector.lengthSync(), greaterThan(1000000));
    expect(recogniser.lengthSync(), greaterThan(4000000));
    expect(recogniserConfig.lengthSync(), greaterThan(50000));
    expect(paddleBridge.lengthSync(), greaterThan(90000));
    expect(openCvJava.lengthSync(), greaterThan(300000));

    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));

    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('ppocr-sdk-release.aar'));
    expect(gradle, contains('onnxruntime-android'));
    expect(gradle, contains('opencv-java-4.5.3.aar'));
    expect(gradle, isNot(contains('com.quickbirdstudios:opencv')));

    final activity = File(
      'android/app/src/main/kotlin/com/gather/checklist/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('PaddleOCR.create('));
    expect(activity, contains('MAX_OCR_IMAGE_DIMENSION = 1600'));
    expect(activity, contains('detLimitSideLen = MAX_OCR_IMAGE_DIMENSION'));
    expect(activity, contains('detLimitType = "max"'));
    expect(activity, contains('detMaxSideLimit = MAX_OCR_IMAGE_DIMENSION'));
    expect(activity, contains('BitmapFactory.Options()'));
    expect(activity, contains('Bitmap.createScaledBitmap('));
    expect(activity, contains('engine.recognize(preparedBitmap)'));
  });

  test('Android reminders use exact alarm-clock scheduling and alarm audio',
      () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('android.permission.FOREGROUND_SERVICE'));
    expect(manifest, contains('android.permission.WAKE_LOCK'));
    expect(manifest, contains('.AlarmReceiver'));
    expect(manifest, contains('.ReminderBootReceiver'));
    expect(manifest, contains('.AlarmSoundService'));

    final scheduler = File(
      'android/app/src/main/kotlin/com/gather/checklist/ReminderScheduler.kt',
    ).readAsStringSync();
    expect(scheduler, contains('setAlarmClock('));
    expect(scheduler, contains('fun restore(context: Context)'));

    final alarmService = File(
      'android/app/src/main/kotlin/com/gather/checklist/AlarmSoundService.kt',
    ).readAsStringSync();
    expect(alarmService, contains('AudioAttributes.USAGE_ALARM'));
    expect(alarmService, contains('isLooping = true'));
    expect(alarmService, contains('setWakeMode('));
    expect(alarmService, contains('addAction(0, "stop", stopIntent)'));

    final activity = File(
      'android/app/src/main/kotlin/com/gather/checklist/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('"checklist/reminders"'));
    expect(activity, contains('ReminderScheduler.sync('));
  });

  test('bundled 64-bit OpenCV ELFs use 16 KB load alignment', () {
    final libraries = <String, int>{
      'android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so': 183,
      'android/app/src/main/jniLibs/arm64-v8a/libopencv_java4.so': 183,
      'android/app/src/main/jniLibs/x86_64/libc++_shared.so': 62,
      'android/app/src/main/jniLibs/x86_64/libopencv_java4.so': 62,
    };

    for (final entry in libraries.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      final elf = _Elf64(file.readAsBytesSync());
      expect(elf.machine, entry.value, reason: entry.key);
      expect(elf.loadAlignments, isNotEmpty, reason: entry.key);
      expect(
        elf.loadAlignments.every((alignment) => alignment >= 0x4000),
        isTrue,
        reason: '${entry.key} has a PT_LOAD segment below 16 KB alignment: '
            '${elf.loadAlignments.map((value) => '0x${value.toRadixString(16)}').join(', ')}',
      );
    }
  });
}

class _Elf64 {
  _Elf64(Uint8List bytes) : _data = ByteData.sublistView(bytes) {
    if (bytes.length < 64 ||
        bytes[0] != 0x7f ||
        bytes[1] != 0x45 ||
        bytes[2] != 0x4c ||
        bytes[3] != 0x46) {
      throw const FormatException('Not an ELF file');
    }
    if (bytes[4] != 2 || bytes[5] != 1) {
      throw const FormatException('Expected a little-endian ELF64 file');
    }
  }

  final ByteData _data;

  int get machine => _data.getUint16(18, Endian.little);

  List<int> get loadAlignments {
    final programHeaderOffset = _data.getUint64(32, Endian.little);
    final programHeaderSize = _data.getUint16(54, Endian.little);
    final programHeaderCount = _data.getUint16(56, Endian.little);
    final alignments = <int>[];
    for (var index = 0; index < programHeaderCount; index++) {
      final offset = programHeaderOffset + (index * programHeaderSize);
      if (offset + programHeaderSize > _data.lengthInBytes) {
        throw const FormatException('Truncated ELF program header table');
      }
      if (_data.getUint32(offset, Endian.little) == 1) {
        alignments.add(_data.getUint64(offset + 48, Endian.little));
      }
    }
    return alignments;
  }
}
