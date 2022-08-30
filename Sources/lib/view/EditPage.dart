/// Created by VadNiks on Jul 31 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'AbsStatefulWidget.dart';
import '../presenter/EditPagePresenter.dart';
import 'package:meta/meta.dart';

@sealed
class EditPage extends AbsPage {
  const EditPage(super.parameter);

  @override
  State<EditPage> createState() => EditPagePresenter(parameter);
}
