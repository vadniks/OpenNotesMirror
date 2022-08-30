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
import '../../consts.dart';
import '../database/Note.dart';
import 'ReminderType.dart';

@sealed
class ReminderManager {
  static const _CREATE_OR_UPDATE_REMINDER_METHOD = "b.5";
  static const _IS_REMINDER_SET_METHOD = 'b.6';
  static const _CANCEL_REMINDER_METHOD = 'b.7';
  static const _LAUNCH_EDIT_PAGE = 'a.1';
  static const _GET_TIMED_DETAILS = 'b.8';
  static const _CONFIGURE_WIDGET_METHOD = 'a.2';
  static const _SET_WIDGET_METHOD = 'b.9';
  static const _NOTIFY_CANT_POST_NOTIFICATIONS_METHOD = 'a.5';
  static bool _initialized = false;
  final Kernel _kernel;

  ReminderManager(this._kernel) {
    assert(!_initialized);
    _initialized = true;
    _kernel.interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
      case _LAUNCH_EDIT_PAGE:
        _kernel.callMainPresenter((presenter) => presenter.launchEditPage(Note.fromMap(call.arguments)));
        return true;
      case _CONFIGURE_WIDGET_METHOD:
        _kernel.callMainPresenter((presenter) => presenter.configureWidget(call.arguments));
        return true;
      case _NOTIFY_CANT_POST_NOTIFICATIONS_METHOD:
        _kernel.callMainPresenter((presenter) => presenter.notifyCantPostNotifications());
        return true;
    }
    return false;
  }

  Future<int?> createOrUpdateReminder(Note note, int? dateTime, int? period) async {
    assert(note.title.isNotEmpty && note.text.isNotEmpty);
    return await _kernel.interop.callKotlinMethod(
      _CREATE_OR_UPDATE_REMINDER_METHOD,
      <Object>[
        note.toMap(),
        note.reminderType!.value,
        dateTime ?? NUM_UNDEF,
        period ?? NUM_UNDEF
      ]
    );
  }

  Future<bool> isReminderSet(int id) async =>
      await _kernel.interop.callKotlinMethod(_IS_REMINDER_SET_METHOD, id);

  Future<void> cancelReminder(int id, ReminderType type, bool cancelInDB) async =>
      await _kernel.interop.callKotlinMethod(
        _CANCEL_REMINDER_METHOD,
        <Object>[id, type.value, cancelInDB]
      );

  Future<String?> getTimedReminderDetails(int? id) async =>
      await _kernel.interop.callKotlinMethod(_GET_TIMED_DETAILS, id);

  Future<void> setWidget(int? noteId, int widgetId) async =>
      await _kernel.interop.callKotlinMethod(_SET_WIDGET_METHOD, [noteId, widgetId]);
}
