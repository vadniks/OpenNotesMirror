/// Created by VadNiks on Jan 28 2023
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: avoid_function_literals_in_foreach_calls, curly_braces_in_flow_control_structures

import 'dart:ui';
import 'package:flutter/material.dart' as material;
import 'package:meta/meta.dart';
import '../model/tuples.dart';
import 'paintInfo.dart';

@sealed
class CanvasPainter extends material.CustomPainter {
  final List<Point> _currentPoints;
  final List<Pair<Path, PaintInfo>> _paths;
  final Image? _image;

  CanvasPainter(this._currentPoints, this._paths, this._image);

  Paint _makePaint(PaintInfo info) => Paint()
    ..color = Color(info.color.value!).withOpacity(info.opacity)
    ..strokeCap = StrokeCap.round
    ..strokeWidth = info.width
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..blendMode = !info.erase ? BlendMode.srcOver : BlendMode.clear;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.saveLayer(bounds, Paint());
    if (_image != null) canvas.drawImage(_image!, const Offset(0, 0), Paint());
    _paths.forEach((path) => canvas.drawPath(path.a, _makePaint(path.b)));
    canvas.restore();

    _currentPoints.forEach((point) => canvas.drawPoints(
      PointMode.points,
      [Offset(point.x, point.y)],
      _makePaint(point)
    ));
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}
