/**
 * Created by VadNiks on Aug 03 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.db

import android.content.Context
import androidx.annotation.WorkerThread
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration

@WorkerThread
@Database(entities = [Note::class], version = DB_VERSION)
@TypeConverters(NoteConverters::class)
abstract class NoteDatabase : RoomDatabase() {
    protected abstract val dao: NoteDao

    @Suppress("RedundantSuspendModifier")
    suspend fun getDao() = dao

    companion object {
        private var database: NoteDatabase? = null

        @Suppress("RedundantSuspendModifier")
        suspend fun getDatabase(
            context: Context,
            migration: Migration
        ): NoteDatabase =
            database ?: Room
                .databaseBuilder(context, NoteDatabase::class.java, DB_NAME)
                .addMigrations(migration)
                .fallbackToDestructiveMigration()
                .build()
                .also { database = it }
    }
}
