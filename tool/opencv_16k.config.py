"""OpenCV Android build matrix for CHECKLIST's offline OCR runtime.

This file is executed by OpenCV's platforms/android/build_sdk.py, which
provides the ABI class. The 64-bit targets deliberately repeat the linker
flags that NDK r28 enables by default so a future toolchain change cannot
silently return the project to 4 KB-only ELF binaries.
"""

_page_size_flags = (
    "-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384"
)
_common = {
    "BUILD_opencv_java": "ON",
    # Keep the Java/JNI generator enabled without invoking OpenCV 4.5.3's
    # obsolete Gradle sample-AAR build.
    "BUILD_ANDROID_PROJECTS": "OFF",
    "ANDROID_PROJECTS_BUILD_TYPE": "GRADLE",
    "CMAKE_JOB_POOLS": "compile_pool=2;link_pool=1",
    "CMAKE_JOB_POOL_COMPILE": "compile_pool",
    "CMAKE_JOB_POOL_LINK": "link_pool",
    "CMAKE_POLICY_VERSION_MINIMUM": "3.5",
    "WITH_IPP": "OFF",
    "WITH_TBB": "OFF",
}
_flexible_pages = {
    **_common,
    "ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES": "ON",
    "CMAKE_SHARED_LINKER_FLAGS": _page_size_flags,
    "CMAKE_MODULE_LINKER_FLAGS": _page_size_flags,
    "CMAKE_EXE_LINKER_FLAGS": _page_size_flags,
}

ABIs = [
    ABI(
        "2",
        "armeabi-v7a",
        None,
        26,
        cmake_vars={**_common, "ANDROID_ABI": "armeabi-v7a with NEON"},
    ),
    ABI("3", "arm64-v8a", None, 26, cmake_vars=_flexible_pages),
    ABI("5", "x86_64", None, 26, cmake_vars=_flexible_pages),
]
