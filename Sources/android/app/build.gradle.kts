 /**
 * Created by VadNiks on Jul 31 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists())
    localPropertiesFile.reader().apply { localProperties.load(this) }

val flutterRoot = localProperties.getProperty("flutter.sdk")
if (flutterRoot == null)
    throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

var flutterVersionCode = localProperties.getProperty("flutter.versionCode")
if (flutterVersionCode == null)
    flutterVersionCode = "1"

var flutterVersionName = localProperties.getProperty("flutter.versionName")
if (flutterVersionName == null)
    flutterVersionName = "1.0"

plugins {
    id("com.android.application")
    kotlin("android")
    id("kotlin-kapt")
}
apply(from = "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle")
apply(from = "flutter.gradle")

android {
    compileSdk = 33
    ndkVersion = "25.0.8775105"

    signingConfigs {
        register("release") {
            storeFile = file("")
            storePassword = ""
            keyAlias = ""
            keyPassword = ""
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        @Suppress("SuspiciousCollectionReassignment")
        freeCompilerArgs += "-Xjvm-default=all"
    }

    sourceSets {
        named("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.sout.android.notes"
        minSdk = 21
        targetSdk = 33
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        resourceConfigurations += "en"
        javaCompileOptions {
            annotationProcessorOptions {
                arguments.putAll(listOf(
                    "room.schemaLocation" to "$projectDir/schemas",
                    "room.incremental" to "true",
                    "room.expandProjection" to "true"
                ))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles += arrayOf(getDefaultProguardFile("proguard-android-optimize.txt"), File("proguard-rules.pro"))
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles += arrayOf(getDefaultProguardFile("proguard-android-optimize.txt"), File("proguard-rules.pro"))
        }
    }
    buildToolsVersion = "30.0.3"
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.7.10")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.4")

    implementation("androidx.core:core-ktx:1.8.0")

    implementation("androidx.room:room-runtime:2.4.3")
    annotationProcessor("androidx.room:room-compiler:2.4.3")
    kapt("androidx.room:room-compiler:2.4.3")
    implementation("androidx.room:room-ktx:2.4.3")
}
