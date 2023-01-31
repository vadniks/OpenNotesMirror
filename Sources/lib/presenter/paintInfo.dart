/// Created by VadNiks on Jan 29 2023
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:meta/meta.dart';
import '../model/database/NoteColor.dart';

@sealed
@immutable
class PaintInfo {
  final NoteColor color;
  final double opacity;
  final double width;
  final bool erase;
  const PaintInfo(this.color, this.opacity, this.width, this.erase);
}

@sealed
@immutable
class Point extends PaintInfo {
  final double x;
  final double y;

  const Point(
    this.x,
    this.y,
    NoteColor color,
    double opacity,
    double width,
    bool erase
  ) : super(color, opacity, width, erase);
}
