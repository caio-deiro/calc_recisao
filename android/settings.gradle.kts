pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // carrega flutter.sdk do local.properties
    val properties = java.util.Properties()
    val localProps = java.io.File(rootDir, "local.properties")
    if (localProps.exists()) {
        java.io.FileInputStream(localProps).use { properties.load(it) }
    }
    val flutterSdk: String? = properties.getProperty("flutter.sdk")
    require(!flutterSdk.isNullOrBlank()) {
        "Defina flutter.sdk em android/local.properties (ex.: flutter.sdk=D:\\\\flutter)"
    }

    // isto é o “pulo do gato”: includeBuild do gradle do Flutter
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")
}

plugins {
    // necessário para carregar os plugins do Flutter
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // AGP e Kotlin (ajuste se o seu projeto exigir versões específicas)
    // AGP 8.5.1+ é necessário para suporte completo a 16 KB no Google Play
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.10" apply false
}

rootProject.name = "calc_recisao"
include(":app")
