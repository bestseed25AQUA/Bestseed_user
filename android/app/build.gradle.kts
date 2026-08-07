import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
keystoreProperties.load(keystorePropertiesFile.inputStream())

/// Google Maps key for the Android manifest, read straight out of the
/// gitignored lib/app/utils/secrets.dart — the same file the Dart code uses, so
/// the key is defined in exactly one place and no build flag is needed.
/// CI may set a GOOGLE_MAPS_API_KEY environment variable instead.
val googleMapsApiKey: String = run {
    System.getenv("GOOGLE_MAPS_API_KEY")?.takeIf { it.isNotBlank() }?.let { return@run it }

    val secretsFile = rootProject.file("../lib/app/utils/secrets.dart")
    if (!secretsFile.exists()) {
        logger.warn(
            "⚠️  lib/app/utils/secrets.dart not found — the Google Maps key will be " +
                "empty and maps will render blank. Copy secrets.example.dart to secrets.dart."
        )
        return@run ""
    }
    val match = Regex("""googleMaps\s*=\s*'([^']*)'""").find(secretsFile.readText())
    match?.groupValues?.get(1).orEmpty().also {
        if (it.isBlank()) {
            logger.warn("⚠️  googleMaps key missing/empty in secrets.dart — maps will render blank.")
        }
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.app.bestseed"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.app.bestseed"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Substituted into ${GOOGLE_MAPS_API_KEY} in AndroidManifest.xml so the
        // key never appears in a tracked file.
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Ship the bundle as ONE self-contained APK instead of a base plus ABI /
    // density / language splits.
    //
    // play-core (pulled in by in_app_update) refuses to start the app when the
    // installed base APK is missing any of its splits, showing "Something went
    // wrong — Check that Google Play is enabled on your device...". That was
    // happening on UPDATE only: a fresh install delivered a matching set, but
    // an update could leave the device with a base whose splits didn't apply,
    // and a full uninstall/reinstall cleared it.
    //
    // Language splits matter especially here — this app ships 13 locales, and a
    // missing language split also means missing translations. With no splits
    // there is nothing to go missing. The cost is download size.
    bundle {
        language { enableSplit = false }
        density { enableSplit = false }
        abi { enableSplit = false }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
