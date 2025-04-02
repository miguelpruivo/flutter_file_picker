import java.io.File

pluginManagement {
    val flutterSdkPath: String by lazy {
        val localPropertiesFile = File(rootDir, "local.properties")
        if (!localPropertiesFile.exists()) {
            error("local.properties file not found")
        }

        val properties = java.util.Properties().apply {
            localPropertiesFile.inputStream().use { load(it) }
        }

        properties.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}

include(":app")
