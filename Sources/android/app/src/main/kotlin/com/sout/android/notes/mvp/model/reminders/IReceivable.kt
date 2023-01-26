/**
 * Created by VadNiks on Aug 21 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.reminders

import android.content.BroadcastReceiver
import android.content.Context
import com.sout.android.notes.mvp.model.core.Kernel

@JvmDefaultWithoutCompatibility
interface IReceivable : Kernel.Injectable {

    fun goAsync(): BroadcastReceiver.PendingResult

    fun processAsync(context: Context, action: suspend () -> Unit) {
        inject(context)
        val pendingResult = goAsync()

        kernel.launchInBackground {
            kernel.onStartReceivingBroadcast()
            action()
            kernel.onStopReceivingBroadcast(pendingResult)
        }
    }
}
