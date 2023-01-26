/**
 * Created by VadNiks on Jul 31 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
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
    ndkVersion = "25.1.8937393"

    signingConfigs {
        register("release") {
            val jks = File(projectDir.parent, "jks.txt").readLines()

            storeFile = file("/data/Downloads/keyForApp3.jks")
            storePassword = jks[0]
            keyAlias = jks[1]
            keyPassword = jks[2]
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
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
            signingConfig = signingConfigs.getByName("release")

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
    buildToolsVersion = "33.0.1"
    namespace = "com.sout.android.notes"
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.7.10")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.4")
    implementation("androidx.core:core-ktx:1.9.0")
    implementation("androidx.room:room-runtime:2.5.0")
    implementation("androidx.room:room-ktx:2.5.0")

    annotationProcessor("androidx.room:room-compiler:2.5.0")
    kapt("androidx.room:room-compiler:2.5.0")
}
