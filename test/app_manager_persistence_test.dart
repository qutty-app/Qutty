import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';
// import 'support/mock_secure_storage.dart';

const profileJson = {
  'id': 42,
  'display_name': 'Alice',
  'bio': 'hello',
  'avatar_url': '',
  'handles': ['alice'],
  'email': null,
  'account_type': 'user',
  'last_online': '2026-01-01T00:00:00Z',
};

void main() {
  // setupMockSecureStorage();
  final overrides = FakeApiHttpOverrides(
    routes: {'/v1/account/me': jsonEncode(profileJson)},
  );
  Future<void> zoneRun(Future<void> Function() body) => HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => overrides.createHttpClient(null),
  );

  test(
    'login saves the account and restore keeps the user signed in',
    () async {
      SharedPreferences.setMockInitialValues({});
      final manager = AppManager.instance;

      await zoneRun(() => manager.login('alice', 'password'));

      expect(manager.isLoggedIn, isTrue);
      expect(manager.accounts, hasLength(1));
      expect(manager.activeAccountId, manager.accounts.single.id);

      final prefs = await SharedPreferences.getInstance();
      final savedAccounts = prefs.getString('qutty.accounts');
      expect(savedAccounts, isNotNull);
      expect(savedAccounts, isNot(contains('token')));
      expect(prefs.getString('qutty.active_account'), isNotNull);
      expect(
        prefs.getString(
          SessionStore.accountTokenKey(manager.accounts.single.id),
        ),
        isNotEmpty,
      );

      await zoneRun(manager.restore);

      expect(manager.isLoggedIn, isTrue);
      expect(manager.profile?.id, 42);
    },
  );

  test('restore keeps the user signed in when the network is down', () async {
    SharedPreferences.setMockInitialValues({
      'qutty.accounts': jsonEncode([
        {
          'id': 'https://beta.qutty.app\u000042',
          'label': 'alice',
          'baseUrl': 'https://beta.qutty.app',
          'token': 'token-abc',
        },
      ]),
      'qutty.active_account': 'https://beta.qutty.app\u000042',
      'qutty.active_profile': jsonEncode(profileJson),
    });
    final manager = AppManager.instance;
    overrides.failAll = true;

    await zoneRun(manager.restore);

    expect(
      manager.isLoggedIn,
      isTrue,
      reason: 'user should remain signed in even without network',
    );
    expect(manager.api.token, 'token-abc');
    expect(manager.accounts, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final savedAccounts = prefs.getString('qutty.accounts');
    expect(savedAccounts, isNot(contains('token-abc')));
    expect(
      prefs.getString(SessionStore.accountTokenKey(manager.accounts.single.id)),
      'token-abc',
    );
  });

  test('restore clears a session rejected by the server', () async {
    const accountId = 'https://beta.qutty.app\u000042';
    SharedPreferences.setMockInitialValues({
      SessionStore.accountTokenKey(accountId): 'expired-token',
      'qutty.accounts': jsonEncode([
        {
          'id': accountId,
          'label': 'alice',
          'baseUrl': 'https://beta.qutty.app',
        },
      ]),
      'qutty.active_account': accountId,
      'qutty.active_profile': jsonEncode(profileJson),
    });
    overrides.failAll = false;
    overrides.routes['/v1/account/me'] = 'session not found';
    overrides.statusCodes['GET /v1/account/me'] = 401;
    final manager = AppManager.instance;

    await zoneRun(manager.restore);

    expect(manager.isLoggedIn, isFalse);
    expect(manager.api.token, isNull);
    expect(manager.profile, isNull);
    expect(manager.accounts, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionStore.accountTokenKey(accountId)), isNull);
  });

  test('failed restore keeps the saved account list intact', () async {
    SharedPreferences.setMockInitialValues({
      'qutty.accounts': jsonEncode([
        {
          'id': 'https://beta.qutty.app\u000042',
          'label': 'alice',
          'baseUrl': 'https://beta.qutty.app',
          'token': 'token-abc',
        },
      ]),
      'qutty.active_account': 'https://beta.qutty.app\u000042',
    });
    final manager = AppManager.instance;
    overrides.failAll = true;

    await zoneRun(manager.restore);

    expect(manager.accounts, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('qutty.accounts');
    expect(stored, isNotNull);
    expect(
      jsonDecode(stored!),
      hasLength(1),
      reason: 'the saved account must survive a failed startup',
    );
  });

  test(
    'restore selects the saved account and reads its saved token',
    () async {
      const firstId = 'https://beta.qutty.app\u000041';
      const selectedId = 'https://beta.qutty.app\u000042';
      SharedPreferences.setMockInitialValues({
        SessionStore.accountTokenKey(firstId): 'token-alpha',
        SessionStore.accountTokenKey(selectedId): 'token-beta',
        'qutty.accounts': jsonEncode([
          {
            'id': firstId,
            'label': 'alice-first',
            'baseUrl': 'https://beta.qutty.app',
          },
          {
            'id': selectedId,
            'label': 'alice-beta',
            'baseUrl': 'https://beta.qutty.app',
          },
        ]),
        'qutty.active_account': selectedId,
        'qutty.active_profile': jsonEncode(profileJson),
      });
      final manager = AppManager.instance;
      overrides.failAll = true;

      await zoneRun(manager.restore);

      expect(manager.accounts, hasLength(2));
      expect(manager.activeAccountId, selectedId);
      expect(manager.api.baseUrl, 'https://beta.qutty.app');
      expect(manager.api.token, 'token-beta');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('qutty.active_account'), selectedId);
      expect(prefs.getString('qutty.accounts'), isNot(contains('token-beta')));
    },
  );
}
