import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads its credentials from the first source that has them:
// android/key.properties on a developer machine, or the ANDROID_KEYSTORE_*
// environment variables that CI fills in from the repository secrets. Without
// either, release builds fall back to the debug key, so a plain
// `flutter build apk --release` still produces something installable.
// See docs/ci-cd.md for how to create the keystore and wire up the secrets.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val releaseStoreFile =
    System.getenv("ANDROID_KEYSTORE_PATH")
        ?: keystoreProperties.getProperty("storeFile")
val releaseStorePassword =
    System.getenv("ANDROID_KEYSTORE_PASSWORD")
        ?: keystoreProperties.getProperty("storePassword")
val releaseKeyAlias =
    System.getenv("ANDROID_KEY_ALIAS")
        ?: keystoreProperties.getProperty("keyAlias")
val releaseKeyPassword =
    System.getenv("ANDROID_KEY_PASSWORD")
        ?: keystoreProperties.getProperty("keyPassword")
val hasReleaseSigning =
    releaseStoreFile != null &&
        file(releaseStoreFile).exists() &&
        releaseStorePassword != null &&
        releaseKeyAlias != null &&
        releaseKeyPassword != null

// The store variant refuses to ship debug-signed bits: when this is set, a
// missing keystore is a build error rather than a quiet fallback.
if (System.getenv("REQUIRE_RELEASE_SIGNING") == "true" && !hasReleaseSigning) {
    throw GradleException(
        "REQUIRE_RELEASE_SIGNING is set, but no release keystore was found. " +
            "Provide android/key.properties or the ANDROID_KEYSTORE_* environment " +
            "variables (see docs/ci-cd.md).",
    )
}

// Firebase is opt-in: without google-services.json the app still builds and
// runs, it just cannot receive push notifications. Drop the file in to enable
// them (see docs/notifications.md).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "app.qutty.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications, which uses java.time APIs
        // that are only available on Android through desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.qutty.client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Signed with the release keystore when one is configured, and
            // with the debug key otherwise, so release builds are always
            // signed by something and installable.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
