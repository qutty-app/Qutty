import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/ugc_pack_screen.dart';

import 'support/clipboard.dart';
import 'support/fake_api.dart';

/// Advances a few frames.
///
/// Not `pumpAndSettle`: the screen shows a spinner while it loads, and a
/// spinner never stops animating, so settling would never finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> pack(int id, String name, {String description = ''}) => {
  'id': id,
  'owner_id': 5,
  'display_name': name,
  'description': description,
  'flags': '',
  'item_count': 1,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> sticker(int id, {int packId = 1}) => {
  'id': id,
  'owner_id': 5,
  'pack_id': packId,
  'name': 'Wave $id',
  'url': '/v1/file/ugc/$id.png',
  'key': 'ugc/$id.png',
  'width': 128,
  'height': 128,
  'file_size': 1024,
  'content_type': 'image/png',
};

/// One pack with one sticker, plus whatever the saved list should return.
FakeApiHttpOverrides onePack({
  String favorites = '[]',
  String description = '',
}) => FakeApiHttpOverrides(
  routes: {
    '/v1/ugc/packs/1': jsonEncode(pack(1, 'Cats', description: description)),
    '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
    '/v1/ugc/favorites/packs': favorites,
  },
);

void main() {
  tearDown(() => HttpOverrides.global = null);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeApiHttpOverrides overrides,
    int packId = 1,
  }) async {
    HttpOverrides.global = overrides;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UgcPackScreen(packId: packId),
      ),
    );
    await settle(tester);
  }

  testWidgets('shows the pack and its items', (tester) async {
    await pumpScreen(
      tester,
      overrides: onePack(description: 'Nine lives, all of them yours.'),
    );

    expect(find.text('Cats'), findsOneWidget);
    expect(find.text('Nine lives, all of them yours.'), findsOneWidget);
    expect(find.text('Items · 1'), findsOneWidget);
    expect(find.byTooltip('Wave 7'), findsOneWidget);
  });

  testWidgets('a sticker opens the shared popup, minus Insert', (tester) async {
    await pumpScreen(tester, overrides: onePack());

    await tester.tap(find.byTooltip('Wave 7'));
    await settle(tester);

    // The popup names the pack and offers the heart and the share action; the
    // Insert button is missing because there is no composer to insert into.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cats'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Save pack'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Insert'), findsNothing);
  });

  testWidgets('the button saves the pack', (tester) async {
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/v1/ugc/packs/1': jsonEncode(pack(1, 'Cats')),
        '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
        '/v1/ugc/favorites/packs': '[]',
        'POST /v1/ugc/favorites/packs': '{}',
      },
    );
    await pumpScreen(tester, overrides: overrides);

    await tester.tap(find.widgetWithText(FilledButton, 'Save pack'));
    await settle(tester);

    final post = overrides.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/v1/ugc/favorites/packs',
    );
    expect(jsonDecode(post.body)['pack_id'], 1);
    expect(find.text('Saved to favorites'), findsOneWidget);
    // The button now offers the opposite.
    expect(
      find.widgetWithText(FilledButton, 'Remove saved pack'),
      findsOneWidget,
    );
  });

  testWidgets('a pack that is already saved starts saved', (tester) async {
    await pumpScreen(
      tester,
      overrides: onePack(favorites: jsonEncode([pack(1, 'Cats')])),
    );

    expect(
      find.widgetWithText(FilledButton, 'Remove saved pack'),
      findsOneWidget,
    );
  });

  testWidgets('sharing copies the pack link', (tester) async {
    final clipboard = captureClipboard(tester);
    await pumpScreen(tester, overrides: onePack());

    await tester.tap(find.byTooltip('Share pack'));
    await settle(tester);

    expect(clipboard.text, 'https://qutty.app/sticker/1');
    expect(find.text('Link copied'), findsOneWidget);
  });

  testWidgets('a pack that cannot be read explains itself', (tester) async {
    await pumpScreen(tester, overrides: FakeApiHttpOverrides(failAll: true));

    expect(find.text('This sticker pack is not available.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });
}
