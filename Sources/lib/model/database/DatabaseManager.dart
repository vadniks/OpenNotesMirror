/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
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
import '../tuples.dart';
import 'Note.dart';

@sealed
class DatabaseManager {
  static const _FETCH_NOTES_METHOD = 'fetchNotes';
  static const _INSERT_NOTE_METHOD = 'insertNote';
  static const _UPDATE_NOTE_METHOD = 'updateNote';
  static const _DELETE_NOTE_METHOD = 'deleteNote';
  static const _ON_DB_MODIFIED_METHOD = 'onDbModified';
  static const _GET_NOTE_BY_ID_METHOD = "getNoteById";
  static const _SEARCH_BY_TITLE_METHOD = 'searchByTitle';
  static const _NOTIFY_BACKED_UP_DB_METHOD = 'notifyBackedUpDb';
  static const _DELETE_SELECTED_METHOD = 'deleteSelected';
  static const _SET_SORT_MODE_METHOD = 'setSortMode';
  static const _GET_SORT_MODE_METHOD = 'getSortMode';
  static bool _initialized = false;
  final Kernel _kernel;
  final Observable<void, void> _observable = Observable();

  DatabaseManager(this._kernel) {
    assert(!_initialized);
    _initialized = true;
    _kernel.interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
      case _ON_DB_MODIFIED_METHOD:
        await onDBModified();
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

  Future<void> onDBModified() async => _observable.notify(null, null);

  void observeDBModification(void Function(void) observer, bool add) =>
    _observable.observe(observer, add);

  Future<List<Note>> searchByTitle(String title) async => (
    await _kernel.interop
    .callKotlinMethod(_SEARCH_BY_TITLE_METHOD, title) as List<dynamic>
  ).map(Note.fromMap).toList(growable: false);

  Future<void> deleteSelected(List<int> ids) async =>
    _kernel.interop.callKotlinMethod(_DELETE_SELECTED_METHOD, ids);

  Future<Pair<int, bool>> fetchSortMode() async {
    final result = await _kernel.interop.callKotlinMethod(_GET_SORT_MODE_METHOD, null) as List<dynamic>;
    return Pair(result[0], result[1]);
  }

  Future<void> setSortMode(int which, bool order) async =>
    await _kernel.interop.callKotlinMethod(_SET_SORT_MODE_METHOD, [which, order]);
}
