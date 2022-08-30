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

import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import com.sout.android.notes.PACKAGE
import com.sout.android.notes.mvp.model.Observable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Interop @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private lateinit var channel: MethodChannel
    private val handlers = Observable<Pair<MethodCall, MethodChannel.Result>, Boolean>()
    private val isAvailable get() = this::channel.isInitialized

    @UiThread
    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            kernel.launchInBackground { handleDartMethod(call, result) }
        }
    }

    fun observeDartMethodHandling(
        add: Boolean,
        observer: suspend (Pair<MethodCall, MethodChannel.Result>) -> Boolean
    ) = handlers.observe(observer, add)

    @Suppress("RedundantSuspendModifier")
    @WorkerThread
    private suspend fun handleDartMethod(call: MethodCall, result: MethodChannel.Result) {
        var res = false
        handlers.notify(call to result) { res = res or it }
        if (!res) result.notImplemented()
    }

    fun callDartMethod(method: String, argument: Any?) = kernel.launchInMain {
        if (isAvailable) channel.invokeMethod(method, argument)
    }

    companion object {
        private const val CHANNEL_NAME = "$PACKAGE/channel"
    }
}
