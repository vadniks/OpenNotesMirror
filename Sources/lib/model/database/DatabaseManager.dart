/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import '../core/Kernel.dart';
import '../Observable.dart';
import '../Pair.dart';
import 'DBModificationMode.dart';
import 'Note.dart';

@sealed
class DatabaseManager {
  static const _FETCH_NOTES_METHOD = 'b.0';
  static const _INSERT_NOTE_METHOD = 'b.1';
  static const _UPDATE_NOTE_METHOD = 'b.2';
  static const _DELETE_NOTE_METHOD = 'b.3';
  static const _ON_DB_MODIFIED_METHOD = 'a.0';
  static const _GET_NOTE_BY_ID_METHOD = "b.4";
  static const _SEARCH_BY_TITLE_METHOD = 'b.10';
  static const _NOTIFY_BACKED_UP_DB_METHOD = 'a.4';
  static bool _initialized = false;
  final Kernel _kernel;
  final Observable<Pair<Note?, DBModificationMode>, void> _observable = Observable();

  DatabaseManager(this._kernel) {
    assert(!_initialized);
    _initialized = true;
    _kernel.interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
      case _ON_DB_MODIFIED_METHOD:
        List<dynamic> arguments = call.arguments;
        await onDBModified(
            arguments[0] != null ? Note.fromMap(arguments[0]) : null,
            DBModificationMode.create(arguments[1] as int)
        );
        return true;
      case _NOTIFY_BACKED_UP_DB_METHOD:
        _kernel.callMainPresenter((presenter) => presenter.notifyDBBackedUp());
        return true;
    }
    return false;
  }

  Future<List<Note>> fetchNotes(int from, int amount) async {
    assert(from >= 0 && amount > 0);
    List<dynamic>? fetched = await _kernel.interop
        .callKotlinMethod(_FETCH_NOTES_METHOD, <int>[from, amount]);
    return fetched?.map(Note.fromMap).toList() ?? <Note>[];
  }

  Future<int> insertNote(Note note) async {
    assert(note.id == null && note.title.isNotEmpty && note.text.isNotEmpty);
    return await _kernel.interop.callKotlinMethod(_INSERT_NOTE_METHOD, note.toMap());
  }

  Future<int> updateNote(Note note) async {
    assert(note.id != null && note.title.isNotEmpty && note.text.isNotEmpty);
    return await _kernel.interop.callKotlinMethod(_UPDATE_NOTE_METHOD, note.toMap());
  }

  Future<int> deleteNote(Note note) async {
    assert(note.id != null);
    return await _kernel.interop.callKotlinMethod(_DELETE_NOTE_METHOD, note.toMap());
  }

  Future<Note?> getNoteById(int id) async =>
      await _kernel.interop.callKotlinMethod(_GET_NOTE_BY_ID_METHOD, id, (object) =>
      object != null ? Note.fromMap(object) : null);

  Future<void> onDBModified(Note? note, DBModificationMode mode) async =>
      _observable.notify(Pair(note, mode), null);

  void observeDBModification(
    void Function(Pair<Note?, DBModificationMode>) observer,
    bool add
  ) => _observable.observe(observer, add);

  Future<List<Note>> searchByTitle(String title) async => (await _kernel
      .interop
      .callKotlinMethod(_SEARCH_BY_TITLE_METHOD, title) as List<dynamic>
  ).map(Note.fromMap).toList(growable: false);
}