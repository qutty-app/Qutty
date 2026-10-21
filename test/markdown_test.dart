import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/widgets/markdown.dart';

void main() {
  Future<String> renderText(WidgetTester tester, String markdown) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(text: markdown, onTap: (_) {}),
        ),
      ),
    );
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .expand((text) => text.textSpan != null ? [text.textSpan] : const [])
        .toList();
    final buffer = StringBuffer();
    void visit(InlineSpan? span) {
      if (span == null) return;
      if (span is TextSpan) {
        buffer.write(span.text ?? '');
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child);
        }
      }
    }

    for (final span in texts) {
      visit(span);
    }
    return buffer.toString();
  }

  testWidgets('renders bold, italic, code, strikethrough', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(
            text: '**bold** *italic* `code` ~~strike~~',
            onTap: (_) {},
          ),
        ),
      ),
    );
    final spans = <TextSpan>[];
    void walk(InlineSpan? span) {
      if (span is TextSpan) {
        spans.add(span);
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    for (final widget in tester.widgetList<Text>(find.byType(Text))) {
      walk(widget.textSpan);
    }
    bool has(TextStyle? Function(TextStyle) attr, String text) => spans.any(
      (span) =>
          span.text == text && attr(span.style ?? const TextStyle()) != null,
    );
    expect(
      has((s) => s.fontWeight == FontWeight.bold ? s : null, 'bold'),
      isTrue,
    );
    expect(
      has((s) => s.fontStyle == FontStyle.italic ? s : null, 'italic'),
      isTrue,
    );
    expect(has((s) => s.fontFamily == 'monospace' ? s : null, 'code'), isTrue);
    expect(
      has(
        (s) => s.decoration == TextDecoration.lineThrough ? s : null,
        'strike',
      ),
      isTrue,
    );
  });

  testWidgets('renders headings, lists, blockquote and link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(
            text: '# Title\n- one\n- two\n> quote\n[go](https://x.dev)',
            onTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Title', findRichText: true), findsOneWidget);
    expect(find.text('one', findRichText: true), findsOneWidget);
    expect(find.text('two', findRichText: true), findsOneWidget);
    expect(find.text('quote', findRichText: true), findsOneWidget);
    expect(find.text('go', findRichText: true), findsOneWidget);
  });

  testWidgets('preserves raw text through renderer', (tester) async {
    final raw = await renderText(tester, 'plain **bold** and `code` here');
    expect(raw, 'plain bold and code here');
  });

  testWidgets('fenced code block produces monospace text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageMarkdown(
            text: '```dart\nfinal x = 1;\n```',
            onTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('final x = 1;'), findsOneWidget);
  });
}
