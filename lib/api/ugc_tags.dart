/// Readers for the `<ugc:id>` references embedded in message text.
///
/// These are deliberately free of Flutter imports: the notification stack and
/// the chat list both need to turn a reference into a readable label, and
/// neither of them has a widget tree to do it in. The rendering widgets build
/// on top of this in `widgets/ugc.dart`.
library;

/// Matches a UGC reference embedded in message text: `<ugc:123>`.
///
/// The id is the server id of one UGC item. A message may carry any number of
/// them, on their own or mixed with ordinary text, which is why the tag is part
/// of the text rather than a separate attachment field: it survives an edit, a
/// forward and a copy the way any other character does.
///
/// A tag preceded by a backslash -- `\<ugc:123>` -- is not a reference: the
/// author asked for the literal text, so the lookbehind keeps it out of every
/// reader below.
final RegExp ugcTagPattern = RegExp(r'(?<!\\)<ugc:(\d+)>');

/// Matches an escaped reference, `\<ugc:123>`, backslash included.
final RegExp ugcEscapedTagPattern = RegExp(r'\\<ugc:\d+>');

/// Whether [text] lets a UGC reference stand through the backslash escape.
///
/// Used by the renderers, which consume the backslash before the tag reaches
/// the pattern above and so have to honour the escape where they see it.
bool startsEscapedUgcTag(String text, int index) =>
    ugcEscapedTagPattern.matchAsPrefix(text, index) != null;

/// Every item id referenced by [text], in the order they appear.
List<int> parseUgcIds(String text) => [
  for (final match in ugcTagPattern.allMatches(text))
    ?int.tryParse(match.group(1)!),
];

/// Whether [text] refers to at least one UGC item.
bool containsUgc(String text) => ugcTagPattern.hasMatch(text);

/// Whether [text] is nothing but UGC references and whitespace.
///
/// Such a message is a sticker drop, not a line of text, so the chat draws it
/// without a bubble behind it.
bool isUgcOnly(String text) {
  if (!ugcTagPattern.hasMatch(text)) return false;
  return text.replaceAll(ugcTagPattern, '').trim().isEmpty;
}

/// A one-line stand-in for [text] with the UGC references removed.
///
/// Used where a message is shown as a label rather than rendered -- the chat
/// list preview and a notification body -- so `<ugc:4>` never reaches the user
/// as raw markup. An escaped tag is literal text and stays, minus the
/// backslash that asked for it. A message that was only a reference becomes
/// [placeholder], which the caller localizes.
String ugcPreviewText(String text, String placeholder) {
  // An escaped tag is literal text, so only the unescaped references are
  // stripped; the backslash that asked for a literal is dropped afterwards,
  // leaving the tag itself on show.
  String unescape(String value) => value.replaceAllMapped(
    ugcEscapedTagPattern,
    (match) => match[0]!.substring(1),
  );
  if (!ugcTagPattern.hasMatch(text)) return unescape(text);
  final stripped = unescape(text.replaceAll(ugcTagPattern, '')).trim();
  return stripped.isEmpty ? placeholder : stripped;
}
