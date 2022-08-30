/// Created by VadNiks on Aug 15 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: use_key_in_widget_constructors, no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../presenter/PeriodPickerDialogPresenter.dart';

@sealed
class PeriodPickerDialog extends StatefulWidget {
  final void Function(int millis) _onSuccess;
  final void Function() _onFailure;

  const PeriodPickerDialog(this._onSuccess, this._onFailure);

  @override
  State<StatefulWidget> createState() =>
      PeriodPickerDialogPresenter(_onSuccess, _onFailure);
}
