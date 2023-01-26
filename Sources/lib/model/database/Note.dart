/// Created by VadNiks on Aug 01 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
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
  final int? id; // 32 bit in jvm
  final String title;
  final String text;
  final int addMillis; // 64 bits
  final int editMillis; // 64 bits
  final ReminderType? reminderType;
  final NoteColor? color;
  final String? spans;

  static const ID = 'id',
    TITLE = 'title',
    TEXT = 'text',
    ADD_MILLIS = 'addMillis',
    EDIT_MILLIS = 'editMillis',
    REMINDER_TYPE = 'reminderType',
    COLOR = 'color',
    SPANS = 'spans',
    UNDEF_LONG = -0x100000000; // cuz int will be casted to long by the methodChannel's codec only if a value occupies more than 32 bits

  const Note({
    this.id,
    required this.title,
    required this.text,
    this.addMillis = UNDEF_LONG, // to unsure the standardMessageCodec will interpret values of these fields as long (more than 32 bits) when calling jvm methods
    this.editMillis = UNDEF_LONG,
    this.reminderType,
    this.color,
    this.spans
  });

  Note copy({
    int? id,
    String? title,
    String? text,
    int? addMillis,
    int? editMillis,
    ReminderType? reminderType,
    NoteColor? color,
    String? spans,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    text: text ?? this.text,
    addMillis: addMillis ?? this.addMillis,
    editMillis: editMillis ?? this.editMillis,
    reminderType: reminderType ?? this.reminderType,
    color: color ?? this.color,
    spans: spans ?? this.spans
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Note &&
      runtimeType == other.runtimeType &&
      id == other.id &&
      title == other.title &&
      text == other.text &&
      addMillis == other.addMillis &&
      editMillis == other.editMillis &&
      reminderType == other.reminderType &&
      color == other.color &&
      spans == other.spans;

  @override
  int get hashCode =>
    id.hashCode ^
    title.hashCode ^
    text.hashCode ^
    addMillis.hashCode ^
    editMillis.hashCode ^
    reminderType.hashCode ^
    color.hashCode ^
    spans.hashCode;

  static Note fromMap(dynamic map) => Note(
    id: map[ID] as int?,
    title: map[TITLE],
    text: map[TEXT],
    addMillis: map[ADD_MILLIS],
    editMillis: map[EDIT_MILLIS],
    reminderType: ReminderType.create(map[REMINDER_TYPE]),
    color: NoteColor.create(map[COLOR]),
    spans: map[SPANS] as String?
  );

  Map<String, dynamic> toMap() {
    assert(color == null || color!.value != null);
    return {
      ID : id,
      TITLE : title,
      TEXT : text,
      ADD_MILLIS : addMillis,
      EDIT_MILLIS : editMillis,
      REMINDER_TYPE : reminderType?.value,
      COLOR : color?.value,
      SPANS : spans
    };
  }

  @override
  String toString() => '($id, $title, $text, $addMillis, $editMillis, $reminderType, $color)';
}
