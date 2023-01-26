/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../view/AbsStatefulWidget.dart';
import '../model/core/Kernel.dart';
import 'Presenters.dart';

abstract class AbsPresenter<V extends AbsPage> extends State<V> {
  @protected
  late final Kernel kernel;
  @protected
  final Presenters presenter;

  @protected
  NavigatorState get navigator => Navigator.of(context);

  @mustCallSuper
  AbsPresenter(Object kernel, this.presenter) { this.kernel = kernel as Kernel; }

  @protected
  @mustCallSuper
  @override
  void initState() {
    super.initState();
    kernel.setPresenter(this, presenter);
  }

  @protected
  @mustCallSuper
  @override
  void dispose() {
    kernel.setPresenter(null, presenter);
    super.dispose();
  }

  @protected
  @nonVirtual
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String text,
    {Duration duration = const Duration(seconds: 4),
    List<Widget>? actions}
  ) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: SizedBox(
      height: 35,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          if (actions != null) ...actions
        ]
      ),
    ),
    duration: duration,
  ));

  @protected
  @nonVirtual
  Divider makeDividerForBottomSheet() => const Divider(
    height: 1.0,
    thickness: 1.0
  );

  @protected
  @nonVirtual
  void popTimes(int times) { for (var _ = 0; _ < times; _++) navigator.pop(); }

  @protected
  @nonVirtual
  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @protected
  @nonVirtual
  bool get isLightTheme => Theme.of(context).brightness == Brightness.light;

  @protected
  @nonVirtual
  Color get textColor => colorScheme.onSurface;
}
