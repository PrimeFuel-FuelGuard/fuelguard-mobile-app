plugins {
    id("com.android.application")
    // Apply the Flutter Gradle Plugin after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.primefuel.fuelguard"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Unique Application ID for the FuelGuard Android client.
        applicationId = "com.primefuel.fuelguard"
        // SDK versions inherited from the Flutter toolchain configuration.
        // See https://flutter.dev/to/review-gradle-config for details.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Version code resolved from pubspec.yaml; split APKs automatically
        // prepend 1000 * ABI_VERSION during release builds.
        // Override with `-P force-version-code-ignoring-abi=true` when required.
        // Default behavior keeps pubspec.yaml as single source of truth.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Release signing configuration for FuelGuard APK distribution.
            // Uses debug keystore for local verification builds.
            signingConfig = signingConfigs.getByName("debug")
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