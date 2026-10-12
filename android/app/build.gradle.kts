plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.animelog.offline"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.animelog.offline"
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

    buildTypes {
        release {
            // Local release APKs reuse the installed app's existing certificate
            // so switching build modes preserves in-place updates and user data.
            signingConfig = signingConfigs.getByName("debug")
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

// Direct Gradle builds do not regenerate Flutter's native plugin registrant.
// Fail early instead of producing an APK with MissingPluginException at runtime.
val verifyFlutterPluginRegistration by tasks.registering {
    doLast {
        val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (!registrant.isFile) {
            throw GradleException("Flutter plugin registrant is missing. Run scripts/prepare_android.ps1 before a direct Gradle build.")
        }
        val source = registrant.readText(Charsets.UTF_8)
        val requiredPlugins = listOf(
            "com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin",
            "com.mr.flutter.plugin.filepicker.FilePickerPlugin",
        )
        for (pluginClass in requiredPlugins) {
            val constructor = Regex("new\\s+" + Regex.escape(pluginClass) + "\\s*\\(")
            if (!constructor.containsMatchIn(source)) {
                throw GradleException("Flutter plugin $pluginClass is not registered. Run scripts/prepare_android.ps1 before a direct Gradle build.")
            }
        }
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(verifyFlutterPluginRegistration)
}
