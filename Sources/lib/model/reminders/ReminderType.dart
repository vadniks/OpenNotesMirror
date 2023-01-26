/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import '../../consts.dart';

enum ReminderType {
  ATTACHED(0), TIMED(1), SCHEDULED(2), WIDGETED(3);

  static const ATTACHED_MARKER = '<attached>';
  static const TIMED_MARKER = '<timed>';
  static const SCHEDULED_MARKER = '<scheduled>';
  static const WIDGETED_MARKER = '<in widget>';
  
  const ReminderType(this.value);
  final int value;

  static ReminderType? create(int? value) {
    if (value == null) return null;
    for (final type in ReminderType.values)
      if (type.value == value) return type;
    return null;
  }

  @override
  String toString() {
    switch (value) {
      case 0: return ATTACHED_MARKER;
      case 1: return TIMED_MARKER;
      case 2: return SCHEDULED_MARKER;
      case 3: return WIDGETED_MARKER;
      default: throw ArgumentError(EMPTY_STRING);
    }
  }
}
