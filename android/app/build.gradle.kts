plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.proyecto_final" // Make sure this is your actual namespace
    compileSdk = flutter.compileSdkVersion // This usually comes from Flutter's settings, e.g., 34

    // MODIFIED: Set ndkVersion explicitly to the highest required by your plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Your project uses Java 11, which is fine.
        // Many Flutter projects and plugins still target Java 8 for wider compatibility.
        // If you encounter issues with other plugins, you might consider changing these to JavaVersion.VERSION_1_8.
        // For now, we'll keep your Java 11 setting.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Ensure this matches your Java compatibility version.
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.proyecto_final" // Make sure this is your actual application ID
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion // e.g., 21
        targetSdk = flutter.targetSdkVersion // e.g., 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // Consider enabling R8/ProGuard for release builds
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    // It's good practice to include packagingOptions if you haven't,
    // especially if you encounter issues with duplicate native libraries.
    // packagingOptions {
    //     resources.excludes.add("/META-INF/{AL2.0,LGPL2.1}")
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // Example: Add Kotlin standard library if not already present (usually is)
    // implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version") // or jdk11
    // Add other dependencies here if needed
}
