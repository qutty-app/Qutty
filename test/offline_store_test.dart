import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/services/offline_store.dart';

import 'support/temp_paths.dart';

ChatInfo _chat(int id, String name) => ChatInfo(
  id: id,
  chatType: 'chat',
  displayName: name,
  bio: '',
  handles: const [],
  createdAt: DateTime(2026, 1, 1),
);

MessageInfo _message(int id, int chatId, String text) => MessageInfo(
  id: id,
  chatId: chatId,
  senderId: 7,
  text: text,
  createdAt: DateTime(2026, 1, 1),
);

Profile _profile(int id, String name) => Profile(
  id: id,
  displayName: name,
  bio: '',
  handles: const [],
);

void main() {
  late Directory temp;
  final store = OfflineStore.instance;
  var accounts = 0;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qutty_offline_test');
    PathProviderPlatform.instance = TempPathProvider(temp.path);
    // Each test gets its own account, which is also what drops whatever the
    // previous test left in memory.
    store.useAccount('account-${accounts++}');
    await store.clearAccount();
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } catch (_) {
      // A leftover temp directory is not worth failing a test over.
    }
  });

  /// Forgets what the store holds in memory without touching the disk, which
  /// is what a fresh launch does.
  Future<void> restart() async {
    final account = store.accountId;
    store.useAccount(null);
    store.useAccount(account);
    await store.load();
  }

  test('keeps the conversations across a restart', () async {
    await store.saveChats([_chat(1, 'Ada'), _chat(2, 'Grace')]);

    await restart();

    expect(store.cachedChats.map((chat) => chat.displayName), ['Ada', 'Grace']);
    expect(store.cachedChats.first.id, 1);
    expect(store.cachedChats.first.chatType, 'chat');
  });

  test('keeps a conversation history across a restart', () async {
    await store.saveMessages(7, [
      _message(1, 7, 'hello'),
      _message(2, 7, 'there'),
    ]);

    await restart();

    final messages = await store.loadMessages(7);
    expect(messages.map((message) => message.text), ['hello', 'there']);
    expect(messages.first.chatId, 7);
    expect(messages.first.senderId, 7);
  });

  test('adds a message that arrives while the app runs', () async {
    await store.saveMessages(7, [_message(1, 7, 'hello')]);

    await store.appendMessage(7, _message(2, 7, 'again'));

    await restart();
    final messages = await store.loadMessages(7);
    expect(messages.map((message) => message.text), ['hello', 'again']);
  });

  test('replacing a message does not store it twice', () async {
    await store.saveMessages(7, [
      _message(1, 7, 'hello'),
      _message(2, 7, 'there'),
    ]);

    await store.appendMessage(7, _message(2, 7, 'edited'));

    final messages = await store.loadMessages(7);
    expect(messages.map((message) => message.text), ['hello', 'edited']);
  });

  test('drops a deleted message from the stored history', () async {
    await store.saveMessages(7, [
      _message(1, 7, 'hello'),
      _message(2, 7, 'there'),
    ]);

    await store.removeMessage(7, 1);

    await restart();
    expect((await store.loadMessages(7)).map((message) => message.id), [2]);
  });

  test('keeps the people across a restart', () async {
    await store.saveUserProfile(_profile(4, 'Grace'));

    await restart();

    expect((await store.loadUserProfile(4))?.displayName, 'Grace');
    expect(await store.loadUserProfile(99), isNull);
  });

  test('reports what it holds', () async {
    await store.saveChats([_chat(1, 'Ada'), _chat(2, 'Grace')]);
    await store.saveMessages(7, [_message(1, 7, 'hello')]);
    await store.saveUserProfile(_profile(4, 'Grace'));

    final stats = await store.stats();

    expect(stats.chatCount, 2);
    expect(stats.messageCount, 1);
    expect(stats.profileCount, 1);
    expect(stats.totalBytes, greaterThan(0));
  });

  test('keeps one account out of the copy of another', () async {
    final first = store.accountId!;
    await store.saveChats([_chat(1, 'Ada')]);

    // The same device, a different account: it must not see Ada.
    store.useAccount('account-other');
    await store.load();
    expect(store.cachedChats, isEmpty);
    await store.clearAccount();

    store.useAccount(first);
    await store.load();
    expect(store.cachedChats, hasLength(1));
  });

  test('forgets everything when the account is cleared', () async {
    await store.saveChats([_chat(1, 'Ada')]);
    await store.saveMessages(7, [_message(1, 7, 'hello')]);
    await store.saveUserProfile(_profile(4, 'Grace'));

    await store.clearAccount();

    await restart();
    expect(store.cachedChats, isEmpty);
    expect(await store.loadMessages(7), isEmpty);
    expect(await store.loadUserProfile(4), isNull);
    expect((await store.stats()).chatCount, 0);
  });

  test('keeps no more histories than the limit allows', () async {
    final total = OfflineStore.maxCachedChats + 5;
    for (var i = 0; i < total; i++) {
      await store.saveMessages(1000 + i, [_message(i + 1, 1000 + i, 'hi')]);
    }

    final scopes = Directory('${temp.path}/offline').listSync()
        .whereType<Directory>()
        .toList();
    final messages = Directory('${scopes.single.path}/messages');
    final files = messages.listSync().whereType<File>().toList();

    expect(files, hasLength(OfflineStore.maxCachedChats));
    // The newest conversation is one of the survivors.
    expect(
      await store.loadMessages(1000 + total - 1),
      isNotEmpty,
    );
  });
}
