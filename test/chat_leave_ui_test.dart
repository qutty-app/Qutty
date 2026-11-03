import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/profile.dart';
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

Map<String, dynamic> chatJson({
  required int id,
  required String type,
  List<String> handles = const ['some_chat'],
  int? peerUserId,
}) => {
  'id': id,
  'chat_type': type,
  'peer_user_id': ?peerUserId,
  'display_name': type == 'dm' ? 'Bob' : 'Some chat',
  'bio': '',
  'avatar_url': '',
  'handles': handles,
  'created_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> memberJson({required int id, required String role}) => {
  'user_id': 5,
  'display_name': 'Alice',
  'username': 'alice',
  'role': role,
  'avatar_url': '',
  'permissions': ['write_messages', 'read_messages'],
};

void main() {
  final overrides = FakeApiHttpOverrides(
    routes: {'/v1/account/me': jsonEncode(profileJson)},
  );

  const accountId = 'https://qutty.app\u0000token-abc';

  setUp(() {
    HttpOverrides.global = overrides;
    overrides.routes.removeWhere((path, _) => path != '/v1/account/me');
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

  void fakeChat({
    required int id,
    required String type,
    required String role,
    List<String> handles = const ['some_chat'],
    int? peerUserId,
  }) {
    overrides.routes['/v1/chats/$id'] = jsonEncode(
      chatJson(id: id, type: type, handles: handles, peerUserId: peerUserId),
    );
    overrides.routes['/v1/chats/$id/me'] = jsonEncode(
      memberJson(id: id, role: role),
    );
    overrides.routes['/v1/chats/$id/messages'] = '[]';
  }

  Future<void> pumpProfile(WidgetTester tester, int id) async {
    await HttpOverrides.runZoned(() async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.reset);

      await tester.runAsync(() => AppManager.instance.restore());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileScreen(id: id, type: 'chat'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  }

  testWidgets('a normal member gets Leave where settings would be', (
    tester,
  ) async {
    fakeChat(id: 7, type: 'chat', role: 'member');
    await pumpProfile(tester, 7);

    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure to leave this chat?'), findsOneWidget);
    expect(find.text('Stay'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('the creator gets settings, not a leave action', (tester) async {
    fakeChat(id: 7, type: 'chat', role: 'creator');
    await pumpProfile(tester, 7);

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('a DM gets a delete action and the both/me scope', (
    tester,
  ) async {
    fakeChat(
      id: 8,
      type: 'dm',
      role: 'member',
      handles: const [],
      peerUserId: 9,
    );
    await pumpProfile(tester, 8);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete this chat for:'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to delete this chat for yourself?'),
      findsOneWidget,
    );
    expect(find.text('Slide to confirm'), findsOneWidget);
  });
}
