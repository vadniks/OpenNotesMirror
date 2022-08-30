/**
 * Created by VadNiks on Aug 05 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.reminders

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import androidx.core.app.AlarmManagerCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.sout.android.notes.NUM_UNDEF
import com.sout.android.notes.PACKAGE
import com.sout.android.notes.R
import com.sout.android.notes.STR_EMPTY
import com.sout.android.notes.mvp.model.core.AbsSingleton
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.model.db.AbsReminderExtra
import com.sout.android.notes.mvp.model.db.Note
import com.sout.android.notes.mvp.model.reminders.ReminderManager.ReminderType
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.collections.ArrayList

@WorkerThread
class NotificationManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private var canPostNotifications = false
    private var canSchedule = false

    init { checkSelfPermission() }

    @UiThread
    private fun checkSelfPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            canPostNotifications = true
            canSchedule = true
            return
        }

        canPostNotifications =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) kernel
                .context
                .checkSelfPermission(Manifest
                    .permission
                    .POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            else true

        canSchedule =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) kernel
                .context
                .checkSelfPermission(Manifest
                    .permission
                    .SCHEDULE_EXACT_ALARM) == PackageManager.PERMISSION_GRANTED
            else true

        var permissions = Array(0) { STR_EMPTY }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            permissions = permissions.plus(Manifest.permission.POST_NOTIFICATIONS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            permissions = permissions.plus(Manifest.permission.SCHEDULE_EXACT_ALARM)

        if (!canPostNotifications || !canSchedule) kernel.launchInBackground {
            kernel.activityPresenter.await().requestPermission(permissions) {
                assert(permissions.size == 1 || permissions.size == 2)
                val post = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) 0 else NUM_UNDEF
                val schedule =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                        if (permissions.size == 1) 0 else 1
                    else NUM_UNDEF

                canPostNotifications = if (post == NUM_UNDEF) true else it[post]
                canSchedule = if (schedule == NUM_UNDEF) true else it[schedule]

                if (!canPostNotifications)
                    kernel.interop.callDartMethod(NOTIFY_CANT_POST_NOTIFICATIONS_METHOD, null)
            }
        }
    }

    suspend fun handleBroadcast(intent: Intent) = when (intent.action) {
        ACTION_DISMISS -> kernel.reminderManager.cancelReminder(
            intent.getIntExtra(ReminderManager.EXTRA_NOTE_ID, NUM_UNDEF),
            ReminderType.create(intent.getIntExtra(ReminderManager.EXTRA_REMINDER_TYPE, NUM_UNDEF)),
            true
        )
        Intent.ACTION_BOOT_COMPLETED -> onDeviceBooted()
        ACTION_TIMED, ACTION_SCHEDULED -> notifyTimedOrScheduled(intent)
        ACTION_SWAP_OFF -> onSwappedOff(intent)
        else -> throw IllegalArgumentException()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        (kernel.context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply { description = CHANNEL_DESCRIPTION }
            )
    }

    private fun getNotificationManagerCompat() = NotificationManagerCompat.from(kernel.context)

    private fun notify(id: Int, title: String, text: String, type: ReminderType) {
        createNotificationChannel()

        val builder = NotificationCompat.Builder(kernel.context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(type === ReminderType.SCHEDULED)
            .setOngoing(type === ReminderType.ATTACHED)
            .setStyle(NotificationCompat.BigTextStyle())
            .setContentIntent(kernel.reminderManager.createActivityOpenIntent(id, type))
            .setSmallIcon(R.drawable.icon_notes_notification)

        if (type !== ReminderType.TIMED)
            builder.addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                ACTION_DISMISS_TITLE,
                PendingIntent.getBroadcast(
                    kernel.context,
                    ReminderManager.makeId(),
                    kernel.reminderManager.createBroadcastIntent().apply {
                        action = ACTION_DISMISS
                        putExtra(ReminderManager.EXTRA_NOTE_ID, id)
                        putExtra(ReminderManager.EXTRA_REMINDER_TYPE, type.value)
                    },
                    ReminderManager.pendingIntentFlags()
                )
            )
        else
            builder.setDeleteIntent(PendingIntent.getBroadcast(
                kernel.context,
                ReminderManager.makeId(),
                kernel.reminderManager.createBroadcastIntent().apply {
                    action = ACTION_SWAP_OFF
                    putExtra(ReminderManager.EXTRA_NOTE_ID, id)
                    putExtra(ReminderManager.EXTRA_REMINDER_TYPE, type.value)
                },
                ReminderManager.pendingIntentFlags()
            ))

        getNotificationManagerCompat().notify(id, builder.build())
    }

    private fun cancel(id: Int) = NotificationManagerCompat.from(kernel.context).cancel(id)

    suspend fun cancel(id: Int, type: ReminderType) = when (type) {
        ReminderType.ATTACHED -> cancel(id)
        ReminderType.TIMED, ReminderType.SCHEDULED -> {
            cancel(id)
            val alarmManager = (kernel.context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager)!!
            alarmManager.cancel(makeTimedOrScheduledPendingIntent(id, (kernel
                .databaseManager
                .getReminderExtraById(id) as ExtraNotificationReminder).id, type))
        }
        else -> throw IllegalArgumentException()
    }

    suspend fun createOrUpdate(
        note: Note,
        type: ReminderType,
        dateTime: Long?,
        period: Long?
    ): Int? {
        val notifId = ReminderManager.makeId()
        val extra = if (note.id != null) kernel.databaseManager.getReminderExtraById(note.id) else null
        val note2 = note.copy(reminderExtra = extra ?: ExtraNotificationReminder(type, notifId, dateTime, period))

        val id = if (note.id == null)
            kernel.databaseManager.insertNote(note2)
        else {
            kernel.databaseManager.updateNote(note2)
            note.id
        }

        val result = if (note.id == null) id else null

        if (!canPostNotifications) return result

        when (type) {
            ReminderType.ATTACHED -> makeAttached(id, note.title, note.text)
            ReminderType.TIMED -> {
                if (!canSchedule) return result

                assert(period == null)
                if (dateTime != null)
                    makeTimed(id, dateTime, notifId)
                //else TODO: check if updated already dispatched timed note and if not dispatched
            }
            ReminderType.SCHEDULED -> {
                if (!canSchedule) return result

                assert(dateTime != null && period != null || dateTime == null && period == null)
                if (dateTime != null && period != null)
                    makeScheduled(id, dateTime, period, notifId)
            }
            else -> throw IllegalArgumentException()
        }
        return result
    }

    private fun makeAttached(id: Int, title: String, text: String) =
        notify(id, title, text, ReminderType.ATTACHED)

    private fun makeTimedOrScheduledPendingIntent(
        id: Int,
        notifId: Int,
        type: ReminderType
    ) = PendingIntent.getBroadcast(
        kernel.context, notifId,
        kernel.reminderManager.createBroadcastIntent().apply {
            action = if (type === ReminderType.TIMED) ACTION_TIMED else ACTION_SCHEDULED
            putExtra(ReminderManager.EXTRA_NOTE_ID, id)
            putExtra(ReminderManager.EXTRA_REMINDER_TYPE, type.value)
        },
        ReminderManager.pendingIntentFlags()
    )

    private fun getAlarmManager() =
        (kernel.context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager)!!

    private fun makeTimed(id: Int, dateTime: Long, notifId: Int) =
        AlarmManagerCompat.setExactAndAllowWhileIdle(
            getAlarmManager(),
            AlarmManager.RTC_WAKEUP,
            dateTime,
            makeTimedOrScheduledPendingIntent(id, notifId, ReminderType.TIMED)
        )

    private suspend fun notifyTimedOrScheduled(intent: Intent) {
        val action = intent.action
        val type = intent.getIntExtra(ReminderManager.EXTRA_REMINDER_TYPE, NUM_UNDEF)

        assert(action === ACTION_TIMED && type == ReminderType.TIMED.value
                || action === ACTION_SCHEDULED && type == ReminderType.SCHEDULED.value)

        val note = kernel.databaseManager.getNoteById(
            intent.getIntExtra(ReminderManager.EXTRA_NOTE_ID, NUM_UNDEF))!!

        val type2 = note.reminderExtra!!.type
        assert(type2 === ReminderType.TIMED || type2 === ReminderType.SCHEDULED)

        notify(note.id!!, note.title, note.text, note.reminderExtra.type)
    }

    private suspend fun onSwappedOff(intent: Intent) {
        val id = intent.getIntExtra(ReminderManager.EXTRA_NOTE_ID, NUM_UNDEF)
        assert(intent.getIntExtra(ReminderManager.EXTRA_REMINDER_TYPE, NUM_UNDEF)
                == ReminderType.TIMED.value
                && id != NUM_UNDEF
        )
        kernel.databaseManager.setReminderExtra(id, null)
    }

    private fun makeScheduled(id: Int, dateTime: Long, period: Long, notifId: Int) =
        getAlarmManager().setRepeating(
            AlarmManager.RTC_WAKEUP,
            dateTime,
            period,
            makeTimedOrScheduledPendingIntent(id, notifId, ReminderType.SCHEDULED)
        )

    private suspend fun onDeviceBooted() = kernel.databaseManager.getNotesWithReminders().forEach {
        when (it.reminderExtra!!.type) {
            ReminderType.ATTACHED -> makeAttached(it.id!!, it.title, it.text)
            ReminderType.TIMED -> {
                val extra = (it.reminderExtra as ExtraNotificationReminder?)!!

                if (extra.dateTime!! > System.currentTimeMillis() + TIMED_AFTER_BOOT_DELAY)
                    makeTimed(it.id!!, extra.dateTime, extra.id)
                else
                    notify(it.id!!, it.title, it.text, ReminderType.TIMED)
            }
            ReminderType.SCHEDULED -> kernel.databaseManager.updateNote(it.copy(reminderExtra = null))
            else -> Unit
        }
    }

    @Suppress("BlockingMethodInNonBlockingContext")
    suspend fun getTimedDetails(id: Int?): String? {
        val extra = kernel
            .databaseManager
            .getReminderExtraById(id ?: return null)

        if (extra == null || extra !is ExtraNotificationReminder) return null
        val millis = extra.dateTime ?: return null

        val calendar = Calendar.getInstance()
        calendar.timeInMillis = millis

        return StringBuilder().apply {
            append(
                if (millis > System.currentTimeMillis() + 1000) TIMED_PENDING
                else TIMED_DISPATCHED
            )
            append(calendar[Calendar.MONTH] + 1)
            append(DOT)
            append(calendar[Calendar.DAY_OF_MONTH])
            append(DOT)
            append(calendar[Calendar.YEAR])
            append(TIMED_MIDDLE)
            append(calendar[Calendar.HOUR_OF_DAY])
            append(COLON)
            append(calendar[Calendar.MINUTE])
        }.toString()
    }

    suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        GET_TIMED_DETAILS -> {
            result.success(getTimedDetails(call.arguments as Int?))
            true
        }
        else -> false
    }

    fun createReminderExtra(notificationId: Int, type: ReminderType) =
        ExtraNotificationReminder(type, notificationId, null, null) as AbsReminderExtra

    private data class ExtraNotificationReminder(
        override val type: ReminderType,
        override val id: Int,
        val dateTime: Long?,
        val period: Long?
    ) : AbsReminderExtra(id, type)

    companion object {
        private const val CHANNEL_ID = "$PACKAGE.ReminderNotificationChannel"
        private const val CHANNEL_NAME = "Reminder notification channel"
        private const val CHANNEL_DESCRIPTION =
            "Notification channel to which all reminder notifications will be assigned"
        private const val ACTION_DISMISS = "$PACKAGE.ACTION_DISMISS"
        private const val ACTION_DISMISS_TITLE = "Dismiss"
        private const val ACTION_TIMED = "$PACKAGE.ACTION_TIMED"
        private const val ACTION_SWAP_OFF = "$PACKAGE.ACTION_SWAP_OFF"
        private const val ACTION_SCHEDULED = "$PACKAGE.ACTION_SCHEDULED"
        private const val TIMED_AFTER_BOOT_DELAY = 10000
        private const val GET_TIMED_DETAILS = "b.8"
        private const val DOT = '.'
        private const val COLON = ':'
        private const val TIMED_DISPATCHED = "Timed reminder has already notified on "
        private const val TIMED_PENDING = "Timed reminder will notify on "
        private const val TIMED_MIDDLE = " at "
        private const val NOTIFY_CANT_POST_NOTIFICATIONS_METHOD = "a.5"
    }
}
