/**
 * Created by VadNiks on Aug 02 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
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
import android.os.Bundle
import androidx.annotation.AnyThread
import androidx.annotation.UiThread
import com.sout.android.notes.mvp.model.core.Interop
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.model.db.Note
import com.sout.android.notes.mvp.model.db.toMap
import com.sout.android.notes.mvp.view.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Kernel finishes old activity and drops old instance of this class when Android creates new activity,
// allowing only the single instance of this class to be presented in the Kernel and only one instance
// of the activity to be running. This can happen if user queries for widget configuring while the
// app is launched & still alive
@UiThread
class ActivityPresenter(private val activityGetter: () -> Activity) : Kernel.Injectable {
    override lateinit var kernel: Kernel
    var isActivityRunning = true; private set
    private val activity get() = activityGetter()
    private var onPermissionRequestResponded: ((BooleanArray) -> Unit)? = null
    private var currentNote: Note? = null

    private val dartMethodHandler: suspend (Pair<MethodCall, MethodChannel.Result>) -> Boolean
    = { it -> handleDartMethod(it.first, it.second) }

    init {
        inject(activity)
        kernel.onActivityPresenterInit(this)
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
        SAVE_STATE_METHOD -> {
            currentNote = Note.fromMap(call.arguments as Map<String, Any?>)
            result.success(null)
            true
        }
        RESET_STATE_METHOD -> {
            currentNote = null
            result.success(null)
            true
        }
        DELETE_SELECTED_METHOD -> {
            kernel.launchInBackground { kernel.databaseManager.deleteMultiple(call.arguments as List<Int>) }
            result.success(null)
            true
        }
        EXPORT_DATABASE_METHOD -> {
            queryDatabaseExport()
            result.success(null)
            true
        }
        IMPORT_DATABASE_METHOD -> {
            queryDatabaseImport()
            result.success(null)
            true
        }
        CHANGE_THEME_METHOD -> {
            changeTheme()
            result.success(null)
            true
        }
        IS_DARK_THEME_METHOD -> {
            result.success(kernel.sharedPrefs.getBoolean(PREF_IS_DARK, false))
            true
        }
        else -> false
    }

    fun configureFlutterEngine(flutterEngine: FlutterEngine, intent: Intent) {
        kernel.interop.configureFlutterEngine(flutterEngine)
        onNewIntent(intent)
    }

    private fun changeTheme() = if (Build.VERSION.SDK_INT > Build.VERSION_CODES.Q) null
    else kernel.sharedPrefs.getBoolean(PREF_IS_DARK, false).let {
        kernel.sharedPrefs.edit().putBoolean(PREF_IS_DARK, !it).apply() // can be asynchronous
        kernel.interop.callDartMethod(ON_THEME_CHANGED_METHOD, !it)
    }

    fun onSaveInstanceState(outState: Bundle) = outState.putSerializable(CURRENT_NOTE, currentNote)

    @Suppress("DEPRECATION")
    fun onRestoreInstanceState(savedInstanceState: Bundle) {
        val note = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            savedInstanceState.getSerializable(CURRENT_NOTE, Note::class.java)
        else
            savedInstanceState.getSerializable(CURRENT_NOTE)) as Note?

        if (note != null) kernel.interop.callDartMethod(Interop.LAUNCH_EDIT_PAGE_METHOD, note.toMap())
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
    fun setResult(result: Int) = activity.setResult(result)

    @AnyThread
    fun finish() = activity.finishAndRemoveTask()

    // TODO: add encryption
    private fun queryDatabaseExport() = activity.startActivityForResult(
        Intent.createChooser(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = DATABASE_MIME
            putExtra(Intent.EXTRA_TITLE, DATABASE_NAME)
        }, CREATE_FILE_FOR_EXPORTING),
        REQUEST_DATABASE_CREATION_CODE
    )

    private fun queryDatabaseImport() = activity.startActivityForResult(
        Intent.createChooser(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = DATABASE_MIME
        }, SELECT_FILE_FOR_IMPORTING),
        REQUEST_DATABASE_SELECTION_CODE
    )

    private fun send(title: String, text: String) = activity.startActivity(Intent.createChooser(Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TITLE, title)
        putExtra(Intent.EXTRA_TEXT, text)
        type = SEND_MIME
    }, null).apply {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) putExtra(
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

    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        if (requestCode != REQUEST_PERMISSIONS_CODE || permissions.size != grantResults.size) return
        onPermissionRequestResponded!!.invoke(grantResults.map { it == PackageManager.PERMISSION_GRANTED }.toBooleanArray())
        onPermissionRequestResponded = null
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        tryExportDatabase(requestCode, resultCode, data)
        tryImportFromDatabase(requestCode, resultCode, data)
    }

    private fun checkActivityResult(resultCode: Int, data: Intent?) =
        resultCode == android.app.Activity.RESULT_OK
        && data != null
        && data.data != null

    private fun tryExportDatabase(requestCode: Int, resultCode: Int, data: Intent?) { // TODO: perform export/import in a background service
        if (requestCode != REQUEST_DATABASE_CREATION_CODE) return
        if (!checkActivityResult(resultCode, data)) {
            kernel.interop.callDartMethod(NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD, false)
            return
        }

        kernel.launchInBackground {
            kernel.databaseManager.copyDatabaseContentToExternal(data!!.data!!, activity.contentResolver)
            { kernel.interop.callDartMethod(NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD, it) }
        }
    }

    private fun tryImportFromDatabase(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_DATABASE_SELECTION_CODE) return
        if (
            !checkActivityResult(resultCode, data)
            || data?.getStringExtra(Intent.EXTRA_TITLE)?.endsWith(DATABASE_NAME.substringAfter('.')) == true
        ) {
            kernel.interop.callDartMethod(NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD, false)
            return
        }

        kernel.launchInBackground {
            kernel.databaseManager.copyDatabaseContentFromExternal(data!!.data!!, activity.contentResolver)
            { kernel.interop.callDartMethod(NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD, it) }
        }
    }

    companion object {
        private const val SEND_METHOD = "send"
        private const val HANDLE_SEND_METHOD = "handleSend"
        private const val SAVE_STATE_METHOD = "saveState"
        private const val RESET_STATE_METHOD = "resetState"
        private const val DELETE_SELECTED_METHOD = "deleteSelected"
        private const val EXPORT_DATABASE_METHOD = "exportDatabase"
        private const val IMPORT_DATABASE_METHOD = "importDatabase"
        private const val NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD = "notifyDatabaseExportedOrImported"
        private const val CHANGE_THEME_METHOD = "changeTheme"
        private const val ON_THEME_CHANGED_METHOD = "onThemeChange"
        private const val IS_DARK_THEME_METHOD = "isDarkTheme"
        private const val DATABASE_MIME = "application/octet-stream" // "application/vnd.sqlite3" // some file pickers wrongly identify vendor mime type and set mime to plain binary
        private const val DATABASE_NAME = "notes.sqlite3"
        private const val CREATE_FILE_FOR_EXPORTING = "Create file in which the database content will be written"
        private const val SELECT_FILE_FOR_IMPORTING = "Select database file"
        private const val CURRENT_NOTE = "currentNote"
        private const val SEND_MIME = "text/plain"
        private const val ERROR = "<ERROR>"
        private const val EMPTY = ""
        private const val REQUEST_PERMISSIONS_CODE = 0
        private const val REQUEST_DATABASE_CREATION_CODE = 1
        private const val REQUEST_DATABASE_SELECTION_CODE = 2
        private const val PREF_IS_DARK = "isDark"

        fun init(activity: Activity) = ActivityPresenter { activity }
    }
}
