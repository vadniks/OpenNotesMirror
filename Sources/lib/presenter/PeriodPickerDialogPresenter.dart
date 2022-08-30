/// Created by VadNiks on Aug 15 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../consts.dart';
import '../view/PeriodPickerDialog.dart';

@sealed
class PeriodPickerDialogPresenter extends State<PeriodPickerDialog> {
  final void Function(int millis) _onSuccess;
  final void Function() _onFailure;
  late final List<TextEditingController> _controllers;
  var _succeeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController()
    ];
  }

  @override
  void dispose() {
    if (!_succeeded) _onFailure();
    super.dispose();
  }

  PeriodPickerDialogPresenter(this._onSuccess, this._onFailure);
  
  int? _fieldValue(int index) => int.tryParse(_controllers[index].text);

  Widget makeField(int index, String hint) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: TextFormField(
        decoration: InputDecoration(hintText: hint),
        controller: _controllers[index],
        keyboardType: const TextInputType.numberWithOptions(
          signed: false,
          decimal: true
        ),
      ),
    )
  );

  bool _checkFields() {
    var areAllEmpty = true;
    _controllers.forEach((controller) =>
        areAllEmpty &= controller.text.isEmpty);

    var areAllValid = true;
    final bounds = [4, 31, 24, 60];

    for (int i = 0; i < 4; i++) {
      final field = _fieldValue(i);
      areAllValid &= _controllers[i].text.isEmpty
          || field != null
          && field >= 0
          && field <= bounds[i];
    }
    return !areAllEmpty && areAllValid;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          SET_PERIOD,
          style: TextStyle(fontSize: 20)
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            TIME_PERIOD_HINT,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            makeField(0, WEEKS),
            makeField(1, DAYS),
            makeField(2, HOURS),
            makeField(3, MINUTES)
          ]
        ),
        TextButton(
          onPressed: () {
            if (!_checkFields()) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(WRONG_VALUES_ENTERED)));
              return;
            }

            _succeeded = true;
            Navigator.of(context).pop();
            
            Timer.run(() => _onSuccess(
              Duration(
                days: (_fieldValue(0) ?? 0) * 7 + (_fieldValue(1) ?? 0),
                hours: _fieldValue(2) ?? 0,
                minutes: _fieldValue(3) ?? 0
              ).inMilliseconds
            ));
          },
          child: Text(
            DONE.toUpperCase(),
            style: const TextStyle(fontSize: 18),
          )
        )
      ],
    )
  );
}

// int.parse(_controllers[0].text) * 1000 * 60 * 60 * 24 * 7 +
// int.parse(_controllers[1].text) * 1000 * 60 * 60 * 24 +
// int.parse(_controllers[2].text) * 1000 * 60 * 60 +
// int.parse(_controllers[3].text) * 1000 * 60
