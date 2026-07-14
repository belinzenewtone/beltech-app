import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin now provides Built-in Kotlin; do not apply kotlin-android here.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseSigningKeys = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val releaseSigningMissingKeys = releaseSigningKeys
    .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
val releaseStoreFilePath = keystoreProperties.getProperty("storeFile") ?: ""
val releaseStoreFile = if (releaseStoreFilePath.isBlank()) {
    null
} else {
    rootProject.file(releaseStoreFilePath)
}
val hasReleaseSigningConfig =
    keystorePropertiesFile.exists() &&
        releaseSigningMissingKeys.isEmpty() &&
        (releaseStoreFile?.exists() == true)
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseTaskRequested && !hasReleaseSigningConfig) {
    val issues = buildList {
        if (!keystorePropertiesFile.exists()) {
            add("android/key.properties is missing.")
        }
        if (releaseSigningMissingKeys.isNotEmpty()) {
            add("Missing keys in android/key.properties: ${releaseSigningMissingKeys.joinToString(", ")}.")
        }
        if (releaseStoreFile == null || !releaseStoreFile.exists()) {
            add("Keystore file from 'storeFile' was not found.")
        }
    }.joinToString(" ")
    throw GradleException(
        "Release signing is required and debug fallback is disabled. " +
            "$issues " +
            "Create android/key.properties from android/key.properties.example " +
            "and use the same release keystore for all installs/updates.",
    )
}

android {
    namespace = "com.beltech.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.beltech.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = releaseStoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    packaging {
        jniLibs {
            // Extract native libraries at install time so the system can align
            // them to 16KB pages on Android 15+ / 16KB page-size devices.
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning != null) {
                signingConfig = releaseSigning
            } else if (releaseTaskRequested) {
                throw GradleException(
                    "Release signing config was not created. " +
                        "Set up android/key.properties with your release keystore.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
