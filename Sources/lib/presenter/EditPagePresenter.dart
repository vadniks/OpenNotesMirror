/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2022 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import '../model/database/NoteColor.dart';
import 'Presenter.dart';
import '../view/PeriodPickerDialog.dart';
import '../model/database/Note.dart';
import '../model/reminders/ReminderType.dart';
import '../view/EditPage.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';
import '../consts.dart';

@sealed
class EditPagePresenter extends AbsPresenter<EditPage> {
  late TextEditingController _titleController;
  late TextEditingController _textController;
  Note? _noteParameter;
  NoteColor? _color;
  static const _SEND_METHOD = 'b.11';

  bool get _isEditing => _noteParameter != null;

  EditPagePresenter(Object kernel) : super(kernel, Presenter.EDIT);

  List<String>? _getTextsOrNull() {
    String title = _titleController.value.text;
    String text = _textController.value.text;

    if (title.isEmpty || text.isEmpty) {
      showSnackBar(TEXTS_ARE_EMPTY);
      return null;
    } else
      return [title, text];
  }

  void _onSaveClicked() {
    List<String>? texts;
    if ((texts = _getTextsOrNull()) == null)
      return;

    var note = Note(
      title: texts![0],
      text: texts[1],
      color: _getColor()
    );

    if (!_isEditing)
      kernel.dbManager.insertNote(note).then((id) => _afterSave(id, note));
    else {
      note = note.copy(
        id: _noteParameter!.id,
        reminderType: _noteParameter!.reminderType
      );

      if (note.reminderType != null)
        kernel.reminderManager.createOrUpdateReminder(note, null, null)
            .then((_) => _afterSave(null, note));
      else
        kernel.dbManager.updateNote(note).then((_) => _afterSave(null, note));
    }
  }

  Future<void> _afterSave(int? id, Note note) async {
    if (!mounted) return;

    setState(() => _noteParameter = id == null ? note : note.copy(id: id));
    showSnackBar(SAVED);
  }

  Future<void> _onDeleteClicked() async {
    Navigator.pop(context);

    if (!_isEditing) {
      showSnackBar(NOTE_DOESNT_EXIST_YET);
      return;
    }
    Navigator.pop(context);

    if (_noteParameter!.reminderType != null
        && await kernel.reminderManager.isReminderSet(_noteParameter!.id!))
      kernel.reminderManager.cancelReminder(
        _noteParameter!.id!,
        _noteParameter!.reminderType!,
        false
      );

    kernel.dbManager.deleteNote(_noteParameter!);
  }

  void _createReminders() => showModalBottomSheet(
    context: context,
    builder: (builder) => Column(
      children: [
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(ATTACH_NOTIFICATION),
          onTap: _attachNotification
        ),
        ListTile(
          title: const Text(TIMED_NOTIFICATION),
          onTap: _timedNotification
        ),
        ListTile(
          title: const Text(SCHEDULE_NOTIFICATION),
          onTap: _scheduleNotification
        )
      ],
    )
  );

  Future<void> _notificationChecker(ReminderType type, void Function(Note) onSuccess) async {
    Navigator.pop(context);
    Navigator.pop(context);

    if (_isEditing
        && await kernel.reminderManager.isReminderSet(_noteParameter!.id!)) {
      showSnackBar(REMINDER_IS_SET);
      return;
    }

    List<String>? texts = _getTextsOrNull();
    if (texts == null) return;

    onSuccess(Note(
      id: _noteParameter?.id,
      title: texts[0],
      text: texts[1],
      reminderType: type,
      color: _getColor()
    ));
  }

  void _attachNotification() => _notificationChecker(ReminderType.ATTACHED, (note) =>
      kernel.reminderManager
          .createOrUpdateReminder(note, null, null)
          .then((id) => _afterSave(id, note))
  );

  void _timedNotification() => _notificationChecker(ReminderType.TIMED, (note) =>
      _pickDateTime(true, (millis) => kernel.reminderManager
          .createOrUpdateReminder(note, millis, null)
          .then((id) => _afterSave(id, note)), _onCancel)
      );

  void _scheduleNotification() => _notificationChecker(ReminderType.SCHEDULED,
      (note) => _pickDateTime(false, (initial) => _pickPeriod(
              (period) => kernel.reminderManager
                  .createOrUpdateReminder(note, initial, period)
                  .then((id) => _afterSave(id, note)),
              _onCancel
      ), _onCancel)
  );

  void _onCancel() => showSnackBar(CANCELED);

  void _removeReminder() {
    Navigator.pop(context);

    if (!_isEditing) {
      showSnackBar(REMINDER_IS_NOT_SET);
      return;
    }

    kernel.reminderManager.cancelReminder(
      _noteParameter!.id!,
      _noteParameter!.reminderType!,
      true
    );

    _afterSave(null, _noteParameter!.copy(reminderType: null));
  }

  void _pickDateTime(bool timed, void Function(int millis) onSuccess, void Function() onFailure) {
    final initTime = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: initTime,
      firstDate: initTime,
      lastDate: initTime.add(const Duration(days: 365)),
      helpText: timed ? CHOOSE_DATE : CHOOSE_DATE_2
    ).then((date) =>
      showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initTime),
        helpText: timed ? CHOOSE_TIME : CHOOSE_TIME_2
      ).then((time) {
        if (date == null || time == null) {
          onFailure();
          return;
        }
        Timer.run(() => onSuccess(date.add(Duration(
          hours: time.hour,
          minutes: time.minute
        )).millisecondsSinceEpoch));
      })
    );
  }

  void _pickPeriod(
    void Function(int millis) onSuccess,
    void Function() onFailure
  ) => showDialog(
    context: context,
    builder: (context) => PeriodPickerDialog(onSuccess, onFailure)
  );

  void _onMenuClicked() => kernel
      .reminderManager
      .getTimedReminderDetails(_noteParameter?.id)
      .then((details) => showModalBottomSheet(
        context: context,
          builder: (builder) => Column(
            children: [
              makeDividerForBottomSheet(),
              ListTile(
                title: const Text(DETAILS),
                subtitle: Text(details ?? TIMED_IS_NOT_SET),
              ),
              ListTile(
                title: const Text(DELETE),
                onTap: _onDeleteClicked
              ),
              ListTile(
                title: const Text(CREATE_REMINDER),
                onTap: _createReminders
              ),
              ListTile(
                title: const Text(REMOVE_REMINDER),
                onTap: _removeReminder,
              ),
              ListTile(
                title: const Text(CHOOSE_COLOR),
                onTap: _chooseColor,
              ),
              ListTile(
                title: const Text(SEND),
                onTap: _send,
              )
            ],
          )
      ));

  Future<void> _send() async => kernel.interop.callKotlinMethod(
      _SEND_METHOD, [_titleController.text, _textController.text]
  );

  NoteColor? _getColor() => _color == null
      ? _noteParameter?.color
      : _color == NoteColor.NONE ? null : _color;

  void _setColor(NoteColor? color) {
    Navigator.pop(context);
    Navigator.pop(context);
    _color = color;
    showSnackBar(COLOR_SET);
  }

  Row _makeRowOfColorAndText(Color color, String text, bool reversed) {
    final list = [
      Padding(
        padding: !reversed
            ? const EdgeInsets.only(right: 10)
            : const EdgeInsets.only(left: 10),
        child: SizedBox(
          width: 25,
          height: 25,
          child: ColoredBox(color: color)
        ),
      ),
      Text(text)
    ];
    return Row(children: reversed
        ? list.reversed.toList(growable: false)
        : list);
  }

  void _chooseColor() => showModalBottomSheet(
    context: context,
    builder: (context) => ListView(
      children: [
        makeDividerForBottomSheet(),
        ListTile(title: _makeRowOfColorAndText(
          _noteParameter?.color?.value != null
              ? Color(_noteParameter!.color!.value!)
              : Colors.transparent,
          CURRENT_COLOR,
          true
        )),
        makeDividerForBottomSheet(),
        ...NoteColor.values.map((noteColor) => ListTile(
          title: _makeRowOfColorAndText(
            noteColor.value != null ? Color(noteColor.value!) : Colors.transparent,
            noteColor.name,
            false
          ),
          onTap: () => _setColor(noteColor),
        ))
      ],
    )
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments;

    if ((arguments is! Note?) && (arguments is! List<String>))
      throw ArgumentError(EMPTY_STRING);

    if (arguments is Note?)
      _noteParameter = arguments;

    _titleController = TextEditingController();
    _titleController.text = _noteParameter?.title ?? EMPTY_STRING;

    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
    _textController.text = _noteParameter?.text ?? EMPTY_STRING;

    if (arguments is List<String>)
      _handleSendText(arguments[0], arguments[1]);
  }

  void _handleSendText(String title, String text) {
    _titleController.text = title;
    _textController.text = text;
  }

  void _onTextChanged() {
    if (!_isEditing)
      _titleController.text = _textController.text;
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();

    _textController.dispose();
    _textController.removeListener(_onTextChanged);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          onPressed: _onSaveClicked,
          icon: const Icon(
            Icons.save,
            color: Colors.white70
          ),
        ),
        IconButton(
          onPressed: _onMenuClicked,
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white70
          )
        )
      ],
      title: SizedBox(
        child: TextFormField(
          keyboardType: TextInputType.text,
          maxLines: 1,
          cursorColor: Colors.white70,
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: TITLE_STRING,
            hintStyle: TextStyle(color: Colors.white38)
          ),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20
          ),
        )
      )
    ),
    body: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Expanded(
            child: TextFormField(
              style: const TextStyle(fontSize: 20),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              expands: true,
              controller: _textController,
              autofocus: !_isEditing,
              decoration: const InputDecoration(hintText: TEXT_STRING),
            )
          )
        ],
      ),
    )
  );
}
