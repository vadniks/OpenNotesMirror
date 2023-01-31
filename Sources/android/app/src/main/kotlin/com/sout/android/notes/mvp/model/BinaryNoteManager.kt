/**
 * Created by VadNiks on Jan 29 2022
 * Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model

import android.content.ContentResolver
import android.net.Uri
import androidx.annotation.UiThread
import androidx.annotation.WorkerThread
import com.sout.android.notes.NUM_UNDEF
import com.sout.android.notes.mvp.model.core.AbsSingleton
import com.sout.android.notes.mvp.model.core.Kernel
import com.sout.android.notes.mvp.model.db.Note
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

@WorkerThread
class BinaryNoteManager @UiThread constructor(private val kernel: Kernel) : AbsSingleton() {

    init { kernel.interop.observeDartMethodHandling(true) { handleDartMethod(it.first, it.second) } }

    @Suppress("UNCHECKED_CAST")
    private suspend fun handleDartMethod(
        call: MethodCall,
        result: MethodChannel.Result
    ): Boolean = when (call.method) {
        SAVE_BINARY_NOTE_METHOD -> {
            val args = call.arguments as List<Any>
            result.success(saveOrUpdate(Note.fromMap(args[0] as Map<String, Any?>), args[1] as ByteArray))
            true
        }
        READ_BINARY_NOTE_METHOD -> {
            result.success(read(Note.fromMap(call.arguments as Map<String, Any?>)))
            true
        }
        DELETE_BINARY_NOTE_METHOD -> {
            result.success(delete(Note.fromMap(call.arguments as Map<String, Any?>)))
            true
        }
        else -> false
    }

    private fun getOrCreateTypedDir() = File(kernel.context.filesDir, BINARY_NOTES_DIR)
        .run { if (!exists()) if (!mkdir()) null else this else this }

    private fun getBinaryFile(id: Int) = getOrCreateTypedDir()?.let { File(it, id.toString()) }

    private suspend fun saveOrUpdate(note: Note, content: ByteArray): Int? {
        val editing = note.id != null

        val newId = if (!editing)
            kernel.databaseManager.insertNote(note)
        else
            kernel.databaseManager.updateNote(note).let { if (it != 1) NUM_UNDEF else note.id!! }

        if (newId <= 0) return null

        getBinaryFile(newId)
            ?.takeIf { if (editing) it.exists() else it.createNewFile() }
            ?.writeBytes(content) ?: return null
        return newId
    }

    private fun read(note: Note): ByteArray? = getBinaryFile(note.id!!)?.takeIf { it.exists() }?.readBytes()

    suspend fun delete(note: Note): Boolean = getBinaryFile(note.id!!)
        ?.takeIf { it.exists() }
        ?.delete()
        .let { kernel.databaseManager.deleteById(note.id) != 0 && it == true }

    fun export(id: Int, uri: Uri, contentResolver: ContentResolver)
    = contentResolver.openOutputStream(uri, "w").use { out ->
        if (out != null)
            getBinaryFile(id)?.inputStream()?.use { it.copyTo(out) }
    }

    companion object {
        private const val BINARY_NOTES_DIR = "binaryNotes"
        private const val SAVE_BINARY_NOTE_METHOD = "saveBinaryNote"
        private const val READ_BINARY_NOTE_METHOD = "readBinaryNote"
        private const val DELETE_BINARY_NOTE_METHOD = "deleteBinaryNote"
    }
}
