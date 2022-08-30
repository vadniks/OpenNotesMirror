/**
 * Created by VadNiks on Aug 07 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.reminders

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import com.sout.android.notes.mvp.model.core.Kernel

class BroadcastReceiver : android.content.BroadcastReceiver(), IReceivable {
    override lateinit var kernel: Kernel

    @SuppressLint("UnsafeProtectedBroadcastReceiver")
    override fun onReceive(context: Context, intent: Intent) = processAsync(context) {
        kernel.reminderManager.onBroadcastReceived(intent)
    }
}
