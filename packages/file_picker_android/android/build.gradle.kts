import com.android.build.gradle.LibraryExtension
import groovy.lang.GroovyObject
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.withGroovyBuilder

group = "com.mr.flutter.plugin.filepicker"
version = "1.0-SNAPSHOT"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

fun GroovyObject.intProperty(name: String): Int {
    val value = getProperty(name)
    return when (value) {
        is Number -> value.toInt()
        is String -> value.toInt()
        else -> error("Property '$name' is not an Int-compatible value: $value")
    }
}

val agpVersion = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION
    .substringBefore('.')
    .toInt()
val builtInKotlinProperty = providers.gradleProperty("android.builtInKotlin").orNull
val isBuiltInKotlinEnabled = agpVersion >= 9 &&
    (builtInKotlinProperty == null || builtInKotlinProperty.toBoolean())
val shouldApplyKotlinAndroidPlugin = agpVersion < 9 || !isBuiltInKotlinEnabled

apply(plugin = "com.android.library")
if (shouldApplyKotlinAndroidPlugin) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

val flutterExtension = extensions.getByName("flutter") as GroovyObject
val flutterCompileSdkVersion = flutterExtension.intProperty("compileSdkVersion")

configure<LibraryExtension> {
    compileSdk = flutterCompileSdkVersion
    namespace = "com.mr.flutter.plugin.filepicker"

    defaultConfig {
        minSdk = 21
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("proguard-rules.pro")
    }

    lint {
        disable += "InvalidPackage"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    if (shouldApplyKotlinAndroidPlugin) {
        withGroovyBuilder {
            "kotlinOptions" {
                setProperty("jvmTarget", JavaVersion.VERSION_17.toString())
            }
        }
    }
}

dependencies {
    add("implementation", "androidx.core:core:1.18.0")
    add("implementation", "androidx.core:core-ktx:1.18.0")
    add("implementation", "androidx.annotation:annotation:1.10.0")
    add("implementation", "androidx.lifecycle:lifecycle-runtime:2.10.0")
    add("implementation", "org.apache.tika:tika-core:3.3.0")
}

