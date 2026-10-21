import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The chat composer.
///
/// It is an [ExtendedTextField] rather than a plain one so that an unescaped
/// `<ugc:id>` can be drawn as an inline emoji.
Finder composerField() => find.byType(ExtendedTextField);

/// Types [text] into the chat composer.
///
/// `tester.enterText` only speaks to [EditableText], which the extended field
/// does not extend, so the text is written straight to the controller with the
/// caret at the end -- the same value the keyboard would have produced.
Future<void> enterComposerText(WidgetTester tester, String text) async {
  final field = tester.widget<ExtendedTextField>(composerField());
  field.focusNode?.requestFocus();
  field.controller!.value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  await tester.pump();
}

/// The text the composer currently holds.
String composerText(WidgetTester tester) =>
    tester.widget<ExtendedTextField>(composerField()).controller!.text;
