/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../view/AbsStatefulWidget.dart';
import '../model/core/Kernel.dart';
import 'Presenter.dart';

abstract class AbsPresenter<V extends AbsPage> extends State<V> {
  @protected
  late final Kernel kernel;
  @protected
  final Presenter presenter;

  @mustCallSuper
  AbsPresenter(Object kernel, this.presenter) { this.kernel = kernel as Kernel; }

  @mustCallSuper
  @override
  void initState() {
    super.initState();
    kernel.setPresenter(this, presenter);
  }

  @mustCallSuper
  @override
  void dispose() {
    kernel.setPresenter(null, presenter);
    super.dispose();
  }

  @nonVirtual
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String text,
    [Duration duration = const Duration(seconds: 4)]
  ) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
    ),
    duration: duration,
  ));

  @nonVirtual
  Divider makeDividerForBottomSheet() => const Divider(height: 1.0, thickness: 1.0);
}
