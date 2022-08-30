/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

import '../../consts.dart';

enum DBModificationMode {
  INSERT(0), UPDATE(1), DELETE(2);

  const DBModificationMode(this.value);
  final int value;

  static DBModificationMode create(int value) {
    switch (value) {
      case 0: return DBModificationMode.INSERT;
      case 1: return DBModificationMode.UPDATE;
      case 2: return DBModificationMode.DELETE;
      default: throw ArgumentError(EMPTY_STRING);
    }
  }
}
