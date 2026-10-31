import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/services/media_cache.dart';
import 'package:qutty/services/offline_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';
import 'support/temp_paths.dart';

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
  final manager = AppManager.instance;
  final overrides = FakeApiHttpOverrides(
    routes: {'/v1/account/me': jsonEncode(profileJson)},
  );
  late Directory temp;

  Future<T> zoneRun<T>(Future<T> Function() body) => HttpOverrides.runZoned(
    body,
    createHttpClient: (_) => overrides.createHttpClient(null),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('qutty_offline_app');
    PathProviderPlatform.instance = TempPathProvider(temp.path);
    overrides.failAll = false;
    // A fresh scope, so nothing the previous test stored is still in memory.
    OfflineStore.instance.useAccount(null);
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } catch (_) {
      // A leftover temp directory is not worth failing a test over.
    }
  });

  test('falls back to the stored person when the server is away', () async {
    await zoneRun(() => manager.login('alice', 'password'));
    await OfflineStore.instance.saveUserProfile(
      const Profile(id: 7, displayName: 'Grace', bio: '', handles: []),
    );

    overrides.failAll = true;

    final profile = await zoneRun(() => manager.loadUserProfile(7));
    expect(profile.displayName, 'Grace');
  });

  test('says so when nobody stored knows the person either', () async {
    await zoneRun(() => manager.login('alice', 'password'));

    overrides.failAll = true;

    await expectLater(
      zoneRun(() => manager.loadUserProfile(7)),
      throwsA(isA<Exception>()),
    );
  });

  test('keeps a conversation it loaded, so it survives the server', () async {
    overrides.routes['/v1/chats/7/messages'] = jsonEncode([
      {
        'id': 1,
        'chat_id': 7,
        'sender_id': 7,
        'text': 'hello',
        'created_at': '2026-01-01T00:00:00Z',
      },
      {
        'id': 2,
        'chat_id': 7,
        'sender_id': 42,
        'text': 'there',
        'created_at': '2026-01-01T00:01:00Z',
      },
    ]);
    await zoneRun(() => manager.login('alice', 'password'));

    final loaded = await zoneRun(() => manager.loadMessages(7));
    expect(loaded.map((message) => message.text), ['hello', 'there']);

    overrides.failAll = true;
    await expectLater(
      zoneRun(() => manager.loadMessages(7)),
      throwsA(isA<Exception>()),
    );

    // The screen reads this copy when the server could not answer.
    final stored = await manager.storedMessages(7);
    expect(stored.map((message) => message.text), ['hello', 'there']);
  });

  test('media belongs to the account that loaded it', () async {
    overrides.routes['/media/a.png'] = 'b64:${base64Encode([1, 2, 3])}';
    await zoneRun(() => manager.login('alice', 'password'));
    final url = 'https://api.qutty.app/media/a.png';

    final file = await zoneRun(() => MediaCache.instance.download(url));
    expect(file, isNotNull);
    expect(MediaCache.instance.cachedFileFor(url), isNotNull);

    // A second account on the same device starts with nothing of the first.
    overrides.routes['/v1/account/me'] = jsonEncode({
      ...profileJson,
      'id': 43,
      'display_name': 'Bob',
      'handles': ['bob'],
    });
    await zoneRun(() => manager.login('bob', 'password'));

    expect(MediaCache.instance.cachedFileFor(url), isNull);
  });

  test('does not keep a conversation when caching is off', () async {
    overrides.routes['/v1/chats/7/messages'] = jsonEncode([
      {
        'id': 1,
        'chat_id': 7,
        'sender_id': 7,
        'text': 'hello',
        'created_at': '2026-01-01T00:00:00Z',
      },
    ]);
    await zoneRun(() => manager.login('alice', 'password'));
    await manager.setCacheChats(false);

    await zoneRun(() => manager.loadMessages(7));

    expect(await manager.storedMessages(7), isEmpty);
  });
}
