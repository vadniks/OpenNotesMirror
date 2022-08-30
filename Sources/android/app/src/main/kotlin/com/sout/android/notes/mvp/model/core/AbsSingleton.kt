/**
 * Created by VadNiks on Aug 21 2022
 * Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
 *
 * This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
 * No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
 * without author's written permission, are strongly prohibited.
 *
 * Source codes are opened only for review.
 */

package com.sout.android.notes.mvp.model.core

import kotlin.reflect.KClass

abstract class AbsSingleton {

    init {
        assert(!(map[this::class] ?: false))
        map[this::class] = true
    }

    companion object {
        private val map = HashMap<KClass<out AbsSingleton>, Boolean>()
    }
}
