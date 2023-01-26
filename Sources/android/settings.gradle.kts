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

include(":app")

val localPropertiesFile = File(rootProject.projectDir, "local.properties")
val properties = Properties()

assert(localPropertiesFile.exists())
localPropertiesFile.reader().apply {  properties.load(this) }

val flutterSdkPath: String? = properties.getProperty("flutter.sdk")
assert(flutterSdkPath != null, fun() = "flutter.sdk not set in local.properties")
apply(from = "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle")
