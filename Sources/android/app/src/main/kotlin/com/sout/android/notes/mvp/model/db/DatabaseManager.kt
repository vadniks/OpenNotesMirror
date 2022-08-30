/**
 * Created by VadNiks on Aug 10 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.db

import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
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

@WorkerThread
class DatabaseManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {
    private var database = CompletableDeferred<NoteDatabase>()
    private var delegate = CompletableDeferred<NoteDao>()

    init {
        kernel.interop.observeDartMethodHandling(true) { handleDartMethod(it.first, it.second) }
    }

    suspend fun init() {
        tryToOpenDBOrBackupAndClean()
        database.complete(NoteDatabase.getDatabase(kernel.context, Migration()))
        delegate.complete(database.await().getDao())
    }

    private suspend fun tryToOpenDBOrBackupAndClean() = if (isDBEncrypted()) backupDB() else Unit

    @Suppress("RedundantSuspendModifier")
    private suspend fun isDBEncrypted(): Boolean {
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
        else -> false
    }

    suspend fun fetchNotes(from: Int, amount: Int): List<Note> = delegate.await().getNotesLimited(from, amount)

    suspend fun getNoteById(id: Int) = delegate.await().getNoteById(id)

    suspend fun isReminderSet(id: Int): Boolean = delegate.await().getReminderExtraById(id) != null

    suspend fun noteExists(id: Int) = delegate.await().exists(id)

    suspend fun setReminderExtra(id: Int, extra: AbsReminderExtra?) {
        assert(delegate.await().setReminderExtra(id, extra) == 1)
        notifyDBModified(null, DBModificationMode.UPDATE)
    }

    suspend fun getReminderExtraById(id: Int) = delegate.await().getReminderExtraById(id)

    suspend fun getNotesWithReminders() = delegate.await().getNotesWithReminders()

    suspend fun searchByTitle(title: String) = delegate.await().searchByTitle(title)

    suspend fun insertNote(note: Note): Int {
        var id = 0
        assert(note.id == null && delegate.await().insertNote(note).also { id = it.toInt() } != NUM_UNDEF_L)
        notifyDBModified(Note(id, note.title, note.text), DBModificationMode.INSERT)
        return id
    }

    suspend fun updateNote(note: Note): Int {
        var rows = 0
        assert(note.id != null && delegate.await().updateNote(note).also { rows = it } != NUM_ZERO)
        notifyDBModified(note, DBModificationMode.UPDATE)
        return rows
    }

    suspend fun deleteNote(note: Note): Int {
        var rows = 0
        assert(note.id != null && delegate.await().deleteNote(note).also { rows = it } != NUM_ZERO)
        notifyDBModified(note, DBModificationMode.DELETE)
        return rows
    }

    private fun notifyDBModified(note: Note?, mode: DBModificationMode) =
        kernel.interop.callDartMethod(ON_DB_MODIFIED_METHOD, listOf(note?.toMap(), mode.value))

    suspend fun terminate() {
        if (!database.isCompleted || database.await().isOpen) return
        database.await().close()

        database = CompletableDeferred()
        delegate = CompletableDeferred()
    }

    enum class DBModificationMode(val value: Int)
    { INSERT(0), UPDATE(1), DELETE(2) }

    private inner class Migration : androidx.room.migration.Migration(OLD_DB_VERSION, DB_VERSION) {

        override fun migrate(database: SupportSQLiteDatabase) {
            val cursor = database.query("select $ID, $TITLE, $TEXT from $DB_NAME")
            val notes = ArrayList<Note>(cursor.count)

            val id = cursor.getColumnIndex(ID)
            val title = cursor.getColumnIndex(TITLE)
            val text = cursor.getColumnIndex(TEXT)

            if (!cursor.moveToFirst()) return
            assert(id != NUM_UNDEF || title != NUM_UNDEF || text != NUM_UNDEF)

            do notes.add(Note(
                cursor.getInt(id),
                cursor.getString(title),
                cursor.getString(text),
                kernel.reminderManager.createReminderExtra(cursor),
                null
            )) while (cursor.moveToNext())
            cursor.close()

            database.execSQL("drop table $DB_NAME")
            database.execSQL("""create table `$DB_NAME` (
                `$ID` integer primary key autoincrement,
                `$TITLE` text not null,
                `$TEXT` TEXT not null,
                `$REMINDER_EXTRA` blob,
                `$COLOR` text
           )""".trimIndent())

            notes.forEach { database.insert(DB_NAME, SQLiteDatabase.CONFLICT_FAIL, ContentValues().apply {
                put(ID, it.id)
                put(TITLE, it.title)
                put(TEXT, it.text)
                put(REMINDER_EXTRA, NoteConverters().absReminderExtraToBytes(it.reminderExtra))
                put(COLOR, null as String?)
            }) }
        }
    }

    companion object {
        private const val FETCH_NOTES_METHOD = "b.0";
        private const val INSERT_NOTE_METHOD = "b.1"
        private const val UPDATE_NOTE_METHOD = "b.2"
        private const val DELETE_NOTE_METHOD = "b.3"
        private const val ON_DB_MODIFIED_METHOD = "a.0"
        private const val GET_NOTE_BY_ID_METHOD = "b.4"
        private const val SEARCH_BY_TITLE_METHOD = "b.10"
        private const val NOTIFY_BACKED_UP_DB_METHOD = "a.4"
        private const val BACKUP_NOTATION = ".backup"
    }
}
