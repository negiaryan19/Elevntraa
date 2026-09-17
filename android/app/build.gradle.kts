import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (roadmap item 12).
//
// `android/key.properties` is git-ignored and points at the upload keystore
// kept OUTSIDE the repo (see docs/RELEASE.md). Without it a release build
// stops: a debug-signed APK or bundle must never reach a doctor or the Play
// Store. On a developer machine, `RXVARTA_ALLOW_DEBUG_SIGNING=true` lets
// `flutter run --release` fall back to the debug key.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val allowDebugSignedRelease = System.getenv("RXVARTA_ALLOW_DEBUG_SIGNING") == "true"

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.project == project &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle")) &&
            task.name.endsWith("Release")
    }
    if (buildsRelease && !hasReleaseKeystore && !allowDebugSignedRelease) {
        throw GradleException(
            "android/key.properties not found, so this release build has no " +
                "upload key. See docs/RELEASE.md. For a local test only, set " +
                "RXVARTA_ALLOW_DEBUG_SIGNING=true to sign with the debug key."
        )
    }
}

android {
    namespace = "com.rxvarta.rxvarta"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rxvarta.rxvarta"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                // The upload keystore is generated as PKCS12 (openssl); JKS
                // also works if you provide one.
                storeType = keystoreProperties.getProperty("storeType", "PKCS12")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Only reachable with RXVARTA_ALLOW_DEBUG_SIGNING=true (see
                // the task-graph check above).
                signingConfig = signingConfigs.getByName("debug")
            }
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
