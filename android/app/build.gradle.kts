import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
val releaseStorePassword = keystoreProperties.getProperty("storePassword")
val releaseStoreFile = releaseStoreFilePath?.let { file(it) }
val hasReleaseKeystore =
    !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank() &&
        releaseStoreFile?.exists() == true &&
        !releaseStorePassword.isNullOrBlank()

// Performance measurement builds (`-P perfBuild=true`, see
// docs/PERFORMANCE_PASS_2.md) install next to the store app instead of
// replacing it and wiping its data. They never initialise Firebase, which is
// configured for the store package name only.
val isPerfBuild = project.hasProperty("perfBuild")

android {
    namespace = "com.aurumdev.enjoy_lavash_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aurumdev.enjoy_lavash_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = "false"
        if (isPerfBuild) {
            // `-P perfSuffix=.perfb` gives a second variant (e.g. a baseline)
            // its own id, so both stay installed (docs/PERFORMANCE_PASS_2.md).
            applicationIdSuffix =
                (project.findProperty("perfSuffix") as String?) ?: ".perf"
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
        }
        release {
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            // Never fall back to the debug key. Without a keystore the release
            // packaging tasks below fail loudly instead of producing a
            // debug-signed artifact.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

val releasePackagingTasks = setOf(
    "assembleRelease",
    "bundleRelease",
    "packageRelease",
    "packageReleaseBundle",
    "packageReleaseUniversalApk",
)

tasks.configureEach {
    if (isPerfBuild && name.startsWith("process") && name.endsWith("GoogleServices")) {
        enabled = false
    }
    if (name in releasePackagingTasks) {
        doFirst {
            if (!hasReleaseKeystore) {
                throw GradleException(
                    "Release keystore is not configured. Create android/key.properties " +
                        "with storeFile, storePassword, keyAlias and keyPassword " +
                        "before building a release."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
