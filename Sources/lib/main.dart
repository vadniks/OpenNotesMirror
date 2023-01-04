/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'model/core/Kernel.dart';

void main() => Kernel();

/*
TODO: add canvas notes (ability to draw)
TODO: add audio notes
TODO: add database encryption or encrypt each note
TODO: add db import/export
TODO: add tags (mark a note with a tag and search by tag)
TODO: add creation and edition dateTime
TODO: add qr code generation
TODO: add db sync with Google account (import/export db)
TODO: add ability to change font style & color
TODO: optimize db usage: query only first n chars from title & text when fetching all notes for the main list and when user opens note query full fields
TODO: add db data compression (or/and in memory compression of lists of notes)
TODO: add ability to manually change theme
TODO: W/OnBackInvokedCallback: OnBackInvokedCallback is not enabled for the application. Set 'android:enableOnBackInvokedCallback="true"' in the application manifest. # WORKS WITHOUT IT
*/
