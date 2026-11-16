# OpenCV 4.5.3 16 KB Android build

CHECKLIST's PaddleOCR bridge calls `System.loadLibrary("opencv_java4")`, so the
app must retain OpenCV 4.x's library name. The previous QuickBird 4.5.3 binary
used 4 KB ELF load alignment and could not load on a 16 KB-page Android device.

The checked-in JNI libraries were rebuilt from the official OpenCV 4.5.3
source archive using Android NDK `28.2.13676358`, API 26, and
[`opencv_16k.config.py`](opencv_16k.config.py). The source archive SHA-256 is:

`77f616ae4bea416674d8c373984b20c8bd55e7db887fd38c6df73463a0647bab`

Before running OpenCV's `platforms/android/build_sdk.py`, apply
[`opencv-4.5.3-no-sdk-aar.patch`](opencv-4.5.3-no-sdk-aar.patch). It skips only
OpenCV's obsolete sample-AAR Gradle task; it does not alter the Java generator
or native library. Build the `core,imgproc,imgcodecs,java` module list. Those
are the complete OpenCV packages referenced by `ppocr-sdk-release.aar`.

After assembling an APK, run:

```sh
python3 tool/check_android_elf_alignment.py path/to/checklist.apk
```

The check validates every 64-bit native library's ELF `PT_LOAD` alignment and
the APK data offset of every uncompressed 64-bit library.
