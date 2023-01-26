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

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import com.sout.android.notes.NUM_UNDEF
import com.sout.android.notes.R
import com.sout.android.notes.STR_UNDEF
import com.sout.android.notes.mvp.model.core.AbsSingleton
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.model.db.AbsReminderExtra
import com.sout.android.notes.mvp.model.db.Note
import com.sout.android.notes.mvp.model.reminders.ReminderManager.ReminderType
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@WorkerThread
class WidgetManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private val appWidgetManager get() = AppWidgetManager.getInstance(kernel.context)

    suspend fun onUpdate(
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) = appWidgetIds.forEach { updateEach(it, appWidgetManager, false) }

    private suspend fun updateEach(id: Int, appWidgetManager: AppWidgetManager, reset: Boolean) {
        val note = if (!reset) getNoteByWidgetId(id) else null

        val views = RemoteViews(kernel.context.packageName, R.layout.widget).apply {
            setOnClickPendingIntent(
                R.id.widget_layout,
                kernel.reminderManager.createActivityOpenIntent(note?.id ?: NUM_UNDEF, ReminderType.WIDGETED)
            )

            setOnClickPendingIntent(
                R.id.widget_button,
                kernel.reminderManager.createActivityOpenIntent(null, null) {
                    action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
                }
            )

            setInt(R.id.widget_layout, SET_BACKGROUND_COLOR, note?.color?.value ?: Color.WHITE)
            setImageViewResource(R.id.widget_button,
                lightOrDark(R.drawable.icon_edit_dark, R.drawable.icon_edit_light, null, note))

            val textColor = lightOrDark(Color.BLACK, Color.WHITE, Color.RED, note)
            setTextColor(R.id.widget_title, textColor)
            setTextColor(R.id.widget_text, textColor)

            setInt(R.id.widget_divider, SET_BACKGROUND_COLOR, lightOrDark(Color.BLACK, Color.WHITE, null, note))

            setTextViewText(R.id.widget_title, note?.title ?: STR_UNDEF)
            setTextViewText(R.id.widget_text, note?.text ?: STR_UNDEF)
        }
        appWidgetManager.updateAppWidget(id, views)
    }

    private fun <T> lightOrDark(light: T, dark: T, onNull: T?, note: Note?) =
        if (note == null) onNull ?: light else if (note.color?.isDark() == true) dark else light

    suspend fun unset(noteId: Int) = (kernel
        .databaseManager
        .getReminderExtraById(noteId) as ExtraWidgetReminder?
    )?.id.apply {
        updateEach(this!!, appWidgetManager, true)
    }

    suspend fun onDeleted(appWidgetIds: IntArray) = appWidgetIds.forEach { deleteEach(it) }

    private suspend fun deleteEach(id: Int) {
        kernel.databaseManager.setReminderExtra(getNoteByWidgetId(id)?.id ?: return, null)
    }

    @WorkerThread
    fun onActivityNewIntent(intent: Intent) {
        if (intent.action !== AppWidgetManager.ACTION_APPWIDGET_CONFIGURE) return

        kernel.interop.callDartMethod(
            CONFIGURE_WIDGET_METHOD,
            intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            ).apply { assert(this != AppWidgetManager.INVALID_APPWIDGET_ID) }
        )
    }

    private suspend fun getNoteByWidgetId(id: Int) = kernel
        .databaseManager
        .getNotesWithReminders()
        .find(fun(it) = it.reminderExtra!!.let { extra ->
            if (extra !is ExtraWidgetReminder) false
            else extra.id == id
        })

    @Suppress("UNCHECKED_CAST")
    suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        SET_WIDGET_METHOD -> {
            val arguments = call.arguments as List<Int?>
            setWidget(arguments[0], arguments[1]!!)
            result.success(null)
            true
        }
        else -> false
    }

    private suspend fun setWidget(noteId: Int?, widgetId: Int) {
        assert(kernel.activityPresenter.isCompleted)

        if (noteId != null) {
            val note = kernel.databaseManager.getNoteById(noteId)!!
            assert(note.reminderExtra == null)

            getNoteByWidgetId(widgetId).apply {
                if (this == null) return@apply
                assert(reminderExtra!! is ExtraWidgetReminder)
                kernel.databaseManager.setReminderExtra(id!!, null)
            }

            kernel.databaseManager.setReminderExtra(noteId, ExtraWidgetReminder(widgetId))
            updateEach(widgetId, appWidgetManager, false)
        }

        kernel.activityPresenter.await().apply { kernel.launchInMain {
            setResult(if (noteId == null) Activity.RESULT_CANCELED else Activity.RESULT_OK)
            finish()
        } }
    }

    suspend fun onEnabled() = kernel.databaseManager.getNotesWithReminders().forEach {
        if (it.reminderExtra?.type !== ReminderType.WIDGETED) return@forEach
        updateEach(it.reminderExtra.id, appWidgetManager, false)
    }

    suspend fun update(note: Note) {
        val extra = kernel.databaseManager.getReminderExtraById(note.id!!)!!
        kernel.databaseManager.updateNote(note.copy(reminderExtra = extra))
        updateEach(extra.id, appWidgetManager, false)
    }

    fun createReminderExtra(widgetId: Int) = ExtraWidgetReminder(widgetId) as AbsReminderExtra

    private data class ExtraWidgetReminder(override val id: Int) : AbsReminderExtra(id, ReminderType.WIDGETED)

    companion object {
        private const val SET_BACKGROUND_COLOR = "setBackgroundColor"
        private const val CONFIGURE_WIDGET_METHOD = "configureWidget"
        private const val SET_WIDGET_METHOD = "setWidget"
    }
}
