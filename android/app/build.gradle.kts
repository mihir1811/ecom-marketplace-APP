import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (never committed), e.g.
//   storeFile=C:/keys/gemworld-upload.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// Without it, release falls back to the debug key exactly as before.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.example.gemworld"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Must match the Android app registered in Firebase (google-services.json).
        applicationId = "com.gemworld.notifications"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Plugins with prebuilt .so files (WebRTC via livekit_client) ship every ABI
        // regardless of --target-platform. Package only the ABIs Flutter itself built.
        (project.findProperty("target-platform") as String?)?.let { platforms ->
            val abiByPlatform = mapOf(
                "android-arm" to "armeabi-v7a",
                "android-arm64" to "arm64-v8a",
                "android-x64" to "x86_64",
            )
            // The Flutter plugin presets all three ABIs, so replace rather than append.
            ndk {
                abiFilters.clear()
                abiFilters += platforms.split(",").mapNotNull { abiByPlatform[it.trim()] }
            }
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Flutter's Gradle plugin already turns on R8 code + resource
            // shrinking for release; app keep rules live in proguard-rules.pro.
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKeystore) "release" else "debug",
            )
            isDebuggable = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
