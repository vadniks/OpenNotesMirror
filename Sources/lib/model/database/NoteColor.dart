/// Created by VadNiks on Aug 25 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures

import '../../consts.dart';

enum NoteColor {
  RED        (0xFFF44336, 'Red'),
  PINK       (0xFFE91E63, 'Pink'),
  PURPLE     (0xFF9C27B0, 'Purple'),
  DEEP_PURPLE(0xFF673AB7, 'Deep purple'),
  INDIGO     (0xFF3F51B5, 'Indigo'),
  BLUE       (0xFF2196F3, 'Blue'),
  LIGHT_BLUE (0xFF03A9F4, 'Light blue'),
  CYAN       (0xFF00BCD4, 'Cyan'),
  TEAL       (0xFF009688, 'Teal'),
  GREEN      (0xFF4CAF50, 'Green'),
  LIGHT_GREEN(0xFF8BC34A, 'Light green'),
  LIME       (0xFFCDDC39, 'Lime'),
  YELLOW     (0xFFFFEB3B, 'Yellow'),
  AMBER      (0xFFFFC107, 'Amber'),
  ORANGE     (0xFFFF9800, 'Orange'),
  DEEP_ORANGE(0xFFFF5722, 'Deep orange'),
  BROWN      (0xFF795548, 'Brown'),
  GRAY       (0xFF9E9E9E, 'Gray'),
  BLUE_GRAY  (0xFF607D8B, 'Blue gray'),
  BLACK      (0xFF000000, 'Black'),
  WHITE      (0xFFFFFFFF, 'White'),
  NONE       (NUM_UNDEF, 'None');

  const NoteColor(this._value, this.name);
  final int _value;
  final String name;

  int? get value => _value == NUM_UNDEF ? null : _value;

  static NoteColor? create(int? value) {
    if (value == null || value == NoteColor.NONE._value) return null;
    for (final i in NoteColor.values)
      if (i.value == value) return i;
    return null;
  }

  static NoteColor? create2(int? index) => index == null ? null :
    index <= NoteColor.values.length && index >= 0 ? NoteColor.values[index] : null;
}
