/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../presenter/AbsPresenter.dart';
import '../../presenter/Presenters.dart';
import '../../presenter/ViewLocator.dart';
import '../../presenter/MainPagePresenter.dart';
import 'package:meta/meta.dart';
import '../database/DatabaseManager.dart';
import '../database/Note.dart';
import '../reminders/ReminderManager.dart';
import 'Interop.dart';

@sealed
class Kernel {
  static bool _initialized = false;
  MainPagePresenter? _mainPagePresenter;
  late final Interop interop;
  late final DatabaseManager dbManager;
  late final ReminderManager reminderManager;
  static const _HANDLE_SEND_METHOD = 'handleSend'; // why the f*** there is no private modifier in Dart, is it too hard to implement? Okay I can barely understand why there's no package-private modifier but plain private modifier? JUST WHY!?
  static const _NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD = 'notifyDatabaseExportedOrImported';

  Kernel() {
    assert(!_initialized);
    _initialized = true;

    runApp(ViewLocator.createView(this, Presenters.SCREEN));
    interop = Interop(this);
    dbManager = DatabaseManager(this);
    reminderManager = ReminderManager(this);
    interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  void setPresenter(AbsPresenter? presenter, Presenters which) {
    switch (which) {
      case Presenters.SCREEN: /*ignore*/ break;
      case Presenters.MAIN: _mainPagePresenter = presenter as MainPagePresenter?; break;
      case Presenters.EDIT: /*ignore*/ break; // maybe will be used in the future
      case Presenters.DRAW: /*ignore*/ break; // TODO: rename to canvas
    }
  }

  void callMainPresenter(void Function(MainPagePresenter) action) =>
    _mainPagePresenter == null
      ? MainPagePresenter.observeMainPageLaunch((presenter) => action(presenter), true)
      : action(_mainPagePresenter!);

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
      case _HANDLE_SEND_METHOD:
        List<dynamic> arguments = call.arguments; // MainPagePresenter doesn't directly listen for this backend call cuz it might appear before presenter initialization like when app isn't not running but user has just performed text sending from another app therefore presenter must be initialized first
        callMainPresenter((presenter) => presenter.handleSendText(arguments[0] as String, arguments[1] as String));
        return true;
      case Interop.LAUNCH_EDIT_PAGE: // and this call is handled here cuz MPP has the corresponding method and this call can happened when MPP hasn't been initialized yet too
        callMainPresenter((presenter) => presenter.launchEditPage(Note.fromMap(call.arguments)));
        return true;
      case _NOTIFY_DATABASE_EXPORTED_OR_IMPORTED_METHOD: // TODO: make MPP listen & process this call itself
        callMainPresenter((presenter) => presenter.onDatabaseExportedOrImported(call.arguments)); // I'm too lazy to move it there
        return true;
    }
    return false;
  }
}
