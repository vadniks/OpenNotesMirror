/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'spannableTextEditingController.dart';
import '../model/database/NoteColor.dart';
import 'Presenters.dart';
import '../model/database/Note.dart';
import '../model/reminders/ReminderType.dart';
import '../view/EditPage.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';
import '../consts.dart';

@sealed
class EditPagePresenter extends AbsPresenter<EditPage> {
  late TextEditingController _titleController;
  late SpannableTextEditingController _textController;
  Note? _noteParameter;
  NoteColor? _color;
  static const _SEND_METHOD = 'send';
  static const _SAVE_STATE_METHOD = 'saveState';
  static const _RESET_STATE_METHOD = 'resetState';
  var _chosenTriggerDate = DateTime.fromMillisecondsSinceEpoch(0);
  var _chosenTriggerTime = const TimeOfDay(hour: 0, minute: 0);
  var _chosenPeriodDays = 0;
  var _chosenPeriodHours = 0;
  var _chosenPeriodMinutes = 0;
  bool get _isEditing => _noteParameter != null;
  String get _title => _titleController.text;
  String get _text => _textController.text;
  var _canPostNotifications = false;

  EditPagePresenter(Object kernel) : super(kernel, Presenters.EDIT);

  Future<void> _onSaveClicked() async {
    if (_title.isEmpty || _text.isEmpty) {
      showSnackBar(TEXTS_ARE_EMPTY);
      return;
    }

    var note = await _makeNote(null);

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

  Future<void> _afterSave(int? id, Note note, [DateTime? trigger]) async {
    if (!mounted) return;
    setState(() => _noteParameter = id == null ? note : note.copy(id: id));
    showSnackBar(SAVED + (trigger != null ? NOTIFICATION_WILL_APPEAR_AT + trigger.toString() : ''));
  }

  Future<void> _onDeleteClicked() async {
    navigator.pop();

    if (!_isEditing) {
      showSnackBar(NOTE_DOESNT_EXIST_YET);
      return;
    }
    navigator.pop();

    if (_noteParameter!.reminderType != null
      && await kernel.reminderManager.isReminderSet(_noteParameter!.id!))
      kernel.reminderManager.cancelReminder(
        _noteParameter!.id!,
        _noteParameter!.reminderType!,
        false
      );

    kernel.dbManager.deleteNote(_noteParameter!);
  }

  Future<void> _createReminders() async {
    if (_isEditing && await kernel.reminderManager.isReminderSet(_noteParameter!.id!)) {
      navigator.pop();
      showSnackBar(REMINDER_IS_SET);
      return;
    }
    if (_title.isEmpty || _text.isEmpty) {
      showSnackBar(TEXTS_ARE_EMPTY);
      navigator.pop();
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (builder) => Column(children: [
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
      ])
    );
  }

  Future<Note> _makeNote(ReminderType? type) async => Note(
    id: _noteParameter?.id,
    title: _title,
    text: _text,
    reminderType: type,
    color: _getColor(),
    spans: await _textController.serialize()
  );

  Future<void> _attachNotification() async {
    popTimes(2);

    final note = await _makeNote(ReminderType.ATTACHED);
    kernel.reminderManager
      .createOrUpdateReminder(note, null, null)
      .then((id) => _afterSave(id, note));
  }

  Future<void> _timedNotification() async {
    popTimes(2);

    final note = await _makeNote(ReminderType.TIMED);
    _pickDate(CHOOSE_DATE, (date) =>
      _pickTime(CHOOSE_TIME, (time) {
        if (date == null || time == null) {
          showSnackBar(CANCELED);
          return;
        }

        final trigger = date.add(Duration(
            hours: time.hour,
            minutes: time.minute
        ));

        if (trigger.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch < 1000 * 60) {
          showSnackBar(INCORRECT_DATE_OR_TIME);
          return;
        }
        kernel.reminderManager
          .createOrUpdateReminder(note, trigger.millisecondsSinceEpoch, null)
          .then((id) => _afterSave(id, note, trigger));
      })
    );
  }

  void _pickDate(String helpText, void Function(DateTime?) callback) {
    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: helpText
    ).then((date) => callback(date));
  }

  void _pickTime(String helpText, void Function(TimeOfDay?) callback) {
    final now = TimeOfDay.now();
    showTimePicker(
      context: context,
      initialTime: now,
      helpText: helpText
    ).then((time) => callback(time));
  }

  int _calcTrigger() => Duration(
    milliseconds: _chosenTriggerDate.millisecondsSinceEpoch,
    hours: _chosenTriggerTime.hour,
    minutes: _chosenTriggerTime.minute
  ).inMilliseconds;

  int _calcPeriod() => Duration(
    days: _chosenPeriodDays,
    hours: _chosenPeriodHours,
    minutes: _chosenPeriodMinutes
  ).inMilliseconds;

  Future<void> _doScheduleNotification() async {
    final trigger = _calcTrigger();
    final period = _calcPeriod();
    final now = DateTime.now().millisecondsSinceEpoch;
    const minute = 1000 * 60;

    if (trigger - now < minute || period - minute < 0) {
      showSnackBar(INCORRECT_TRIGGER_OR_PERIOD);
      return;
    }

    popTimes(3);

    final note = await _makeNote(ReminderType.SCHEDULED);
    kernel.reminderManager
      .createOrUpdateReminder(note, trigger, period)
      .then((id) => _afterSave(id, note));
  }

  void _scheduleNotification() => showModalBottomSheet( // TODO: put reminder setting logic into ReminderManager or into a separate class
    context: context,
    builder: (_) => StatefulBuilder(builder: (_, stateSetter) {
      final tdt = DateTime.fromMillisecondsSinceEpoch(_calcTrigger()),
        triggerDate = tdt.millisecondsSinceEpoch == 0 ? NOT_SET : '${tdt.month}-${tdt.day}-${tdt.year}',
        triggerTime = tdt.millisecondsSinceEpoch == 0 ? NOT_SET : '${tdt.hour}:${tdt.minute}';

      return Column(children: [
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(
            SCHEDULE_NOTIFICATION,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TextButton(
            onPressed: _doScheduleNotification,
            child: const Text(
              DONE,
              style: TextStyle(fontSize: 16)
            )
          )
        ),
        makeDividerForBottomSheet(),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(TRIGGER_DATE),
              Text(triggerDate)
            ]
          ),
          onTap: () => _pickDate(
            CHOOSE_DATE,
            (date) => stateSetter(() { if (date != null) _chosenTriggerDate = date; })
          ),
        ),
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(TRIGGER_TIME),
              Text(triggerTime)
            ]
          ),
          onTap: () => _pickTime(
            CHOOSE_TIME,
            (time) => stateSetter(() { if (time != null) _chosenTriggerTime = time; })
          ),
        ),
        ListTile(title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(PERIOD_DAYS),
            DropdownButton<int>(
              value: _chosenPeriodDays,
              items: [for (var i = 0; i <= 31; i++) DropdownMenuItem(
                value: i,
                child: Text(i.toString()),
              )],
              onChanged: (days) => stateSetter(() { if (days != null) _chosenPeriodDays = days; })
            )
          ]
        )),
        ListTile(title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(PERIOD_HOURS),
            DropdownButton<int>(
              value: _chosenPeriodHours,
              items: [for (var i = 0; i <= 24; i++) DropdownMenuItem(
                value: i,
                child: Text(i.toString()),
              )],
              onChanged: (hours) => stateSetter(() { if (hours != null) _chosenPeriodHours = hours; })
            )
          ]
        )),
        ListTile(title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(PERIOD_MINUTES),
            DropdownButton<int>(
              value: _chosenPeriodMinutes,
              items: [for (var i = 0; i <= 60; i++) DropdownMenuItem(
                value: i,
                child: Text(i.toString()),
              )],
              onChanged: (minutes) => stateSetter(() { if (minutes != null) _chosenPeriodMinutes = minutes; })
            )
          ]
        ))
      ]);
    })
  );

  void _removeReminder() {
    navigator.pop();

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

  void _onMenuClicked() => kernel
    .reminderManager
    .getReminderDetails(_noteParameter?.id)
    .then((details) => showModalBottomSheet(
      context: context,
      builder: (builder) => SingleChildScrollView(child: Column(children: [
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(DETAILS),
          subtitle: Text(
            details ?? TIMED_OR_SCHEDULED_IS_NOT_SET,
            textAlign: TextAlign.justify
          )
        ),
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(DELETE),
          onTap: _onDeleteClicked
        ),
        ListTile(
          title: const Text(CREATE_REMINDER),
          onTap: _canPostNotifications ? _createReminders : null
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
        ),
        ListTile(
          title: const Text(CREATED_UPDATED_AT),
          onTap: _noteParameter == null ? null : _showTimestamp,
        ),
        ListTile(
          title: const Text(DECORATE_SELECTED_TEXT),
          onTap: _decorateSelectedText,
        )
      ]))
    ));

  Future<void> _decorateSelectedText() async {
    if (_textController.selection.isCollapsed) {
      navigator.pop();
      showSnackBar(NOTHING_SELECTED);
      return;
    }

    var style = FontStyleExtended.NORMAL, color = NoteColor.NONE;

    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (_, stateSetter) => Column(children: [
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(DECORATE_SELECTED_TEXT),
          trailing: TextButton(
            onPressed: () {
              popTimes(2);
              _textController.setSpan(style, color);
            },
            child: const Text(DONE)
          ),
        ),
        makeDividerForBottomSheet(),
        ListTile(
          title: const Text(FONT_STYLE),
          trailing: DropdownButton<FontStyleExtended>(
            value: style,
            items: FontStyleExtended.values.map((element) => DropdownMenuItem(
              value: element,
              child: Text(
                element.name,
                style: TextStyle(
                  fontStyle: element.style,
                  fontWeight: element.weight
                ),
              )
            )).toList(),
            onChanged: (chosen) => stateSetter(() => style = chosen ?? FontStyleExtended.NORMAL),
          ),
        ),
        ListTile(
          title: const Text(FONT_COLOR),
          trailing: DropdownButton<NoteColor>(
            value: color,
            items: [for (final element in NoteColor.values)
              if (element != NoteColor.BLACK && element != NoteColor.WHITE)
                DropdownMenuItem(
                  value: element,
                  child: Text(
                    element.name,
                    style: TextStyle(color: element.value == null ? null : Color(element.value!))
                  )
                )
            ].toList(),
            onChanged: (chosen) => stateSetter(() => color = chosen ?? NoteColor.NONE),
          ),
        ),
        ListTile(
          title: const Text(RESET_ALL),
          onTap: () {
            _textController.clearSpans();
            popTimes(2);
          },
        )
      ]))
    );
  }

  void _showTimestamp() {
    navigator.pop();

    final added = _noteParameter!.addMillis,
      edited = _noteParameter!.editMillis;

    showSnackBar(
      '$ADDED_AT ${added < 1000
        ? JUST_NOW
        : DateTime.fromMillisecondsSinceEpoch(added)}\n'
      '$EDITED_AT ${edited < 1000
        ? JUST_NOW
        : DateTime.fromMillisecondsSinceEpoch(edited)}'
    );
  }

  Future<void> _send() async => kernel.interop.callKotlinMethod(
    _SEND_METHOD, [_title, _text]
  );

  NoteColor? _getColor() => _color == null
    ? _noteParameter?.color
    : _color == NoteColor.NONE ? null : _color;

  void _setColor(NoteColor? color) {
    popTimes(2);
    _color = color;
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
    return Row(children: reversed ? list.reversed.toList(growable: false) : list);
  }

  void _chooseColor() => showModalBottomSheet(
    context: context,
    builder: (context) => ListView(children: [
      makeDividerForBottomSheet(),
      ListTile(
        title: _makeRowOfColorAndText(
          _noteParameter?.color?.value != null
            ? Color(_noteParameter!.color!.value!)
            : Colors.transparent,
          CURRENT_COLOR,
          true
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(COLOR_SET)
        ),
      ),
      makeDividerForBottomSheet(),
      ...NoteColor.values.map((noteColor) => ListTile(
        title: _makeRowOfColorAndText(
          noteColor.value != null ? Color(noteColor.value!) : Colors.transparent,
          noteColor.name,
          false
        ),
        onTap: () => _setColor(noteColor),
      ))
    ])
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments;

    if ((arguments is! Note?) && (arguments is! List<String>))
      throw ArgumentError(EMPTY_STRING);

    kernel.reminderManager
      .canPostNotifications()
      .then((value) => _canPostNotifications = value);

    if (arguments is Note?)
      _noteParameter = arguments;

    _titleController = TextEditingController();
    _titleController.text = _noteParameter?.title ?? EMPTY_STRING;

    _textController = SpannableTextEditingController(
      textColor,
      _noteParameter?.spans,
      _noteParameter?.text
    );
    _textController.addListener(_onTextChanged);
    _textController.text = _noteParameter?.text ?? EMPTY_STRING;

    if (_noteParameter != null && _noteParameter!.id == null)
      _noteParameter = null;

    if (arguments is List<String>)
      _handleSendText(arguments[0], arguments[1]);
  }

  void _handleSendText(String title, String text) {
    _titleController.text = title;
    _textController.text = text;
  }

  Future<void> _onTextChanged() async {
    if (!_isEditing) _titleController.text = _text.replaceAll('\n', ' ');

    try { await kernel.interop.callKotlinMethod(_SAVE_STATE_METHOD, Note(
      id: _noteParameter?.id,
      title: _title,
      text: _text,
      color: _getColor()
    ).toMap()); } catch (_) {} // ActivityPresenter removes requestProcessor when activity stops, in order to avoid throwing 'saveState method impl not found' when activity stops while keyboard is still shown
  }

  @override
  void dispose() {
    kernel.interop.callKotlinMethod(_RESET_STATE_METHOD, null);

    super.dispose();
    _titleController.dispose();

    _textController.dispose();
    _textController.removeListener(_onTextChanged);
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async {
      final title = _title;
      final text = _text;
      if (_noteParameter != null || title.isEmpty && text.isEmpty) return true;

      kernel.callMainPresenter((presenter) => presenter.showSnackBar(
        UNSAVED,
        actions: [Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IconButton(
            onPressed: () => presenter.handleSendText(title, text),
            icon: const Icon(
              Icons.edit,
              color: Colors.white70,
            ),
          ),
        )]
      ));
      return true;
    },
    child: _build(context)
  );

  Widget _build(BuildContext context) => Scaffold(
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
      title: SizedBox(child: TextFormField(
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
      ))
    ),
    body: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(children: [Expanded(child: TextFormField(
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 20),
        keyboardType: TextInputType.multiline,
        maxLines: null,
        expands: true,
        controller: _textController,
        autofocus: !_isEditing,
        decoration: const InputDecoration(hintText: TEXT_STRING),
        // selectionControls: , // TODO
      ))])
    )
  );
}
