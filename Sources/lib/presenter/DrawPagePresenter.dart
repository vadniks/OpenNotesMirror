/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:flutter/material.dart';
import 'Presenter.dart';
import '../view/DrawPage.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';

@sealed
class DrawPagePresenter extends AbsPresenter<DrawPage> {
  DrawPagePresenter(Object kernel) : super(kernel, Presenter.DRAW);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
