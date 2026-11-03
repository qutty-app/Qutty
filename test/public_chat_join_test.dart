import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

const profileJson = {
  'id': 5,
  'display_name': 'Alice',
  'bio': 'hello',
  'avatar_url': '',
  'handles': ['alice'],
  'email': null,
  'account_type': 'user',
  'last_online': '2026-01-01T00:00:00Z',
};

// A public chat: it carries a handle, so the server lets a non-member read it.
const publicChatJson = {
  'id': 7,
  'chat_type': 'group',
  'display_name': 'Public group',
  'bio': 'desc',
  'avatar_url': '',
  'handles': ['public_group'],
  'created_at': '2026-01-01T00:00:00Z',
};

const notAMemberJson = {
  'error': 'not_a_member',
  'message': 'not a member',
};

void main() {
  final overrides = FakeApiHttpOverrides(
    routes: {
      '/v1/account/me': jsonEncode(profileJson),
      '/v1/chats/7': jsonEncode(publicChatJson),
      '/v1/chats/7/me': jsonEncode(notAMemberJson),
      '/v1/chats/7/messages': jsonEncode([]),
      'POST /v1/chats/join': jsonEncode({'id': 7}),
    },
  )..statusCodes['/v1/chats/7/me'] = 403;

  const accountId = 'https://qutty.app\u0000token-abc';

  setUp(() {
    HttpOverrides.global = overrides;
    SharedPreferences.setMockInitialValues({
      'qutty.accounts': jsonEncode([
        {
          'id': accountId,
          'label': 'alice',
          'baseUrl': 'https://qutty.app',
          'token': 'token-abc',
        },
      ]),
      'qutty.active_account': accountId,
    });
  });

  tearDown(() => HttpOverrides.global = null);

  Future<void> openChat(WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.runAsync(() => AppManager.instance.restore());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatScreen(chatId: 7),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  }

  testWidgets('a non-member of a public chat is offered Join, not an error', (
    tester,
  ) async {
    await openChat(tester);

    expect(find.text('You are not a member of this chat.'), findsNothing);
    expect(find.text('Join chat'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Join joins by the handle shown in the chat', (tester) async {
    await openChat(tester);

    await tester.tap(find.text('Join chat'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final join = overrides.requests
        .where((request) => request.path == '/v1/chats/join')
        .single;
    expect(join.method, 'POST');
    expect(jsonDecode(join.body), {'handle': 'public_group'});
  });
}
