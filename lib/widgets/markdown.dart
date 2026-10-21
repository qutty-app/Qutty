import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:qutty/api/ugc_tags.dart';

final RegExp _linkifyPattern = RegExp(
  r'(?:qutty://(?:join|sticker)/\S+|(?:https?://)?(?:qutty\.app/(?:invite|sticker)|invite\.qutty)/\S+|https?://\S+|www\.\S+|@\w+)',
);
const String _linkJunk = '.,!?;:)"\']';

class MessageMarkdown extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final ValueChanged<String> onTap;

  /// Builds the inline widget for a `<ugc:id>` reference, or null to leave the
  /// tag as plain text.
  ///
  /// The markdown parser does not know what a UGC item is; it only knows where
  /// the reference sits among the text, so the caller supplies the image and
  /// the parser drops it in as a widget span that wraps with the line.
  final Widget Function(int id)? ugcBuilder;

  const MessageMarkdown({
    super.key,
    required this.text,
    this.style,
    required this.onTap,
    this.ugcBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = style ?? DefaultTextStyle.of(context).style;
    final ctx = _MdContext(
      scheme: scheme,
      base: base,
      onTap: onTap,
      ugcBuilder: ugcBuilder,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseBlocks(text, ctx),
    );
  }
}

class _MdContext {
  final ColorScheme scheme;
  final TextStyle base;
  final TextStyle linkStyle;
  final TextStyle inlineCodeStyle;
  final ValueChanged<String> onTap;
  final Widget Function(int id)? ugcBuilder;
  _MdContext({
    required this.scheme,
    required this.base,
    required this.onTap,
    this.ugcBuilder,
  }) : linkStyle = base.copyWith(
         color: scheme.primary,
         decoration: TextDecoration.underline,
       ),
       inlineCodeStyle = base.copyWith(
         color: scheme.onSurfaceVariant,
         fontFamily: 'monospace',
       );
}

List<Widget> _parseBlocks(String text, _MdContext ctx) {
  final lines = text.split('\n');
  final blocks = <Widget>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimLeft();

    if (trimmed.startsWith('```')) {
      final buffer = <String>[];
      i++;
      while (i < lines.length && !lines[i].startsWith('```')) {
        buffer.add(lines[i]);
        i++;
      }
      if (i < lines.length) i++;
      blocks.add(_codeBlock(ctx, buffer.join('\n')));
      continue;
    }

    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (heading != null) {
      blocks.add(_heading(ctx, heading.group(1)!.length, heading.group(2)!));
      i++;
      continue;
    }

    if (RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$').hasMatch(line)) {
      blocks.add(_rule(ctx));
      i++;
      continue;
    }

    if (trimmed.isEmpty) {
      i++;
      continue;
    }

    if (line.startsWith('>')) {
      final buffer = <String>[];
      while (i < lines.length && lines[i].startsWith('>')) {
        buffer.add(lines[i].substring(1).replaceFirst(RegExp(r'^\s'), ''));
        i++;
      }
      blocks.add(_quote(ctx, buffer.join(' ')));
      continue;
    }

    final listItem = RegExp(r'^(\s*)([-*+]|\d+[.)])\s+(.*)$').firstMatch(line);
    if (listItem != null) {
      final items = <String>[];
      final ordered = RegExp(r'^\d+[.)]').hasMatch(listItem.group(2)!);
      while (i < lines.length) {
        final match = RegExp(
          r'^(\s*)([-*+]|\d+[.)])\s+(.*)$',
        ).firstMatch(lines[i]);
        if (match == null) break;
        items.add(match.group(3)!);
        i++;
      }
      blocks.add(_list(ctx, items, ordered: ordered));
      continue;
    }

    final buffer = <String>[];
    while (i < lines.length && lines[i].trim().isNotEmpty) {
      final current = lines[i];
      if (current.startsWith('```') ||
          current.startsWith('>') ||
          RegExp(r'^\s*(#{1,6})\s+').hasMatch(current) ||
          RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$').hasMatch(current) ||
          RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+').hasMatch(current)) {
        break;
      }
      buffer.add(current.trim());
      i++;
    }
    blocks.add(_paragraph(ctx, buffer.join(' ')));
  }
  if (blocks.isEmpty) blocks.add(_paragraph(ctx, text));
  return blocks;
}

Widget _paragraph(_MdContext ctx, String content) {
  final style = ctx.base;
  return Text.rich(
    TextSpan(style: style, children: _parseInline(content, style, ctx)),
  );
}

Widget _heading(_MdContext ctx, int level, String content) {
  final size = switch (level) {
    1 => 24.0,
    2 => 21.0,
    3 => 18.0,
    4 => 16.0,
    5 => 14.0,
    _ => 12.0,
  };
  final style = ctx.base.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text.rich(
      TextSpan(style: style, children: _parseInline(content, style, ctx)),
    ),
  );
}

Widget _codeBlock(_MdContext ctx, String code) {
  final style = ctx.base.copyWith(
    color: ctx.scheme.onSurface,
    fontFamily: 'monospace',
    fontSize: (ctx.base.fontSize ?? 14) - 1,
  );
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ctx.scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(code, style: style),
    ),
  );
}

Widget _quote(_MdContext ctx, String content) {
  final style = ctx.base.copyWith(fontStyle: FontStyle.italic);
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: ctx.scheme.primary, width: 3)),
    ),
    child: Text.rich(
      TextSpan(style: style, children: _parseInline(content, style, ctx)),
    ),
  );
}

Widget _list(_MdContext ctx, List<String> items, {required bool ordered}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                child: Text(ordered ? '${i + 1}.' : '•', style: ctx.base),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: ctx.base,
                    children: _parseInline(items[i], ctx.base, ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _rule(_MdContext ctx) => Container(
  height: 1,
  margin: const EdgeInsets.symmetric(vertical: 8),
  color: ctx.scheme.outlineVariant,
);

List<InlineSpan> _parseInline(String text, TextStyle style, _MdContext ctx) {
  final spans = <InlineSpan>[];
  final plain = StringBuffer();
  void flushPlain() {
    if (plain.isEmpty) return;
    spans.addAll(_linkify(plain.toString(), style, ctx));
    plain.clear();
  }

  var i = 0;
  while (i < text.length) {
    int? next;
    String? open;
    for (final marker in const ['**', '__', '~~', '`', '[', '\\', '*', '_']) {
      final index = text.indexOf(marker, i);
      if (index != -1 && (next == null || index < next)) {
        next = index;
        open = marker;
      }
    }
    if (next == null) {
      plain.write(text.substring(i));
      break;
    }
    if (next > i) plain.write(text.substring(i, next));
    i = next;
    final marker = open!;

    if (marker == '\\') {
      // An escaped UGC tag is literal text: the backslash is the author's ask
      // for the tag itself rather than the item, so the whole tag leaves here
      // as one span and never reaches the linkifier that would resolve it.
      final escaped = startsEscapedUgcTag(text, i)
          ? ugcEscapedTagPattern.matchAsPrefix(text, i)![0]!
          : null;
      if (escaped != null) {
        flushPlain();
        spans.add(TextSpan(text: escaped.substring(1), style: style));
        i += escaped.length; // Match includes the backslash.
      } else if (i + 1 < text.length) {
        plain.write(text[i + 1]);
        i += 2;
      } else {
        plain.write('\\');
        i++;
      }
    } else if (marker == '`') {
      final close = text.indexOf('`', i + 1);
      if (close != -1) {
        flushPlain();
        spans.add(
          TextSpan(
            text: text.substring(i + 1, close),
            style: ctx.inlineCodeStyle,
          ),
        );
        i = close + 1;
      } else {
        plain.write('`');
        i++;
      }
    } else if (marker == '**' || marker == '__') {
      final close = text.indexOf(marker, i + 2);
      if (close != -1) {
        final inner = style.copyWith(fontWeight: FontWeight.bold);
        flushPlain();
        spans.add(
          TextSpan(
            style: inner,
            children: _parseInline(text.substring(i + 2, close), inner, ctx),
          ),
        );
        i = close + 2;
      } else {
        plain.write(marker);
        i += 2;
      }
    } else if (marker == '~~') {
      final close = text.indexOf('~~', i + 2);
      if (close != -1) {
        final inner = style.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: style.color,
        );
        flushPlain();
        spans.add(
          TextSpan(
            style: inner,
            children: _parseInline(text.substring(i + 2, close), inner, ctx),
          ),
        );
        i = close + 2;
      } else {
        plain.write('~~');
        i += 2;
      }
    } else if (marker == '*' || marker == '_') {
      final close = text.indexOf(marker, i + 1);
      if (close != -1) {
        final inner = style.copyWith(fontStyle: FontStyle.italic);
        flushPlain();
        spans.add(
          TextSpan(
            style: inner,
            children: _parseInline(text.substring(i + 1, close), inner, ctx),
          ),
        );
        i = close + 1;
      } else {
        plain.write(marker);
        i++;
      }
    } else if (marker == '[') {
      final link = _parseLink(text, i);
      if (link != null) {
        flushPlain();
        spans.add(_linkSpan(ctx, link.label, link.url));
        i = link.end;
      } else {
        plain.write('[');
        i++;
      }
    } else {
      plain.write(marker);
      i += marker.length;
    }
  }
  flushPlain();
  return spans;
}

({String label, String url, int end})? _parseLink(String text, int start) {
  final close = text.indexOf(']', start + 1);
  if (close == -1 || close + 1 >= text.length || text[close + 1] != '(') {
    return null;
  }
  final closeParen = text.indexOf(')', close + 2);
  if (closeParen == -1) return null;
  final label = text.substring(start + 1, close);
  final url = text.substring(close + 2, closeParen);
  if (label.trim().isEmpty || url.trim().isEmpty) return null;
  return (label: label, url: url.trim(), end: closeParen + 1);
}

InlineSpan _linkSpan(_MdContext ctx, String label, String url) => TextSpan(
  style: ctx.linkStyle,
  recognizer: TapGestureRecognizer()..onTap = () => ctx.onTap(url),
  children: _parseInline(label, ctx.linkStyle, ctx),
);

List<InlineSpan> _linkify(String text, TextStyle style, _MdContext ctx) {
  final builder = ctx.ugcBuilder;
  if (builder == null || !ugcTagPattern.hasMatch(text)) {
    return _linkifyPlain(text, style, ctx);
  }
  // A UGC reference sits inline with the words around it, so the text is cut
  // into runs at each tag and the runs between them are linkified as usual.
  // Recursion in [_parseInline] means a tag inside bold or a link label lands
  // here too, so it renders wherever the author put it.
  final spans = <InlineSpan>[];
  var end = 0;
  for (final match in ugcTagPattern.allMatches(text)) {
    if (match.start > end) {
      spans.addAll(
        _linkifyPlain(text.substring(end, match.start), style, ctx),
      );
    }
    final id = int.tryParse(match.group(1)!);
    if (id != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: builder(id),
        ),
      );
    }
    end = match.end;
  }
  if (end < text.length) {
    spans.addAll(_linkifyPlain(text.substring(end), style, ctx));
  }
  return spans;
}

List<InlineSpan> _linkifyPlain(String text, TextStyle style, _MdContext ctx) {
  final spans = <InlineSpan>[];
  var end = 0;
  for (final match in _linkifyPattern.allMatches(text)) {
    final raw = match.group(0)!;
    var clean = raw.length;
    while (clean > 0 && _linkJunk.contains(raw[clean - 1])) {
      clean--;
    }
    if (clean == 0) continue;
    if (match.start > end) {
      spans.add(TextSpan(text: text.substring(end, match.start), style: style));
    }
    final value = raw.substring(0, clean);
    spans.add(
      TextSpan(
        text: value,
        style: ctx.linkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => ctx.onTap(value),
      ),
    );
    end = match.start + clean;
  }
  if (end < text.length) {
    spans.add(TextSpan(text: text.substring(end), style: style));
  }
  return spans;
}
