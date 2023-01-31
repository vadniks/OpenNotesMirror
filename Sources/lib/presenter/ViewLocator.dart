/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:meta/meta.dart';
import 'Presenters.dart';
import '../view/AbsStatefulWidget.dart';
import '../view/CanvasPage.dart';
import '../view/EditPage.dart';
import '../view/MainPage.dart';
import '../view/Screen.dart';

@sealed
class ViewLocator {
  ViewLocator._internal() { throw Exception(); }

  static AbsPage createView(Object parameter, Presenters which) { switch (which) {
    case Presenters.SCREEN: return Screen(parameter);
    case Presenters.MAIN: return MainPage(parameter);
    case Presenters.EDIT: return EditPage(parameter);
    case Presenters.CANVAS: return CanvasPage(parameter);
  } }
}
