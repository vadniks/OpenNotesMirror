/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'Kernel.dart';
import '../Observable.dart';
import '../../consts.dart';

@sealed
class Interop {
  static const _CHANNEL_NAME = '$PACKAGE_NAME/channel';
  static const LAUNCH_EDIT_PAGE = 'launchEditPage';
  static const SEND_METHOD = 'send';
  static const _LOG_METHOD = 'log';
  static bool _initialized = false;
  late final MethodChannel _channel;
  final Observable<MethodCall, Future<bool>> _observable = Observable();

  Interop(Kernel _) {
    assert(!_initialized);
    _initialized = true;

    _channel = const MethodChannel(_CHANNEL_NAME);
    _channel.setMethodCallHandler(_handleKotlinMethod);
  }

  void log(Object? msg) => callKotlinMethod(_LOG_METHOD, msg.toString());

  Future<void> _handleKotlinMethod(MethodCall call) async {
    bool result = false;
    _observable.notify(call, (res) async => result |= await res);
    if (!result) throw ArgumentError(EMPTY_STRING);
  }

  void observeMethodHandling(Future<bool> Function(MethodCall) observer, bool add) =>
    _observable.observe(observer, add);

  Future<T> callKotlinMethod<T>(
    String which,
    dynamic argument,
    [T Function(dynamic)? converter]
  ) async {
    final result = await _channel.invokeMethod<dynamic>(which, argument);
    return converter != null ? converter(result) : result;
  }
}
