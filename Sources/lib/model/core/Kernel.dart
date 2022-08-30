/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
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
import '../../presenter/Presenter.dart';
import '../../presenter/ViewLocator.dart';
import '../../presenter/EditPagePresenter.dart';
import '../../presenter/MainPagePresenter.dart';
import '../../presenter/DrawPagePresenter.dart';
import 'package:meta/meta.dart';
import '../database/DatabaseManager.dart';
import '../reminders/ReminderManager.dart';
import 'Interop.dart';

@sealed
class Kernel {
  static bool _initialized = false;
  MainPagePresenter? _mainPagePresenter;
  EditPagePresenter? _editPagePresenter;
  DrawPagePresenter? _drawPagePresenter;
  late final Interop interop;
  late final DatabaseManager dbManager;
  late final ReminderManager reminderManager;
  static const _HANDLE_SEND_METHOD = 'a.3';

  Kernel() {
    assert(!_initialized);
    _initialized = true;

    runApp(ViewLocator.createView(this, Presenter.SCREEN));
    interop = Interop(this);
    dbManager = DatabaseManager(this);
    reminderManager = ReminderManager(this);
    interop.observeMethodHandling(_handleKotlinMethod, true);
  }

  void setPresenter(AbsPresenter? presenter, Presenter which) {
    switch (which) {
      case Presenter.SCREEN: /*ignore*/ break;
      case Presenter.MAIN: _mainPagePresenter = presenter as MainPagePresenter?; break;
      case Presenter.EDIT: _editPagePresenter = presenter as EditPagePresenter?; break;
      case Presenter.DRAW: _drawPagePresenter = presenter as DrawPagePresenter?; break;
    }
  }

  void callMainPresenter(void Function(MainPagePresenter) action) =>
      _mainPagePresenter == null
          ? MainPagePresenter.observeMainPageLaunch((presenter) => action(presenter), true)
          : action(_mainPagePresenter!);

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    switch (call.method) {
      case _HANDLE_SEND_METHOD:
        List<dynamic> arguments = call.arguments;
        callMainPresenter((presenter) => presenter.handleSendText(arguments[0] as String, arguments[1] as String));
        return true;
    }
    return false;
  }
}
