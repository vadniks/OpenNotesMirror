/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures, empty_statements

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'Presenters.dart';
import 'ViewLocator.dart';
import '../view/Screen.dart';
import '../consts.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

@sealed
class ScreenPresenter extends AbsPresenter<Screen> {
  static const _DARK_SECONDARY_COLOR = Color(0xFF0F0F0F);
  static const _ON_THEME_CHANGED_METHOD = 'onThemeChange';
  static const _IS_DARK_THEME_METHOD = 'isDarkTheme';
  bool _isDark = false;

  MaterialColor _makeBlack() {
    Map<int, Color> map = { 50: Colors.black };
    for (int i = 100; i <= 900; map[i] = Colors.black, i += 100);
    return MaterialColor(Colors.black.value, map);
  }

  ScreenPresenter(Object kernel) : super(kernel, Presenters.SCREEN) {
    super.kernel.interop.observeMethodHandling(_handleKotlinMethod, true);
    super.kernel.interop.callKotlinMethod(_IS_DARK_THEME_METHOD, null)
      .then((isDark) => setState(() => _isDark = isDark));
  }

  @override
  void dispose() {
    kernel.interop.observeMethodHandling(_handleKotlinMethod, false);
    super.dispose();
  }

  Future<bool> _handleKotlinMethod(MethodCall call) async {
    if (call.method == _ON_THEME_CHANGED_METHOD) {
      setState(() => _isDark = call.arguments);
      return true;
    } else
      return false;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: APP_NAME,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.green,
        accentColor: Colors.greenAccent
      ),
      primarySwatch: !_isDark && SchedulerBinding.instance.window.platformBrightness == Brightness.light
        ? Colors.green
        : _makeBlack()
    ),
    themeMode: _isDark ? ThemeMode.dark : ThemeMode.system,
    darkTheme: ThemeData.dark().copyWith(
      primaryColor: Colors.cyan,
      brightness: Brightness.dark,
      backgroundColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      canvasColor: Colors.black,
      dialogBackgroundColor: _DARK_SECONDARY_COLOR,
      snackBarTheme: const SnackBarThemeData(backgroundColor: _DARK_SECONDARY_COLOR),
      listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),
      cardColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.cyan,
        surface: _DARK_SECONDARY_COLOR,
        onSecondary: _DARK_SECONDARY_COLOR,
        onSurface: Colors.white
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _DARK_SECONDARY_COLOR,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        )
      )
    ),
    initialRoute: ROUTE_MAIN,
    routes: {
      ROUTE_MAIN : (context) => ViewLocator.createView(kernel, Presenters.MAIN),
      ROUTE_EDIT : (context) => ViewLocator.createView(kernel, Presenters.EDIT),
      ROUTE_CANVAS : (context) => ViewLocator.createView(kernel, Presenters.CANVAS)
    },
  );
}
