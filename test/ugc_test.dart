import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/ugc_tags.dart';
import 'package:qutty/widgets/markdown.dart';

void main() {
  group('parseUgcIds', () {
    test('reads every reference in order', () {
      expect(parseUgcIds('<ugc:1> and <ugc:22>'), [1, 22]);
    });

    test('ignores text with no reference', () {
      expect(parseUgcIds('just words'), isEmpty);
    });

    test('ignores a tag with a non-numeric id', () {
      // The pattern only matches digits, so a malformed tag stays as text
      // rather than resolving to some arbitrary item.
      expect(parseUgcIds('<ugc:abc>'), isEmpty);
      expect(ugcTagPattern.hasMatch('<ugc:abc>'), isFalse);
    });

    test('ignores a tag the author escaped', () {
      expect(parseUgcIds(r'\<ugc:1>'), isEmpty);
      expect(ugcTagPattern.hasMatch(r'\<ugc:1>'), isFalse);
    });
  });

  group('isUgcOnly', () {
    test('a lone reference is a sticker drop', () {
      expect(isUgcOnly('<ugc:3>'), isTrue);
    });

    test('several references with whitespace are still only references', () {
      expect(isUgcOnly(' <ugc:3> <ugc:4> '), isTrue);
    });

    test('text beside a reference keeps the bubble', () {
      expect(isUgcOnly('hi <ugc:3>'), isFalse);
    });

    test('plain text is not a sticker drop', () {
      expect(isUgcOnly('hello'), isFalse);
    });

    test('an escaped reference is text, not a sticker drop', () {
      expect(isUgcOnly(r'\<ugc:3>'), isFalse);
    });
  });

  group('ugcPreviewText', () {
    test('a reference-only body becomes the placeholder', () {
      expect(ugcPreviewText('<ugc:9>', 'Sticker'), 'Sticker');
    });

    test('surrounding text is kept, only the tags go', () {
      expect(ugcPreviewText('look <ugc:9> here', 'Sticker'), 'look  here');
    });

    test('text without tags is returned untouched', () {
      expect(ugcPreviewText('hello', 'Sticker'), 'hello');
    });

    test('an escaped tag stays, minus the backslash that escaped it', () {
      expect(ugcPreviewText(r'\<ugc:9>', 'Sticker'), '<ugc:9>');
      expect(ugcPreviewText(r'look \<ugc:9> here', 'Sticker'), 'look <ugc:9> here');
    });
  });

  testWidgets('markdown swaps a reference for the builder widget', (
    tester,
  ) async {
    const key = ValueKey('ugc-5');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(
            text: 'look <ugc:5> here',
            onTap: (_) {},
            ugcBuilder: (id) => SizedBox(key: key, width: id.toDouble()),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
    // The words that framed it survive on either side.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
        .join();
    expect(texts, contains('look'));
    expect(texts, contains('here'));
    expect(texts, isNot(contains('<ugc:')));
  });

  testWidgets('markdown leaves the tag alone without a builder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(text: 'look <ugc:5> here', onTap: _noop),
        ),
      ),
    );

    final plain = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
        .join();
    expect(plain, contains('<ugc:5>'));
  });

  testWidgets('markdown shows an escaped reference as its literal text', (
    tester,
  ) async {
    const key = ValueKey('ugc-escaped');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(
            text: r'look \<ugc:5> here',
            onTap: (_) {},
            ugcBuilder: (id) => SizedBox(key: key, width: id.toDouble()),
          ),
        ),
      ),
    );

    // The escape asks for the tag itself, not the item behind it.
    expect(find.byKey(key), findsNothing);
    final plain = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
        .join();
    expect(plain, contains('<ugc:5>'));
    expect(plain, isNot(contains(r'\')));
  });
}

void _noop(String _) {}
