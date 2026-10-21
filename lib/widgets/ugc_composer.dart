import 'dart:ui' as ui;

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'package:qutty/widgets/ugc.dart';

/// Builds the inline spans the composer draws while a message is written.
///
/// A plain [TextField] can only lay out characters, so the composer is an
/// [ExtendedTextField], which asks this builder for the span behind each run
/// of text. An unescaped `<ugc:id>` becomes the item's image at
/// [kUgcEmojiSize]; an escaped `\<ugc:id>` becomes the literal tag text, the
/// backslash consumed the way the markdown renderer consumes it.
///
/// The spans carry the raw text and their offset ([ExtendedWidgetSpan.start]
/// and [SpecialTextSpan.actualText]), which is what lets the caret, a
/// selection and a backspace behave as if the tag were still plain text.
class UgcComposerSpanBuilder extends RegExpSpecialTextSpanBuilder {
  UgcComposerSpanBuilder();

  @override
  List<RegExpSpecialText> get regExps => [_UgcSpecialText()];
}

class _UgcSpecialText extends RegExpSpecialText {
  _UgcSpecialText();

  /// An optional backslash followed by a reference. The escape is matched too
  /// so that it can be honoured here rather than drawn as an emoji.
  @override
  RegExp get regExp => RegExp(r'\\?<ugc:\d+>');

  @override
  InlineSpan finishText(
    int start,
    Match match, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    final raw = match[0]!;
    if (raw.startsWith(r'\')) {
      return SpecialTextSpan(
        text: raw.substring(1),
        actualText: raw,
        start: start,
        style: textStyle,
      );
    }
    final id = int.tryParse(ugcTagPattern.firstMatch(raw)!.group(1)!);
    if (id == null) {
      return TextSpan(text: raw, style: textStyle);
    }
    return ExtendedWidgetSpan(
      actualText: raw,
      start: start,
      alignment: ui.PlaceholderAlignment.middle,
      child: UgcView(id: id, size: kUgcEmojiSize),
    );
  }
}
