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
import '../../consts.dart';
import '../database/Note.dart';
import 'ReminderType.dart';

@sealed
class ReminderManager {
  static const _CREATE_OR_UPDATE_REMINDER_METHOD = 'createOrUpdateReminder';
  static const _IS_REMINDER_SET_METHOD = 'isReminderSet';
  static const _CANCEL_REMINDER_METHOD = 'cancelReminder';
  static const _GET_REMINDER_DETAILS = 'getReminderDetails';
  static const _CONFIGURE_WIDGET_METHOD = 'configureWidget';
  static const _SET_WIDGET_METHOD = 'setWidget';
  static const _NOTIFY_CANT_POST_NOTIFICATIONS_METHOD = 'notifyCantPostNotifications';
  static const _CAN_POST_NOTIFICATIONS_METHOD = 'canPostNotifications';
  static bool _initialized = false;
  final Kernel _kernel;

  ReminderManager(this._kernel) {
    assert(!_initialized);
    _initialized = true;
    _kernel.interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
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

  Future<String?> getReminderDetails(int? id) async =>
    await _kernel.interop.callKotlinMethod(_GET_REMINDER_DETAILS, id);

  Future<void> setWidget(int? noteId, int widgetId) async =>
    await _kernel.interop.callKotlinMethod(_SET_WIDGET_METHOD, [noteId, widgetId]);

  Future<bool> canPostNotifications() async =>
    await _kernel.interop.callKotlinMethod(_CAN_POST_NOTIFICATIONS_METHOD, null);
}
