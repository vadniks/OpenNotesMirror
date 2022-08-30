/**
 * Created by VadNiks on Aug 11 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model

import androidx.annotation.WorkerThread

class Observable<P, R> {
    private val observers = ArrayList<suspend (P) -> R>()
    val size get() = observers.size

    fun observe(observer: suspend (P) -> R, add: Boolean) =
        if (add) observers.add(observer) else observers.remove(observer)

    @WorkerThread
    suspend fun notify(parameter: P, callback: ((R) -> Unit)?) =
        observers.forEach { if (callback != null) callback(it(parameter)) else it(parameter) }

    @Suppress("RedundantSuspendModifier")
    @WorkerThread
    suspend fun reset() = observers.clear()
}
