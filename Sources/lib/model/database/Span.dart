/// Created by VadNiks on Jan 17 2023
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:meta/meta.dart';
import '../../consts.dart';
import '../../model/database/NoteColor.dart';
import '../../presenter/spannableTextEditingController.dart';

@sealed
@immutable
class Span {
  final FontStyleExtended style;
  final NoteColor? color;
  final int start;
  final int end;

  const Span(this.style, this.color, this.start, this.end);

  Span copy({
    FontStyleExtended? style,
    NoteColor? color,
    int? start,
    int? end
  }) => Span(
    style ?? this.style,
    color ?? this.color,
    start ?? this.start,
    end ?? this.end
  );

  @override
  String toString() => '${style.id},${color?.index ?? NUM_UNDEF},$start,$end';

  static Span? fromString(String string) {
    final splitted = string.split(',');
    if (splitted.length != 4) return null;

    final style = FontStyleExtended.create(int.tryParse(splitted[0]));
    if (style == null) return null;

    final color = NoteColor.create2(int.tryParse(splitted[1]));

    final start = int.tryParse(splitted[2]);
    if (start == null) return null;

    final end = int.tryParse(splitted[3]);
    if (end == null) return null;

    return Span(style, color, start, end);
  }
}
