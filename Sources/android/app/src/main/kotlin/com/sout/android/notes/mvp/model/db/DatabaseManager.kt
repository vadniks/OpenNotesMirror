/**
 * Created by VadNiks on Aug 10 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.db

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import androidx.annotation.AnyThread
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import androidx.room.migration.Migration
import androidx.sqlite.db.SimpleSQLiteQuery
import androidx.sqlite.db.SupportSQLiteDatabase
import com.sout.android.notes.NUM_UNDEF
import com.sout.android.notes.NUM_UNDEF_L
import com.sout.android.notes.NUM_ZERO
import com.sout.android.notes.mvp.model.core.AbsSingleton
import com.sout.android.notes.mvp.model.core.Kernel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import java.io.File
import java.io.FileInputStream
import java.lang.System.currentTimeMillis

@WorkerThread
class DatabaseManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private var database = CompletableDeferred<NoteDatabase>()
    private var delegate = CompletableDeferred<NoteDao>()
    private var sortMode: Pair<SortMode, Boolean>? = null

    init { kernel.interop.observeDartMethodHandling(true) { handleDartMethod(it.first, it.second) } }

    suspend fun init() {
        tryToOpenDBOrBackupAndClean()
        database.complete(NoteDatabase.getDatabase(kernel.context, BaseMigration(OLD_GEN), BaseMigration(NEW_310)))
        delegate.complete(database.await().getDao())
    }

    private suspend fun tryToOpenDBOrBackupAndClean() = if (isDBEncrypted()) backupDB() else Unit

    private fun isDBEncrypted(): Boolean {
        val file = kernel.context.getDatabasePath(DB_NAME)
        if (!file.exists()) return false

        val db = try {
            SQLiteDatabase.openDatabase(
                file.absolutePath,
                null,
                SQLiteDatabase.OPEN_READONLY
            ).also { it.version }
        } catch (e: Exception) { null }

        return if (db != null) {
            db.close()
            false
        } else
            true
    }

    @Suppress("RedundantSuspendModifier")
    private suspend fun backupDB() {
        val db = kernel.context.getDatabasePath(DB_NAME)
        if (!db.exists()) return

        db.parentFile!!.listFiles()!!.forEach { if (it != db && it.exists()) it.delete() }
        db.renameTo(File(db.absolutePath + BACKUP_NOTATION))

        kernel.interop.callDartMethod(NOTIFY_BACKED_UP_DB_METHOD, null)
    }

    @Suppress("UNCHECKED_CAST")
    @WorkerThread
    private suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        FETCH_NOTES_METHOD -> {
            val arguments = call.arguments as List<Int>
            result.success(fetchNotes(arguments[0], arguments[1]).map { it.toMap() })
            true
        }
        INSERT_NOTE_METHOD -> {
            result.success(insertNote(Note.fromMap(call.arguments as Map<String, Any?>)))
            true
        }
        UPDATE_NOTE_METHOD -> {
            result.success(updateNote(Note.fromMap(call.arguments as Map<String, Any?>)))
            true
        }
        DELETE_NOTE_METHOD -> {
            result.success(deleteNote(Note.fromMap(call.arguments as Map<String, Any?>)))
            true
        }
        GET_NOTE_BY_ID_METHOD -> {
            result.success(getNoteById(call.arguments as Int)?.toMap())
            true
        }
        SEARCH_BY_TITLE_METHOD -> {
            result.success(searchByTitle(call.arguments as String).map(fun(it) = it.toMap()))
            true
        }
        SET_SORT_MODE_METHOD -> {
            with(kernel.databaseManager) {
                val mode = call.arguments as List<Any>
                setSortMode(createSortMode(mode[0] as Int)!!, mode[1] as Boolean)
            }
            result.success(null)
            true
        }
        GET_SORT_MODE_METHOD -> {
            result.success(sortMode?.run { listOf(first.mode, second) } ?: listOf(0, false))
            true
        }
        else -> false
    }

    private val orderBy get() = "order by ${sortMode!!.first.column} ${if (sortMode!!.second) "desc" else "asc"}"

    private suspend fun fetchNotes(from: Int, amount: Int): List<Note> {
        if (sortMode == null) { sortMode = getSortMode() ?: (SortMode.ID to false) }

        return delegate.await().getNotes(SimpleSQLiteQuery(
            "select * from $DB_NAME $orderBy limit ? offset ?",
            arrayOf(amount, from)
        ))
    }

    suspend fun getNoteById(id: Int) = delegate.await().getNoteById(id)

    suspend fun isReminderSet(id: Int): Boolean = delegate.await().getReminderExtraById(id) != null

    @Deprecated("unused")
    suspend fun noteExists(id: Int) = delegate.await().exists(id)

    suspend fun setReminderExtra(id: Int, extra: AbsReminderExtra?) {
        assert(delegate.await().setReminderExtra(id, extra) == 1)
        notifyDBModified()
    }

    suspend fun getReminderExtraById(id: Int) = delegate.await().getReminderExtraById(id)

    suspend fun getNotesWithReminders() = delegate.await().getNotesWithReminders()

    private suspend fun searchByTitle(title: String) = delegate.await().getNotes(SimpleSQLiteQuery(
        "select * from $DB_NAME where instr(lower($TITLE), lower(?)) > 0 collate nocase $orderBy",
        arrayOf(title)
    ))

    suspend fun insertNote(note: Note): Int {
        var id = 0
        val curMillis = currentTimeMillis()

        assert(note.id == null && delegate.await()
            .insertNote(note.copy(addMillis = curMillis, editMillis = curMillis))
            .also { id = it.toInt() } != NUM_UNDEF_L)

        notifyDBModified()
        return id
    }

    suspend fun updateNote(note: Note): Int {
        var rows = 0
        val delegate2 = delegate.await()

        assert(note.id != null && delegate2.updateNote(note.copy(
            addMillis = delegate2.getAddMillis(note.id),
            editMillis = currentTimeMillis())
        ).also { rows = it } != NUM_ZERO)

        notifyDBModified()
        return rows
    }

    private suspend fun deleteNote(note: Note): Int {
        var rows = 0
        assert(note.id != null && delegate.await().deleteNote(note).also { rows = it } != NUM_ZERO)
        notifyDBModified()
        return rows
    }

    suspend fun deleteMultiple(ids: List<Int>) = ids.forEach {
        assert(delegate.await().deleteById(it) == 1)
        notifyDBModified()
    }

    private fun notifyDBModified() = kernel.interop.callDartMethod(ON_DB_MODIFIED_METHOD, null)

    suspend fun terminate() {
        if (!database.isCompleted || !database.await().isOpen) return
        database.await().close()

        database = CompletableDeferred()
        delegate = CompletableDeferred()
    }

    @SuppressLint("ApplySharedPref")
    @AnyThread
    private fun setSortMode(mode: SortMode, order: Boolean) {
        sortMode = mode to order
        kernel.sharedPrefs.edit().putString(SORT_MODE_PREF, "${mode.mode}$order").commit()
    }

    @AnyThread
    private fun createSortMode(mode: Int) = SortMode.values().find { it.mode == mode }

    @AnyThread
    private fun getSortMode() = kernel.sharedPrefs.getString(SORT_MODE_PREF, "0false")?.run {
        createSortMode(elementAt(0).digitToInt())!! to substring(1).toBoolean()
    }

    @WorkerThread
    fun copyDatabaseContentToExternal(
        uri: Uri,
        contentResolver: ContentResolver,
        @WorkerThread callback: (Boolean) -> Unit
    ) { try {
        val bytesWritten = contentResolver.openOutputStream(uri, "w")?.use { out ->
            FileInputStream(kernel.context.getDatabasePath(DB_NAME)).use { it.copyTo(out) }
        }
        callback(bytesWritten != 0L)
    } catch (_: Exception) { callback(false) } }

    @WorkerThread
    suspend fun copyDatabaseContentFromExternal(
        uri: Uri,
        contentResolver: ContentResolver,
        @WorkerThread callback: (Boolean) -> Unit
    ) {
        val descriptor = contentResolver.openInputStream(uri)?.use { input ->
            val name = currentTimeMillis().toString()
            kernel.context.openFileOutput(name, Context.MODE_PRIVATE).use { input.copyTo(it) }

            val file = kernel.context.getFileStreamPath(name)
            if (!file.exists()) {
                callback(false)
                return
            }

            @Suppress("NAME_SHADOWING")
            val callback = { successful: Boolean ->
                file.delete()
                callback(successful)
            }

            try { SQLiteDatabase.openDatabase(file.absolutePath, null, SQLiteDatabase.OPEN_READONLY).use {
                if (it.attachedDbs.find { db -> db.first == DB_NAME } != null) {
                    callback(false)
                    return
                }

                if (!it.rawQuery("pragma table_info('$DB_NAME')", emptyArray()).let { cursor ->
                    val columnIndex = cursor.getColumnIndex("name")
                    var isTitleFound = false
                    var isTextFound = false

                    if (!cursor.moveToFirst()) return@let false
                    do {
                        val s = cursor.getString(columnIndex)
                        isTitleFound = isTitleFound || s == TITLE
                        isTextFound = isTextFound || s == TEXT
                    } while ((!isTitleFound || !isTextFound) && cursor.moveToNext())
                    cursor.close()

                    isTitleFound && isTextFound
                }) {
                    callback(false)
                    return
                }

                 it.query(DB_NAME, arrayOf(TITLE, TEXT), null, emptyArray(), null, null, null).use { cursor ->
                     val title = cursor.getColumnIndex(TITLE) // querying only most important fields for supporting all db versions
                     val text = cursor.getColumnIndex(TEXT) // basically supports any sqlite3 database with text columns 'title' & 'text'

                     if (title == NUM_UNDEF || text == NUM_UNDEF || !cursor.moveToFirst()) {
                         callback(false)
                         return
                     }

                     val dlg = delegate.await()
                     do dlg.insertNote(Note( // using direct insert to avoid notifying (by the proxy) front-end about database modifications, it's gonna take measures (update main list) on successful callback call processing
                         null,
                         cursor.getString(title),
                         cursor.getString(text),
                         currentTimeMillis(),
                         currentTimeMillis(),
                         null,
                         null,
                         null
                     )) while (cursor.moveToNext())
                 }
            } } catch (_: Exception) { callback(false) }
            file.delete()
        }
        callback(descriptor != null)
    }

    enum class SortMode(val mode: Int, val column: String) {
        ID(0, com.sout.android.notes.mvp.model.db.ID),
        TITLE(1, com.sout.android.notes.mvp.model.db.TITLE)
    }

    private inner class BaseMigration(private val fromVersion: Int)
        : Migration(fromVersion, ACTUAL_DB_VERSION)
    { override fun migrate(database: SupportSQLiteDatabase) {
        database.query(
            """select $ID, $TITLE, $TEXT 
                ${if (fromVersion == NEW_310) ", $REMINDER_EXTRA, $COLOR" else ""} 
                from $DB_NAME
            """.trimIndent()
        ).use { cursor ->
            val count = cursor.count
            val notes = ArrayList<Note>(count)
            val converters = NoteConverters()

            val id = cursor.getColumnIndex(ID)
            val title = cursor.getColumnIndex(TITLE)
            val text = cursor.getColumnIndex(TEXT)
            val remExtra = cursor.getColumnIndex(REMINDER_EXTRA)
            val color = cursor.getColumnIndex(COLOR)

            if (!cursor.moveToFirst() && count > 0) throw IllegalStateException()
            assert(id != NUM_UNDEF && title != NUM_UNDEF && text != NUM_UNDEF)
            if (fromVersion == NEW_310) assert(remExtra != NUM_UNDEF && color != NUM_UNDEF)

            if (count > 0) do notes.add(Note(
                cursor.getInt(id),
                cursor.getString(title),
                cursor.getString(text),
                currentTimeMillis(),
                currentTimeMillis(),
                if (fromVersion == OLD_GEN) kernel.reminderManager.createReminderExtra(cursor)
                else converters.bytesToAbsReminderExtra(cursor.getBlob(remExtra)),
                if (fromVersion == OLD_GEN) null else NoteColor.values().find { it.name == cursor.getString(color) },
                null
            )) while (cursor.moveToNext())

            database.execSQL("drop table $DB_NAME")
            database.execSQL("""create table `$DB_NAME` (
                `$ID` integer primary key autoincrement,
                `$TITLE` text not null,
                `$TEXT` text not null,
                `$ADD_MILLIS` integer not null,
                `$EDIT_MILLIS` integer not null,
                `$REMINDER_EXTRA` blob,
                `$COLOR` text,
                `$SPANS` text
           )""".trimIndent())

            notes.forEach { database.insert(DB_NAME, SQLiteDatabase.CONFLICT_FAIL, ContentValues().apply {
                put(ID, it.id)
                put(TITLE, it.title)
                put(TEXT, it.text)
                put(ADD_MILLIS, it.addMillis)
                put(EDIT_MILLIS, it.editMillis)
                put(REMINDER_EXTRA, converters.absReminderExtraToBytes(it.reminderExtra))
                put(COLOR, it.color?.name)
                put(SPANS, it.spans)
            }) }
        }
    } }

    companion object {
        private const val FETCH_NOTES_METHOD = "fetchNotes"
        private const val INSERT_NOTE_METHOD = "insertNote"
        private const val UPDATE_NOTE_METHOD = "updateNote"
        private const val DELETE_NOTE_METHOD = "deleteNote"
        private const val ON_DB_MODIFIED_METHOD = "onDbModified"
        private const val GET_NOTE_BY_ID_METHOD = "getNoteById"
        private const val SEARCH_BY_TITLE_METHOD = "searchByTitle"
        private const val NOTIFY_BACKED_UP_DB_METHOD = "notifyBackedUpDb"
        private const val SET_SORT_MODE_METHOD = "setSortMode"
        private const val GET_SORT_MODE_METHOD = "getSortMode"
        private const val BACKUP_NOTATION = ".backup"
        private const val SORT_MODE_PREF = "sortMode"
        private const val OLD_GEN = 5
        private const val NEW_310 = 6
    }
}
