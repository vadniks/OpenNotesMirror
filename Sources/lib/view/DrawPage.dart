/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: no_logic_in_create_state, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'AbsStatefulWidget.dart';
import '../presenter/DrawPagePresenter.dart';

@sealed
class DrawPage extends AbsPage {
  const DrawPage(super.parameter);

  @override
  State<StatefulWidget> createState() => DrawPagePresenter(parameter);
}
