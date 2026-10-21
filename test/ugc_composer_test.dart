import 'dart:convert';
import 'dart:io';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/widgets/ugc.dart';
import 'package:qutty/widgets/ugc_composer.dart';

import 'support/fake_api.dart';

/// The composer draws an unescaped `<ugc:id>` as the item's emoji and an
/// escaped one as the literal tag, so both shapes are mounted here.
void main() {
  tearDown(() => HttpOverrides.global = null);

  Future<void> pumpComposer(WidgetTester tester, String text) async {
    HttpOverrides.global = FakeApiHttpOverrides(
      routes: {
        '/v1/ugc/items/5': jsonEncode({
          'id': 5,
          'owner_id': 1,
          'pack_id': 1,
          'name': 'wave',
          'url': '/v1/file/ugc/5.png',
          'content_type': 'image/png',
        }),
      },
    );
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExtendedTextField(
            controller: controller,
            specialTextSpanBuilder: UgcComposerSpanBuilder(),
          ),
        ),
      ),
    );
    // Two frames: one to lay the field out, one for the item the emoji
    // resolution kicked off to come back and redraw it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('an unescaped reference is drawn as an inline emoji', (
    tester,
  ) async {
    await pumpComposer(tester, 'look <ugc:5> here');

    expect(find.byType(UgcView), findsOneWidget);
  });

  testWidgets('an escaped reference is drawn as the literal tag', (
    tester,
  ) async {
    await pumpComposer(tester, r'look \<ugc:5> here');

    expect(find.byType(UgcView), findsNothing);
  });
}
