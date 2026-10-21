import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/ugc_portal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/clipboard.dart';
import 'support/fake_api.dart';

/// Advances a few frames.
///
/// Not `pumpAndSettle`: the page shows a spinner while it loads, and a spinner
/// never stops animating, so settling would never finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> packJson({
  int id = 1,
  String name = 'Cats',
  int itemCount = 0,
}) => {
  'id': id,
  'owner_id': 5,
  'display_name': name,
  'description': '',
  'flags': '',
  'item_count': itemCount,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => HttpOverrides.global = null);

  Future<FakeApiHttpOverrides> pumpPortal(
    WidgetTester tester, {
    required FakeApiHttpOverrides overrides,
  }) async {
    HttpOverrides.global = overrides;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const UgcPortalScreen(),
      ),
    );
    await settle(tester);
    return overrides;
  }

  testWidgets('lists the packs the account owns', (tester) async {
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats', itemCount: 2)]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
        },
      ),
    );

    expect(find.text('Cats'), findsOneWidget);
    // The item count is read from the pack's own list, not the summary field.
    expect(find.textContaining('Items'), findsWidgets);
  });

  testWidgets('an account with no packs is told to make one', (tester) async {
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
        },
      ),
    );

    expect(find.textContaining('No packs yet'), findsOneWidget);
    expect(find.text('New pack'), findsOneWidget);
  });

  testWidgets('creating a pack posts it and shows it', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
          'POST /v1/ugc/packs': jsonEncode(packJson(name: 'My Pack')),
        },
      ),
    );

    await tester.tap(find.text('New pack'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'My Pack');
    await tester.tap(find.widgetWithText(FilledButton, 'Create pack'));
    await settle(tester);

    final post = overrides.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/v1/ugc/packs',
    );
    expect(jsonDecode(post.body)['display_name'], 'My Pack');
    // The form page stays mounted beneath the navigator after it pops, so the
    // name shows up both on the new pack tile and in the form's own field.
    expect(find.text('My Pack'), findsWidgets);
  });

  testWidgets('deleting a pack confirms first, then removes it', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats')]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
          'DELETE /v1/ugc/packs/1': '{}',
        },
      ),
    );

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    // The confirmation is a second step, not an immediate delete.
    expect(find.text('Delete pack?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(
      overrides.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/ugc/packs/1',
      ),
      isTrue,
    );
    expect(find.text('Cats'), findsNothing);
  });

  testWidgets('the heart on a pack tile saves the pack', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats')]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
          'POST /v1/ugc/favorites/packs': '{}',
        },
      ),
    );

    // Not saved yet: the heart is an offer to save.
    expect(find.byTooltip('Save pack'), findsOneWidget);
    await tester.tap(find.byTooltip('Save pack'));
    await settle(tester);

    final post = overrides.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/v1/ugc/favorites/packs',
    );
    expect(jsonDecode(post.body)['pack_id'], 1);
    // The heart fills in, and now offers removal.
    expect(find.byTooltip('Save pack'), findsNothing);
    expect(find.byTooltip('Remove saved pack'), findsOneWidget);
  });

  testWidgets('a saved pack starts with a filled heart', (tester) async {
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats')]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/favorites/packs': jsonEncode([packJson(name: 'Cats')]),
        },
      ),
    );

    expect(find.byTooltip('Remove saved pack'), findsOneWidget);
  });

  testWidgets('the page makes packs, it does not browse favorites', (
    tester,
  ) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats')]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
        },
      ),
    );

    // The item shortlist lives in the picker now, so neither its heading nor
    // its empty line is on this page, and the endpoint is never read.
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('No favorites yet.'), findsNothing);
    expect(
      overrides.requests.any((r) => r.path == '/v1/ugc/favorites/items'),
      isFalse,
    );
  });

  testWidgets('sharing a pack copies its link', (tester) async {
    final clipboard = captureClipboard(tester);
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/packs': jsonEncode([packJson(name: 'Cats')]),
          '/v1/ugc/packs/1/items': '[]',
          '/v1/ugc/favorites/packs': '[]',
        },
      ),
    );

    await tester.tap(find.byTooltip('Share pack'));
    await settle(tester);

    expect(clipboard.text, 'https://qutty.app/sticker/1');
    expect(find.text('Link copied'), findsOneWidget);
  });

  testWidgets('a failed load explains itself and offers a retry', (
    tester,
  ) async {
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(failAll: true),
    );

    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });
}
