/// Created by VadNiks on Aug 10 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

import 'package:meta/meta.dart';

@sealed
class Reference<T> {
  T value;
  Reference(this.value);
}

@immutable
@sealed
class Pair<A, B> {
  final A a;
  final B b;

  const Pair(this.a, this.b);
}

@immutable
@sealed
class Triple<A, B, C> {
  final A a;
  final B b;
  final C c;

  const Triple(this.a, this.b, this.c);
}

@immutable
@sealed
class Tetrad<A, B, C, D> {
  final A a;
  final B b;
  final C c;
  final D d;

  const Tetrad(this.a, this.b, this.c, this.d);
}
