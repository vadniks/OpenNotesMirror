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

import androidx.annotation.ColorInt
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.TypeConverter
import com.sout.android.notes.mvp.model.reminders.ReminderManager
import java.io.*
import kotlin.math.pow

const val DB_NAME = "notes"
const val ACTUAL_DB_VERSION = 7
const val ID = "id"
const val TITLE = "title"
const val TEXT = "text"
const val ADD_MILLIS = "addMillis"
const val EDIT_MILLIS = "editMillis"
const val REMINDER_EXTRA = "reminderExtra"
const val REMINDER_TYPE = "reminderType"
const val COLOR = "color"
const val SPANS = "spans"

@Entity(tableName = DB_NAME, indices = [Index(value = [TITLE])])
data class Note(
    @PrimaryKey(autoGenerate = true) val id: Int?,
    val title: String,
    val text: String,
    val addMillis: Long,
    val editMillis: Long = addMillis,
    val reminderExtra: AbsReminderExtra? = null,
    val color: NoteColor? = null,
    val spans: String? = null
) : Serializable { companion object { fun fromMap(map: Map<String, Any?>): Note = Note(
    map[ID] as Int?,
    (map[TITLE] as String?)!!,
    (map[TEXT] as String?)!!,
    (map[ADD_MILLIS] as Long?)!!,
    (map[EDIT_MILLIS] as Long?)!!,
    color = NoteColor.values().find(fun(value) = value.value == (map[COLOR] as Long?)?.toInt()),
    spans = map[SPANS] as String?
) } }

fun Note.toMap(): Map<String, Any?> = mapOf(
    ID to id,
    TITLE to title,
    TEXT to text,
    ADD_MILLIS to addMillis,
    EDIT_MILLIS to editMillis,
    REMINDER_TYPE to reminderExtra?.type?.value,
    COLOR to color?.value?.toUInt()?.toLong(),
    SPANS to spans
)

abstract class AbsReminderExtra(
    open val id: Int,
    open val type: ReminderManager.ReminderType
) : Serializable

enum class NoteColor(@ColorInt val value: Int) { // TODO: add color picker instead of hardcoding color values
    RED        (0xFFF44336u.toInt()), // unsigned type is used cuz kotlin compiler doesn't allow placing numeric values which are higher than the int.max (2147483647) but still represented with 32 bits into int types directly although java does allow
    PINK       (0xFFE91E63u.toInt()),
    PURPLE     (0xFF9C27B0u.toInt()),
    DEEP_PURPLE(0xFF673AB7u.toInt()),
    INDIGO     (0xFF3F51B5u.toInt()),
    BLUE       (0xFF2196F3u.toInt()),
    LIGHT_BLUE (0xFF03A9F4u.toInt()),
    CYAN       (0xFF00BCD4u.toInt()),
    TEAL       (0xFF009688u.toInt()),
    GREEN      (0xFF4CAF50u.toInt()),
    LIGHT_GREEN(0xFF8BC34Au.toInt()),
    LIME       (0xFFCDDC39u.toInt()),
    YELLOW     (0xFFFFEB3Bu.toInt()),
    AMBER      (0xFFFFC107u.toInt()),
    ORANGE     (0xFFFF9800u.toInt()),
    DEEP_ORANGE(0xFFFF5722u.toInt()),
    BROWN      (0xFF795548u.toInt()),
    GRAY       (0xFF9E9E9Eu.toInt()),
    BLUE_GRAY  (0xFF607D8Bu.toInt()),
    BLACK      (0xFF000000u.toInt()),
    WHITE      (0xFFFFFFFFu.toInt());

    fun isDark(): Boolean {
        val red = 0x00ff0000 and value shr 16
        val green = 0x0000ff00 and value shr 8
        val blue = 0x000000ff and value shr 0

        fun linearize(component: Double) =
            if (component <= 0.03928) component / 12.92
            else ((component + 0.055) / 1.055).pow(2.4)

        val r = linearize(red.toDouble() / 0xFF)
        val g = linearize(green.toDouble() / 0xFF)
        val b = linearize(blue.toDouble() / 0xFF)

        val luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return (luminance + 0.05).pow(2) <= 0.15
    }
}

class NoteConverters {

    @TypeConverter
    fun bytesToAbsReminderExtra(bytes: ByteArray?): AbsReminderExtra? =
        if (bytes != null) ObjectInputStream(ByteArrayInputStream(bytes)).readObject() as AbsReminderExtra else null

    @TypeConverter
    fun absReminderExtraToBytes(obj: AbsReminderExtra?): ByteArray? = if (obj != null)
        ByteArrayOutputStream().apply { ObjectOutputStream(this).writeObject(obj) }.toByteArray()
    else null
}
