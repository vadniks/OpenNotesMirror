/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:meta/meta.dart';

@sealed
class Observable<P, R> {
  final List<R Function(P)> _observers = [];
  
  void observe(R Function(P) observer, bool add) =>
      add ? _observers.add(observer) : _observers.remove(observer);

  void notify(P parameter, void Function(R)? callback) {
    for (final observer in _observers)
      callback != null ? callback(observer(parameter)) : observer(parameter);
  }

  void reset() => _observers.clear();
}
