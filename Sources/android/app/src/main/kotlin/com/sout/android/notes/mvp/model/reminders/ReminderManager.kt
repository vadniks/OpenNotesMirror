/**
 * Created by VadNiks on Aug 11 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.reminders

import android.app.PendingIntent
import android.content.Intent
import android.database.Cursor
import android.os.Build
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import androidx.core.database.getLongOrNull
import com.sout.android.notes.NUM_UNDEF
import com.sout.android.notes.NUM_UNDEF_L
import com.sout.android.notes.NUM_ZERO
import com.sout.android.notes.PACKAGE
import com.sout.android.notes.mvp.model.Observable
import com.sout.android.notes.mvp.model.core.AbsSingleton
import com.sout.android.notes.mvp.model.core.Interop
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.model.db.AbsReminderExtra
import com.sout.android.notes.mvp.model.db.Note
import com.sout.android.notes.mvp.model.db.toMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.absoluteValue

@WorkerThread
class ReminderManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private val notificationManager = NotificationManager(kernel)
    private val broadcasts = Observable<Intent, Unit>()
    val widgetManager = WidgetManager(kernel)
    private val handlers = Observable<Pair<MethodCall, MethodChannel.Result>, Boolean>()

    init {
        kernel.interop.observeDartMethodHandling(true) { handleDartMethod(it.first, it.second) }
        broadcasts.observe(notificationManager::handleBroadcast, true)
        handlers.observe({ notificationManager.handleDartMethod(it.first, it.second) }, true)
        handlers.observe({ widgetManager.handleDartMethod(it.first, it.second) }, true)
    }

    @Suppress("UNCHECKED_CAST")
    private suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        CREATE_OR_UPDATE_REMINDER_METHOD -> {
            val arguments = call.arguments as List<Any>
            val note = Note.fromMap(arguments[0] as Map<String, Any?>)
            val type = ReminderType.create(arguments[1] as Int)
            val dateTime = (arguments[2] as Number).toLong()
            val period = (arguments[3] as Number).toLong()

            assert(type === ReminderType.WIDGETED
                    && dateTime == NUM_UNDEF.toLong()
                    && period == NUM_UNDEF.toLong()
                    || type !== ReminderType.WIDGETED
            )

            val id = if (type !== ReminderType.WIDGETED)
                notificationManager.createOrUpdate(
                    note,
                    type,
                    if (dateTime == NUM_UNDEF.toLong()) null else dateTime,
                    if (period == NUM_UNDEF.toLong()) null else period
                )
            else {
                assert(note.id != null)
                widgetManager.update(note)
                NUM_UNDEF
            }

            result.success(id)
            true
        }
        IS_REMINDER_SET_METHOD -> {
            result.success(kernel.databaseManager.isReminderSet(call.arguments as Int))
            true
        }
        CANCEL_REMINDER_METHOD -> {
            val arguments = call.arguments as List<Any>
            cancelReminder(
                arguments[0] as Int,
                ReminderType.create(arguments[1] as Int),
                arguments[2] as Boolean
            )
            result.success(null)
            true
        }
        GET_REMINDER_DETAILS_METHOD -> {
            result.success(notificationManager.getTimedOrScheduledDetails(call.arguments as Int?))
            true
        }
        else -> {
            var res = handlers.size == 0
            handlers.notify(call to result) { res = res or it }
            res
        }
    }

    suspend fun onBroadcastReceived(intent: Intent) = broadcasts.notify(intent, null)

    suspend fun cancelReminder(id: Int, type: ReminderType, cancelInDB: Boolean) {
        if (type !== ReminderType.WIDGETED) notificationManager.cancel(id, type)
        else widgetManager.unset(id)

        if (cancelInDB)
            kernel.databaseManager.setReminderExtra(id, null)
    }

    fun createBroadcastIntent() = Intent(kernel.context, BroadcastReceiver::class.java)

    @UiThread
    fun onActivityNewIntent(intent: Intent) = kernel.launchInBackground {
        if (intent.action !== ACTION_OPEN) {
            widgetManager.onActivityNewIntent(intent)
            return@launchInBackground
        }

        kernel.interop.callDartMethod(
            Interop.LAUNCH_EDIT_PAGE_METHOD,
            kernel.databaseManager.getNoteById(
                getNoteId(intent) ?:
                return@launchInBackground
            )!!.toMap()
        )
    }

    private fun getNoteId(intent: Intent): Int? {
        val id = intent.getIntExtra(EXTRA_NOTE_ID, NUM_UNDEF)
        return if (id != NUM_UNDEF) id else null
    }

    fun createActivityOpenIntent(
        id: Int?,
        type: ReminderType?,
        setter: (Intent.() -> Unit)? = null
    ): PendingIntent = PendingIntent.getActivity(
        kernel.context,
        makeId(),
        kernel.createActivityOpenIntent().apply {
            assert(setter == null && id != null && type != null
                || setter != null && id == null && type == null)

            if (setter != null) {
                setter(this)
                return@apply
            }

            action = ACTION_OPEN
            putExtra(EXTRA_NOTE_ID, id!!)
            putExtra(EXTRA_REMINDER_TYPE, type!!.value)
        },
        pendingIntentFlags()
    )

    fun createReminderExtra(cursor: Cursor): AbsReminderExtra? {
        val widC = cursor.getColumnIndex("wid")
        val nidC = cursor.getColumnIndex("nid")
        val ridC = cursor.getColumnIndex("rid")
        val sidC = cursor.getColumnIndex("sid")

        val array = arrayOfNulls<Long>(4)

        val wid = cursor.getLongOrNull(widC).takeUnless { it == NUM_UNDEF_L }.also { array[0] = it }
        val nid = cursor.getLongOrNull(nidC).takeUnless { it == NUM_UNDEF_L }.also { array[1] = it }
        val rid = cursor.getLongOrNull(ridC).takeUnless { it == NUM_UNDEF_L }.also { array[2] = it }
        val sid = cursor.getLongOrNull(sidC).takeUnless { it == NUM_UNDEF_L }.also { array[3] = it }

        assert(array.count(fun(it) = it != null).run { this == coerceIn(0..1) })

        return when {
            wid != null -> widgetManager.createReminderExtra(wid.toInt())
            nid != null -> notificationManager.createReminderExtra(nid.toInt(),
                ReminderType.ATTACHED
            )
            rid != null -> notificationManager.createReminderExtra(rid.toInt(), ReminderType.TIMED)
            sid != null -> notificationManager.createReminderExtra(sid.toInt(),
                ReminderType.SCHEDULED
            )
            else -> null
        }
    }

    enum class ReminderType(val value: Int) {
        ATTACHED(0), TIMED(1), SCHEDULED(2), WIDGETED(3);

        companion object {
            fun create(value: Int) = values().find { it.value == value }!!
        }
    }

    companion object {
        private const val CREATE_OR_UPDATE_REMINDER_METHOD = "createOrUpdateReminder"
        private const val IS_REMINDER_SET_METHOD = "isReminderSet"
        private const val CANCEL_REMINDER_METHOD = "cancelReminder"
        private const val GET_REMINDER_DETAILS_METHOD = "getReminderDetails"
        const val EXTRA_REMINDER_TYPE = "EXTRA_REMINDER_TYPE"
        const val EXTRA_NOTE_ID = "EXTRA_NOTE_ID"
        const val ACTION_OPEN = "$PACKAGE.ACTION_OPEN"

        fun makeId() = System.currentTimeMillis().toInt().absoluteValue

        fun pendingIntentFlags() = NUM_ZERO or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE else NUM_ZERO)
    }
}
