/**
 * Created by VadNiks on Aug 02 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.presenter

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.AnyThread
import androidx.annotation.UiThread
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.view.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@UiThread
class ActivityPresenter(private val activityGetter: () -> Activity) : Kernel.Injectable {
    override lateinit var kernel: Kernel
    var isActivityRunning = true; private set
    private val activity get() = activityGetter()
    private var onPermissionRequestResponded: ((BooleanArray) -> Unit)? = null

    private val dartMethodHandler: suspend (Pair<MethodCall, MethodChannel.Result>) -> Boolean = {
            it -> handleDartMethod(it.first, it.second)
    }

    init {
        inject(activity)
        kernel.activityPresenter.complete(this)
    }

    @Suppress("UNCHECKED_CAST")
    private suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        SEND_METHOD -> {
            assert(kernel.activityPresenter.isCompleted)
            val arguments = call.arguments as List<String>
            send(arguments[0], arguments[1])
            result.success(null)
            true
        }
        else -> false
    }
    
    fun configureFlutterEngine(flutterEngine: FlutterEngine, intent: Intent) {
        kernel.interop.configureFlutterEngine(flutterEngine)
        onNewIntent(intent)
    }

    fun onNewIntent(intent: Intent) {
        if (intent.action !== Intent.ACTION_SEND)
            kernel.reminderManager.onActivityNewIntent(intent)
        else
            handleTextSend(intent)
    }

    private fun handleTextSend(intent: Intent) {
        val bool = intent.type != SEND_MIME

        val title = if (bool) ERROR else intent.getStringExtra(Intent.EXTRA_TITLE)
        val text = if (bool) ERROR else intent.getStringExtra(Intent.EXTRA_TEXT)

        kernel.interop.callDartMethod(HANDLE_SEND_METHOD, listOf(title ?: EMPTY, text ?: EMPTY))
    }

    fun onStart() {
        kernel.interop.observeDartMethodHandling(true, dartMethodHandler)
        kernel.onActivityStart()
    }

    fun onStop() {
        kernel.interop.observeDartMethodHandling(false, dartMethodHandler)
        kernel.onActivityStop()
    }

    fun onDestroy() {
        isActivityRunning = false
        kernel.onActivityDestroy()
    }

    @AnyThread
    fun setResult(result: Int) {
        activity.setResult(result)
    }

    @AnyThread
    fun finish() = activity.finishAndRemoveTask()

    private fun send(title: String, text: String) = activity.startActivity(Intent.createChooser(Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TITLE, title)
        putExtra(Intent.EXTRA_TEXT, text)
        type = SEND_MIME
    }, null).apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            putExtra(
                Intent.EXTRA_EXCLUDE_COMPONENTS,
                arrayListOf(ComponentName(kernel.context, Activity::class.java))
            )
    })

    fun requestPermission(permissions: Array<String>, callback: (BooleanArray) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M)
            callback(BooleanArray(permissions.size) { true })
        else {
            onPermissionRequestResponded = callback
            activity.requestPermissions(permissions, REQUEST_PERMISSIONS_CODE)
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        onPermissionRequestResponded!!.invoke(
            grantResults.map { it == PackageManager.PERMISSION_GRANTED }.toBooleanArray())
        onPermissionRequestResponded = null
    }

    companion object {
        private const val SEND_METHOD = "b.11"
        private const val SEND_MIME = "text/plain"
        private const val HANDLE_SEND_METHOD = "a.3"
        private const val ERROR = "<ERROR>"
        private const val EMPTY = ""
        private const val REQUEST_PERMISSIONS_CODE = 509154

        fun init(activity: Activity) = ActivityPresenter { activity }
    }
}
