import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

const profileJson = {
  'id': 5,
  'display_name': 'Alice',
  'bio': '',
  'avatar_url': '',
  'handles': ['alice'],
  'email': null,
  'account_type': 'user',
  'last_online': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> chatJson({
  required int id,
  required String type,
  required String role,
  int? peerUserId,
  String handle = '',
}) => {
  'id': id,
  'chat_type': type,
  'peer_user_id': ?peerUserId,
  'display_name': 'Chat $id',
  'bio': '',
  'avatar_url': '',
  'handles': handle.isEmpty ? <String>[] : [handle],
  'permissions': <String>[],
  'created_at': '2026-01-01T00:00:00Z',
  'my_role': role,
};

void main() {
  const accountId = 'https://qutty.app\u0000token-abc';

  test(
    'a DM deleted for this user is hidden from the chat list only',
    () async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/account/me': jsonEncode(profileJson),
          '/v1/chats': jsonEncode([
            chatJson(id: 1, type: 'chat', role: 'member', handle: 'group'),
            chatJson(id: 2, type: 'dm', role: 'restricted', peerUserId: 9),
            chatJson(id: 3, type: 'dm', role: 'member', peerUserId: 10),
          ]),
        },
      );

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

      await HttpOverrides.runZoned(
        () => AppManager.instance.restore(),
        createHttpClient: (_) => overrides.createHttpClient(null),
      );

      expect(AppManager.instance.chats.map((chat) => chat.id), [1, 3]);
      expect(
        AppManager.instance.chats.any(
          (chat) => chat.chatType == 'dm' && chat.myRole == 'restricted',
        ),
        isFalse,
      );
    },
  );
}
