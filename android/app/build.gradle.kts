import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.exists()) {
    releaseSigningPropertiesFile.inputStream().use { releaseSigningProperties.load(it) }
}

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    doLast {
        if (!releaseSigningPropertiesFile.isFile) {
            throw GradleException(
                "Release signing is not configured. Copy android/key.properties.example " +
                    "to android/key.properties and configure a private upload keystore."
            )
        }

        val requiredKeys = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        val missingKeys = requiredKeys.filter { key ->
            val value = releaseSigningProperties.getProperty(key)?.trim()
            value.isNullOrEmpty() || value.startsWith("REPLACE_WITH_")
        }
        if (missingKeys.isNotEmpty()) {
            throw GradleException(
                "Release signing is missing valid values for: ${missingKeys.joinToString()}."
            )
        }

        val keystore = rootProject.file(releaseSigningProperties.getProperty("storeFile"))
        if (!keystore.isFile) {
            throw GradleException("Release keystore does not exist: ${keystore.path}")
        }
    }
}

// Keep local debug builds usable without release credentials, but never let a
// release variant proceed with an unsigned or example-configured identity.
tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(validateReleaseSigning)
    }
}

android {
    namespace = "com.nmnext.nmvybe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.nmnext.nmvybe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseSigningProperties.getProperty("keyAlias")
            keyPassword = releaseSigningProperties.getProperty("keyPassword")
            releaseSigningProperties.getProperty("storeFile")?.let {
                storeFile = rootProject.file(it)
            }
            storePassword = releaseSigningProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Never ship a release binary under the debug signing identity.
            // Configure android/key.properties locally or in the release CI environment.
            signingConfig = signingConfigs.getByName("release")
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
