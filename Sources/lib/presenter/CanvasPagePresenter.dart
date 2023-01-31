/// Created by VadNiks on Aug 02 2022
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:notes_next_gen/model/database/NoteColor.dart';
import '../consts.dart';
import '../model/core/Interop.dart';
import '../model/database/Note.dart';
import '../model/tuples.dart';
import 'Presenters.dart';
import '../view/CanvasPage.dart';
import 'AbsPresenter.dart';
import 'package:meta/meta.dart';
import 'CanvasPainter.dart';
import 'paintInfo.dart';

@sealed
class CanvasPagePresenter extends AbsPresenter<CanvasPage> {
  NoteColor? _color; // brush color
  final List<Point> _currentPoints = [];
  double _opacity = 1;
  double _width = 20;
  final List<Pair<Path, PaintInfo>> _paths = [];
  Path? _currentPath;
  late final TextEditingController _controller;
  var _eraseMode = false;
  Note? _noteParameter;
  ui.Image? _image;
  var _noteColor = NoteColor.NONE; // color of the current note to be placed in the database
  static const _SAVE_BINARY_NOTE_METHOD = 'saveBinaryNote'; // TODO: create separate proxy class BinaryNoteManager and put constants & logic there
  static const _READ_BINARY_NOTE_METHOD = 'readBinaryNote';
  static const _DELETE_BINARY_NOTE_METHOD = 'deleteBinaryNote';

  CanvasPagePresenter(Object kernel) : super(kernel, Presenters.CANVAS);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() { // additionally executes every time a keyboard shows/closes, onResume analogue?
    super.didChangeDependencies();
    if (_color != null) return;

    // set default value only once within a single instance of this page
    _color = isLightTheme ? NoteColor.BLACK : NoteColor.WHITE; // cannot be placed in the initState cuz theme cannot be queried in it

    final arguments = super.arguments; // and this cannot be called from initState too cuz them all require context which isn't available until this method call
    if (arguments is! Note?) throw ArgumentError();
    _noteParameter = arguments;

    if (_noteParameter != null) {
      _controller.text = _noteParameter!.title;
      _noteColor = _noteParameter!.color ?? NoteColor.NONE;
      _load();
    }
  }

  Future<void> _load() async {
    if (_noteParameter == null) return;

    final Uint8List? bytes =
      await kernel.interop.callKotlinMethod(_READ_BINARY_NOTE_METHOD, _noteParameter!.toMap());
    if (bytes == null || !mounted) return;

    final size = screenSize;
    _image = (await (await ui.instantiateImageCodec(
      bytes,
      targetWidth: size.width.floor(),
      targetHeight: size.height.floor()
    )).getNextFrame()).image;

    updateState();
  }

  Future<void> _save() async { // TODO: lock device's orientation
    if (_controller.text.isEmpty) {
      showSnackBar(TEXTS_ARE_EMPTY);
      return;
    }

    final recorder = ui.PictureRecorder();
    final size = screenSize;

    CanvasPainter([], _paths, _image).paint(Canvas(recorder), size);

    final image = await recorder.endRecording().toImage(size.width.floor(), size.height.floor());
    final bytes = await (image).toByteData(format: ui.ImageByteFormat.png);

    if (_noteParameter != null && (_noteParameter!.text.isNotEmpty || !_noteParameter!.canvas))
      throw StateError(EMPTY_STRING);

    final note = _noteParameter?.copy(
      title: _controller.text,
      color: _noteColor
    ) ?? Note(
      title: _controller.text,
      text: EMPTY_STRING,
      color: _noteColor,
      canvas: true
    );

    final int? id = await kernel.interop.callKotlinMethod(_SAVE_BINARY_NOTE_METHOD, [ // TODO: move to DatabaseManager or to BinaryNoteManager
      note.toMap(),
      bytes!.buffer.asUint8List()
    ]);

    if (id != null) {
      _image = image;
      _noteParameter = note.copy(id: id);
      updateState();
    }

    showSnackBar(id == null ? ERROR_OCCURRED : SAVED);
  }

  List<DropdownMenuItem<NoteColor>> _makeColorItems(bool withoutNone) => [ // TODO: add ability to delete all canvas files from internal app storage
    for (final color in NoteColor.values)
      if (!withoutNone || color.value != null) DropdownMenuItem(
        value: color,
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              width: 25,
              height: 25,
              child: ColoredBox(color: color.value != null ? Color(color.value!) : Colors.transparent),
            ),
          ),
          Text(color.name)
        ])
      )
  ];

  void _showTimestamp() {
    navigator.pop();
    showSnackBar(kernel.makeTimeStamp(
      _noteParameter?.addMillis ?? 0,
      _noteParameter?.editMillis ?? 0
    ));
  }

  void _showMenu() => showModalBottomSheet(
    context: context,
    builder: (_) => StatefulBuilder(builder: (_, stateSetter) => SingleChildScrollView(child: Column(children: [
      makeDividerForBottomSheet(),
      ListTile(
        title: const Text(CURRENT_COLOR),
        trailing: DropdownButton<NoteColor>(
          value: _color,
          items: _makeColorItems(true),
          onChanged: (color) => stateSetter(() => _color = color ?? NoteColor.GRAY),
        ),
      ),
      ListTile(
        title: const Text(CURRENT_WIDTH),
        trailing: SizedBox(
          width: 200,
          height: 25,
          child: Slider(
            label: _width.toString(),
            min: 5,
            max: 100,
            value: _width,
            divisions: 19,
            onChanged: (value) => stateSetter(() => _width = value),
          ),
        ),
      ),
      ListTile(
        title: const Text(OPACITY),
        trailing: SizedBox(
          width: 200,
          height: 25,
          child: Slider(
            label: _opacity.toString(),
            value: _opacity,
            divisions: 20,
            onChanged: (value) => stateSetter(() => _opacity = value),
          ),
        ),
      ),
      ListTile(
        title: const Text(ERASE_MODE),
        trailing: Switch(
          value: _eraseMode,
          onChanged: (value) => stateSetter(() => _eraseMode = value),
        ),
      ),
      ListTile(
        title: const Text(CHOOSE_NOTE_COLOR),
        trailing: DropdownButton<NoteColor>(
          value: _noteColor,
          items: _makeColorItems(false),
          onChanged: (color) {
            _noteColor = color ?? NoteColor.NONE;
            stateSetter((){});
          },
        ),
      ),
      ListTile(
        title: const Text(CREATED_UPDATED_AT),
        onTap: _showTimestamp,
      ),
      ListTile(
        title: const Text(DELETE),
        onTap: () {
          if (_noteParameter != null) {
            navigator.pop();
            kernel.interop.callKotlinMethod(_DELETE_BINARY_NOTE_METHOD, _noteParameter!.toMap())
              .then((successful) { if (successful) navigator.pop(); });
          }
        },
      ),
      ListTile(
        title: const Text(EXPORT_TO_FILE),
        onTap: () {
          if (_noteParameter == null) return;
          navigator.pop();
          kernel.interop.callKotlinMethod(Interop.SEND_METHOD, [_noteParameter!.title, null, _noteParameter!.id]);
        },
      )
    ])))
  ).then((_) => updateState());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: SizedBox(child: TextFormField(
        keyboardType: TextInputType.text,
        maxLines: 1,
        cursorColor: Colors.white70,
        controller: _controller,
        decoration: const InputDecoration(
          hintText: TITLE_STRING,
          hintStyle: TextStyle(color: Colors.white38)
        ),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 20
        ),
      )),
      actions: [
        IconButton(
          onPressed: _save,
          icon: const Icon(
            Icons.save,
            color: Colors.white70,
          )
        ),
        IconButton(
          onPressed: _showMenu,
          icon: const Icon(
            Icons.more_vert,
            color: Colors.white70,
          ),
        )
      ],
    ),
    body: GestureDetector(
      onPanDown: (details) {
        final pos = details.localPosition;
        _currentPoints.add(Point(pos.dx, pos.dy, _color!, _opacity, _width, _eraseMode));
        (_currentPath = Path()).moveTo(pos.dx, pos.dy);
        updateState();
      },
      onPanUpdate: (details) {
        final pos = details.localPosition;
        _currentPoints.add(Point(pos.dx, pos.dy, _color!, _opacity, _width, _eraseMode));
        _currentPath!.lineTo(pos.dx, pos.dy);
        updateState();
      },
      onPanEnd: (_) {
        _paths.add(Pair(_currentPath!, PaintInfo(_color!, _opacity, _width, _eraseMode)));
        _currentPoints.clear();
        updateState();
      },
      child: RepaintBoundary(child: CustomPaint(
        size: screenSize,
        painter: CanvasPainter(_currentPoints, _paths, _image))
      )
    ),
  );
}
