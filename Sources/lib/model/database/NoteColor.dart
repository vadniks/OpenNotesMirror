/// Created by VadNiks on Aug 25 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

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
    switch (value) {
      case null: return null;
      case 0xFFF44336: return NoteColor.RED;
      case 0xFFE91E63: return NoteColor.PINK;
      case 0xFF9C27B0: return NoteColor.PURPLE;
      case 0xFF673AB7: return NoteColor.DEEP_PURPLE;
      case 0xFF3F51B5: return NoteColor.INDIGO;
      case 0xFF2196F3: return NoteColor.BLUE;
      case 0xFF03A9F4: return NoteColor.LIGHT_BLUE;
      case 0xFF00BCD4: return NoteColor.CYAN;
      case 0xFF009688: return NoteColor.TEAL;
      case 0xFF4CAF50: return NoteColor.GREEN;
      case 0xFF8BC34A: return NoteColor.LIGHT_GREEN;
      case 0xFFCDDC39: return NoteColor.LIME;
      case 0xFFFFEB3B: return NoteColor.YELLOW;
      case 0xFFFFC107: return NoteColor.AMBER;
      case 0xFFFF9800: return NoteColor.ORANGE;
      case 0xFFFF5722: return NoteColor.DEEP_ORANGE;
      case 0xFF795548: return NoteColor.BROWN;
      case 0xFF9E9E9E: return NoteColor.GRAY;
      case 0xFF607D8B: return NoteColor.BLUE_GRAY;
      case 0xFF000000: return NoteColor.BLACK;
      case 0xFFFFFFFF: return NoteColor.WHITE;
      default: throw ArgumentError(EMPTY_STRING);
    }
  }
}
