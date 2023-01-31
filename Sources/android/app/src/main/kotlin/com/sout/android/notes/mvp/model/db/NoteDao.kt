/**
 * Created by VadNiks on Aug 03 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.db

import androidx.annotation.WorkerThread
import androidx.room.*
import androidx.sqlite.db.SupportSQLiteQuery
import com.sout.android.notes.mvp.model.BinaryNoteManager
import com.sout.android.notes.mvp.model.db.*

@WorkerThread
@Dao
interface NoteDao { // Thing that I hate the most about Kotlin is that it doesn't have package-private modifier (internal isn't the equivalent) for some some reason (I don't agree with language developers' position from their explanation)

    @RawQuery
    suspend fun getNotes(query: SupportSQLiteQuery): List<Note>

    @Query("select * from $DB_NAME where $ID = :$ID limit 1")
    suspend fun getNoteById(id: Int): Note?

    @Query("update $DB_NAME set $REMINDER_EXTRA = :extra where $ID = :$ID")
    suspend fun setReminderExtra(id: Int, extra: AbsReminderExtra?): Int

    @Query("select exists(select 1 from $DB_NAME where $ID = :$ID)")
    suspend fun exists(id: Int): Int

    @Query("select $REMINDER_EXTRA from $DB_NAME where $ID = :$ID")
    suspend fun getReminderExtraById(id: Int): AbsReminderExtra?

    @Query("select $CANVAS from $DB_NAME where $ID = :$ID")
    suspend fun getCanvasFlagById(id: Int): Boolean

    @Query("select * from $DB_NAME where $REMINDER_EXTRA is not null order by $ID asc")
    suspend fun getNotesWithReminders(): List<Note>

    @Query("delete from $DB_NAME where $ID = :$ID")
    suspend fun deleteById(id: Int): Int

    @Insert
    suspend fun insertNote(note: Note): Long

    @Update
    suspend fun updateNote(note: Note): Int

    @Delete
    suspend fun deleteNote(note: Note): Int
}
