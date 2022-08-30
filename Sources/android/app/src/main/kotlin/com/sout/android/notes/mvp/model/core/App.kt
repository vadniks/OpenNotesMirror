/**
 * Created by VadNiks on Aug 01 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.core

import io.flutter.app.FlutterApplication

class App : FlutterApplication(), Kernel.Injector {
    override lateinit var kernel: Kernel

    override fun onCreate() {
        kernel = Kernel { this }
        super.onCreate()
    }
}
