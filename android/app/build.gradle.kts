plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val generatedIconResDir = layout.buildDirectory.dir("generated/checklistIcon/res").get().asFile
val prepareChecklistIcon by tasks.registering(Copy::class) {
    into(generatedIconResDir)
    from(rootProject.file("../Checklist_app_icon_safe.png")) {
        into("mipmap-nodpi")
        rename { "checklist_logo.png" }
    }
    from(rootProject.file("../Checklist_app_icon_safe.png")) {
        into("drawable-nodpi")
        rename { "checklist_logo_foreground.png" }
    }
}

android {
    namespace = "com.gather.checklist"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gather.checklist"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("main").res.srcDir(generatedIconResDir)
    }
}

dependencies {
    implementation(files("libs/ppocr-sdk-release.aar"))
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.21.1")
    // Java API is kept local while the matching JNI binaries are rebuilt with
    // NDK r28 under src/main/jniLibs for Android 16 KB-page compatibility.
    implementation(files("libs/opencv-java-4.5.3.aar"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("androidx.core:core-ktx:1.15.0")
}

tasks.named("preBuild").configure {
    dependsOn(prepareChecklistIcon)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
