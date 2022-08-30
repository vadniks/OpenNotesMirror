/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

abstract class AbsPage extends StatefulWidget {
  final Object parameter;

  const AbsPage(this.parameter);
}
