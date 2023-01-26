/// Created by VadNiks on Jan 15 2023
/// Copyright (C) 2018-2023 Vad Nik (https://github.com/vadniks).
///
/// This is an open-source project, the repository is located at https://github.com/vadniks/OpenNotesMirror.
/// No license provided, so distribution, redistribution, modifying and/or commercial use of this code,
/// without author's written permission, are strongly prohibited.
///
/// Source codes are opened only for review.

// ignore_for_file: constant_identifier_names, curly_braces_in_flow_control_structures, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../model/database/NoteColor.dart';
import '../model/database/Span.dart';

enum FontStyleExtended { // TODO: move into Span.dart
  NORMAL('Normal', FontStyle.normal, FontWeight.normal, 0),
  BOLD('Bold', FontStyle.normal, FontWeight.bold, 1),
  ITALIC('Italic', FontStyle.italic, FontWeight.normal, 2),
  BOLD_ITALIC('Bold italic', FontStyle.italic, FontWeight.bold, 3);

  const FontStyleExtended(this.name, this.style, this.weight, this.id);
  final String name;
  final FontStyle style;
  final FontWeight weight;
  final int id;

  static FontStyleExtended? create(int? id) {
    if (id == null) return null;
    for (final i in FontStyleExtended.values)
      if (i.id == id) return i;
    return null;
  }
}

@sealed
class SpannableTextEditingController extends TextEditingController {
  final Color _baseTextColor;
  final List<TextSpan> _spans = [];
  var _hasDecoratedAnything = false;

  int get start => selection.start;
  int get end => selection.end;

  SpannableTextEditingController(this._baseTextColor, String? serializedSpans, String? _text)
  { if (serializedSpans != null && _text != null) _decompressSpans(serializedSpans, _text); }

  Future<void> _decompressSpans(String serializedSpans, String _text) async {
    final decompressed = <TextSpan>[];
    var lastPos = -1;

    for (final span in _deserialize(serializedSpans) ?? <Span>[]) {
      if (span.start > span.end || span.start <= lastPos) throw Exception();
      lastPos = span.end;

      for (var i = span.start; i <= span.end; i++)
        decompressed.add(_makeTextSpan(_text[i], span.style, span.color, _baseTextColor));
    }

    if (decompressed.isNotEmpty) {
      _hasDecoratedAnything = true;
      _spans.clear();
      _spans.addAll(decompressed);
      _clearSelection();
    }
  }

  List<Span>? _deserialize(String string) {
    final results = <Span>[];
    for (final rawSpan in string.split(';')) {
      final span = Span.fromString(rawSpan);
      if (span != null) results.add(span);
    }
    return results.isEmpty ? null : results;
  }

  Future<String?> serialize() async {
    if (!_hasDecoratedAnything) return null;
    final buffer = StringBuffer();

    for (final span in _compressSpans() ?? <Span>[]) {
      buffer.write(span.toString());
      buffer.write(';');
    }

    return buffer.isEmpty ? null : () {
      final serialized = buffer.toString();
      return serialized.substring(0, serialized.length - 1);
    } ();
  }

  void _checkInterval() { if (start > end || start < 0 || end < 0) throw Error(); }

  TextSpan _makeTextSpan(
    String char,
    FontStyleExtended style,
    NoteColor? color,
    Color baseColor
  ) => TextSpan(
    text: char,
    style: TextStyle(
      color: color?.value != null ? Color(color!.value!) : null,
      fontStyle: style.style,
      fontWeight: style.weight
    )
  );

  Span? _makeSpan(TextSpan span, int start, int end) {
    final isItalic = span.style?.fontStyle == FontStyle.italic,
      isBold = span.style?.fontWeight == FontWeight.bold,
      color = span.style?.color?.value;

    return Span(
      isItalic && isBold // beautify?
        ? FontStyleExtended.BOLD_ITALIC
        : isItalic
          ? FontStyleExtended.ITALIC
          : isBold
            ? FontStyleExtended.BOLD
            : FontStyleExtended.NORMAL,
      NoteColor.create(color != NoteColor.WHITE.value ? color : null),
      start,
      end
    );
  }

  List<Span>? _compressSpans() {
    final compressed = <Span>[];
    Span? lastSpan;
    var index = 0, lastAddedIndex = -1;

    tryUpdateEnd(int where, int replacement) =>
      lastAddedIndex > -1 ? compressed[where] = compressed[where].copy(end: replacement) : null;

    for (final span in _spans) {
      final previousIndex = index - 1,
        previous = previousIndex >= 0 ? _spans[previousIndex] : null;

      if (previous == null || (
        previous.style?.fontStyle != span.style?.fontStyle
        || previous.style?.fontWeight != span.style?.fontWeight
        || previous.style?.color != span.style?.color
      )) {
        tryUpdateEnd(lastAddedIndex, previousIndex);

        lastSpan = _makeSpan(span, index, -1);
        lastAddedIndex = compressed.length;
        compressed.add(lastSpan!);
      }
      index++;
    }

    tryUpdateEnd(lastAddedIndex, index - 1);
    return compressed.isEmpty ? null : compressed;
  }

  Future<void> setSpan(FontStyleExtended style, NoteColor color) async {
    _checkInterval();
    _hasDecoratedAnything = true;
    for (var i = start; i < end; i++)
      _spans.replaceRange(i, i + 1, [_makeTextSpan(text[i], style, color, _baseTextColor)]);
    _clearSelection();
  }

  void _clearSelection() => selection = const TextSelection(baseOffset: 0, extentOffset: 0); // and notify listeners so spans can be rebuilt

  Future<void> clearSpans() async {
    _hasDecoratedAnything = false;
    _spans.clear();
    _clearSelection();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing
  }) {
    final old = <TextSpan>[..._spans];
    var index = 0;

    _spans.clear();
    for (final char in text.characters) _spans.add(TextSpan(
      text: char,
      style: index < old.length ? old[index++].style : style
    ));

    return TextSpan(
      style: style,
      children: [..._spans]
    );
  }
}
