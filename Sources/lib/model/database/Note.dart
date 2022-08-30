/// Created by VadNiks on Aug 01 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names

import 'package:meta/meta.dart';
import '../reminders/ReminderType.dart';
import 'NoteColor.dart';

@sealed
@immutable
class Note {
  final int? id;
  final String title;
  final String text;
  final ReminderType? reminderType;
  final NoteColor? color;

  static const ID = 'id';
  static const TITLE = 'title';
  static const TEXT = 'text';
  static const REMINDER_TYPE = 'reminderType';
  static const COLOR = 'color';

  const Note({
    this.id,
    required this.title,
    required this.text,
    this.reminderType,
    this.color
  });

  Note copy({
    int? id,
    String? title,
    String? text,
    ReminderType? reminderType,
    NoteColor? color
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    text: text ?? this.text,
    reminderType: reminderType ?? this.reminderType,
    color: color ?? this.color
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          text == other.text &&
          reminderType == other.reminderType;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ text.hashCode ^ reminderType.hashCode;

  static Note fromMap(dynamic map) => Note(
    id: map[ID] as int,
    title: map[TITLE],
    text: map[TEXT],
    reminderType: ReminderType.create(map[REMINDER_TYPE]),
    color: NoteColor.create(map[COLOR])
  );

  Map<String, dynamic> toMap() {
    assert(color == null || color!.value != null);
    return {
      ID : id,
      TITLE : title,
      TEXT : text,
      REMINDER_TYPE : reminderType?.value,
      COLOR : color?.value
    };
  }

  @override
  String toString() => '($id, $title, $text, $reminderType)';
}
