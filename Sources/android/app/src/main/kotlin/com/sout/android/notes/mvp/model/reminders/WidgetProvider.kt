/**
 * Created by VadNiks on Aug 21 2022
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
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import com.sout.android.notes.mvp.model.core.Kernel
import kotlinx.coroutines.runBlocking

class WidgetProvider @UiThread constructor() : AppWidgetProvider(), IReceivable {
    override lateinit var kernel: Kernel

    @SuppressLint("UnsafeProtectedBroadcastReceiver")
    @UiThread
    override fun onReceive(context: Context, intent: Intent) = processAsync(context) {
        super.onReceive(context, intent)
    }

    override fun onEnabled(context: Context) = runBlocking {
        kernel.reminderManager.widgetManager.onEnabled()
    }

    @WorkerThread
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) = runBlocking {
        kernel.reminderManager.widgetManager.onUpdate(appWidgetManager, appWidgetIds)
    }

    @WorkerThread
    override fun onDeleted(context: Context, appWidgetIds: IntArray) = runBlocking {
        kernel.reminderManager.widgetManager.onDeleted(appWidgetIds)
    }
}
