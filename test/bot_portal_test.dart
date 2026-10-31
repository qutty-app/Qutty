import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/bot_portal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

/// Advances a few frames.
///
/// Not `pumpAndSettle`: pages that show a spinner while they load, and a spinner
/// never stops animating, so settling would never finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> botJson({int id = 1, String displayName = 'My Bot'}) => {
  'id': id,
  'display_name': displayName,
  'bio': 'bot bio',
  'avatar_url': '/static/logo_bg.svg',
  'account_type': 'bot',
  'handles': ['my_bot'],
  'last_online': '2026-09-30T12:00:00Z',
  'created_at': '2026-09-30T12:00:00Z',
  'updated_at': '2026-09-30T12:00:00Z',
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
        home: const BotPortalScreen(),
      ),
    );
    await settle(tester);
    return overrides;
  }

  testWidgets('lists the bots the account owns', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/dev/bot': jsonEncode([botJson()]),
        },
      ),
    );

    expect(find.text('My Bot'), findsOneWidget);
    expect(find.textContaining('@my_bot'), findsOneWidget);
    expect(find.textContaining('bot bio'), findsOneWidget);
    expect(
      overrides.requests.any(
        (r) => r.path == '/v1/dev/bot' && r.method == 'GET',
      ),
      isTrue,
    );
  });

  testWidgets('an account with no bots is told to make one', (tester) async {
    await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(routes: {'/v1/dev/bot': '[]'}),
    );

    expect(find.textContaining('No bots yet'), findsOneWidget);
    expect(find.text('New bot'), findsOneWidget);
  });

  testWidgets('creating a bot posts it and shows the token once', (
    tester,
  ) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/dev/bot': '[]',
          'POST /v1/dev/bot': jsonEncode({
            'bot': botJson(),
            'token': 'fresh-bot-token',
          }),
        },
      ),
    );

    await tester.tap(find.text('New bot'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'My Bot');
    await tester.tap(find.widgetWithText(FilledButton, 'Create bot'));
    await settle(tester);

    final post = overrides.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/v1/dev/bot',
    );
    expect(jsonDecode(post.body)['display_name'], 'My Bot');
    expect(jsonDecode(post.body)['bio'], '');
    expect(jsonDecode(post.body)['handle'], '');
    expect(find.text('fresh-bot-token'), findsOneWidget);
  });

  testWidgets('deleting a bot confirms first, then removes it', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/dev/bot': jsonEncode([botJson()]),
          'DELETE /v1/dev/bot/1': '{}',
        },
      ),
    );

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('Delete bot?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(
      overrides.requests.any(
        (r) => r.method == 'DELETE' && r.path == '/v1/dev/bot/1',
      ),
      isTrue,
    );
    expect(find.text('My Bot'), findsNothing);
  });

  testWidgets('resetting a bot token shows the new token', (tester) async {
    final overrides = await pumpPortal(
      tester,
      overrides: FakeApiHttpOverrides(
        routes: {
          '/v1/dev/bot': jsonEncode([botJson()]),
          'POST /v1/dev/bot/1/reset-token': jsonEncode({'token': 'rotated'}),
        },
      ),
    );

    await tester.tap(find.byTooltip('Reset token'));
    await settle(tester);
    expect(find.text('Reset bot token?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reset token'));
    await settle(tester);

    expect(
      overrides.requests.any(
        (r) => r.method == 'POST' && r.path == '/v1/dev/bot/1/reset-token',
      ),
      isTrue,
    );
    expect(find.text('rotated'), findsOneWidget);
  });

  testWidgets('a failed load explains itself and offers a retry', (
    tester,
  ) async {
    await pumpPortal(tester, overrides: FakeApiHttpOverrides(failAll: true));

    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });
}
