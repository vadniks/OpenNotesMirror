/**
 * Created by VadNiks on Aug 01 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.core

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.Toast
import androidx.annotation.Keep
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import com.sout.android.notes.COPYRIGHT
import com.sout.android.notes.PACKAGE
import com.sout.android.notes.mvp.presenter.ActivityPresenter
import com.sout.android.notes.mvp.model.db.DatabaseManager
import com.sout.android.notes.mvp.model.reminders.ReminderManager
import com.sout.android.notes.mvp.view.Activity
import kotlinx.coroutines.*
import kotlin.coroutines.coroutineContext
import kotlin.system.exitProcess

@Kernel.Comment(COPYRIGHT)
class Kernel @UiThread constructor(private val contextGetter: () -> Context) : AbsSingleton() {
    private var mainScope = MainScope()
    val context: Context get() = contextGetter()
    val interop = Interop(this)
    val databaseManager = DatabaseManager(this)
    var activityPresenter = CompletableDeferred<ActivityPresenter>(); private set
    val reminderManager = ReminderManager(this)
    private var isFinishingPreviousActivity = false

    @UiThread
    fun onActivityPresenterInit(presenter: ActivityPresenter) {
        if (activityPresenter.isCompleted) runBlocking {
            isFinishingPreviousActivity = true
            activityPresenter.await().finish() // Cuz ActivityPresenter is effectively-singleton, meaning the only one valid instance of it must be referenced to from kernel
            activityPresenter = CompletableDeferred()
        }
        activityPresenter.complete(presenter)
    }

    fun createActivityOpenIntent() = Intent(context, Activity::class.java).apply {
        flags = Intent.FLAG_FROM_BACKGROUND or Intent.FLAG_ACTIVITY_SINGLE_TOP
    }

    @UiThread
    fun showToast(message: String) = Toast.makeText(context, message, Toast.LENGTH_SHORT).show()

    private fun init() {
        if (!mainScope.isActive) mainScope = MainScope()
        launchInBackground { databaseManager.init() }
    }

    @UiThread
    fun onActivityStart() = init()

    @UiThread
    fun onActivityStop() = launchInBackground { databaseManager.terminate() } // Cuz the system doesn't call onDestroy in activity, and the database needs to be closed, we have two options: close it after any db ro/rw operation or close it here

    fun onStartReceivingBroadcast() = init()

    @WorkerThread
    suspend fun onStopReceivingBroadcast(pendingResult: BroadcastReceiver.PendingResult) {
        if (activityPresenter.isCompleted) {
            pendingResult.finish()
            return
        }

        databaseManager.terminate()
        pendingResult.finish()
        mainScope.cancel()
        exitProcess(0)
    }

    @UiThread
    fun onActivityDestroy() {
        if (isFinishingPreviousActivity) {
            isFinishingPreviousActivity = false
            return
        }
        mainScope.cancel()
        exitProcess(0)
    }

    @Deprecated("unused")
    @WorkerThread
    suspend fun assertNotMainCoroutine() = assert(mainScope != coroutineContext)

    fun launchInBackground(action: suspend CoroutineScope.() -> Unit) =
        mainScope.launch(Dispatchers.IO) { action(this) }

    fun launchInMain(action: suspend CoroutineScope.() -> Unit) = mainScope.launch { action(this) }

    val sharedPrefs: SharedPreferences get() = context.getSharedPreferences(SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE)

    @JvmDefaultWithoutCompatibility
    interface Injectable { // Kernel is injected into implementations of this interface
        var kernel: Kernel

        fun inject(context: Context) = (context.applicationContext as Injector).injectKernel(this)
    }

    @JvmDefaultWithoutCompatibility
    interface Injector {
        val kernel: Kernel

        fun injectKernel(injectable: Injectable) = injectable::kernel.set(kernel)
    }

    @Keep
    @Retention(AnnotationRetention.BINARY)
    @Target(AnnotationTarget.CLASS)
    annotation class Comment(val it: String)

    companion object {
        private const val SHARED_PREFS_FILE_NAME = "$PACKAGE.SharedPrefs"
    }
}
