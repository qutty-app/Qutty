import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_service.dart';

/// What the offline store holds on disk.
class OfflineStoreStats {
  /// How many conversations are stored.
  final int chatCount;

  /// How many messages are stored across every conversation.
  final int messageCount;

  /// How many people are stored.
  final int profileCount;

  /// How much space the store takes.
  final int totalBytes;

  const OfflineStoreStats({
    required this.chatCount,
    required this.messageCount,
    required this.profileCount,
    required this.totalBytes,
  });

  static const empty = OfflineStoreStats(
    chatCount: 0,
    messageCount: 0,
    profileCount: 0,
    totalBytes: 0,
  );
}

/// One stored file, with the timestamp eviction orders by.
class _StoredFile {
  _StoredFile(this.file, this.modified);

  final File file;
  final DateTime modified;
}

/// The on-disk copy of the conversations, messages and people.
///
/// This is what makes the app readable without a connection: the server is
/// the source of truth, but a chat that was read once should still be there
/// after the train goes into a tunnel.
///
/// The store is scoped by account. The data of one account must never be
/// shown for another, so switching accounts switches the scope, and signing
/// out drops what the signed-out account left behind.
///
/// Reading waits for the disk, which is a thing no screen should do: the
/// conversations, the people and the histories that were already touched are
/// therefore kept in memory and handed out from there. The store is warmed up
/// once at startup with [load]; a history that was never read is the only
/// thing that is still fetched from the disk.
class OfflineStore {
  OfflineStore._();

  /// The store every part of the app shares.
  static final OfflineStore instance = OfflineStore._();

  /// How many conversations keep a message history.
  ///
  /// The history of a chat grows without bound, so the least recently used
  /// conversations are dropped once there are more than this.
  static const int maxCachedChats = 50;

  String? _accountId;

  /// The conversations of the active account.
  List<ChatInfo> _chats = const [];
  bool _chatsLoaded = false;

  /// The stored people, keyed by user id.
  final Map<String, Profile> _profiles = {};
  bool _profilesLoaded = false;

  /// The histories that were read or written since the app started, so a
  /// conversation that was opened once is not read again on every visit.
  final Map<int, List<MessageInfo>> _histories = {};

  Future<void>? _warming;

  /// Bumped whenever the store is pointed at another account, so a read that
  /// was already in flight cannot land in the new account's memory.
  int _generation = 0;

  /// The account the store currently holds data for.
  String? get accountId => _accountId;

  /// The conversations in memory, without touching the disk.
  ///
  /// Empty until [load] has run, which the app does once at startup.
  List<ChatInfo> get cachedChats => _chats;

  /// Points the store at one account's data.
  ///
  /// Everything held for the previous account is dropped: the data of one
  /// account must never be shown for another.
  void useAccount(String? accountId) {
    if (_accountId == accountId) return;
    _accountId = accountId;
    _generation++;
    _chats = const [];
    _chatsLoaded = false;
    _profiles.clear();
    _profilesLoaded = false;
    _histories.clear();
    _warming = null;
  }

  /// Reads the conversations and the people into memory.
  ///
  /// The app calls this once at startup. It is safe to call more than once:
  /// the work is shared between callers and skipped once it has been done.
  Future<void> load() {
    final pending = _warming;
    if (pending != null) return pending;
    final future = _load();
    _warming = future;
    return future;
  }

  Future<void> _load() async {
    final generation = _generation;
    await _loadChats(generation);
    await _loadProfiles(generation);
  }

  /// Stores the conversations of this account.
  Future<void> saveChats(List<ChatInfo> chats) async {
    // The memory is written before the disk so a reader never waits for a
    // write to finish.
    _chats = List<ChatInfo>.unmodifiable(chats);
    _chatsLoaded = true;
    final directory = await _root();
    if (directory == null) return;
    await _writeJson(File('${directory.path}/chats.json'), {
      'chats': chats.map((chat) => chat.toJson()).toList(),
    });
  }

  /// The stored profile of another person, when one was seen before.
  Future<Profile?> loadUserProfile(int userId) async {
    if (!_profilesLoaded) unawaited(load());
    return _profiles['$userId'];
  }

  /// Stores the profile of another person.
  Future<void> saveUserProfile(Profile profile) async {
    _profiles['${profile.id}'] = profile;
    final directory = await _root();
    if (directory == null) return;
    await _updateProfiles(directory, (profiles) {
      final users = profiles['users'];
      final updated = users is Map ? Map<String, dynamic>.from(users) : {};
      updated['${profile.id}'] = profile.toJson();
      profiles['users'] = updated;
    });
  }

  /// The stored messages of one conversation.
  ///
  /// This is the one read that may still go to the disk, because a full
  /// history is too large to keep every conversation in memory. Callers that
  /// must not wait use it from a background task.
  Future<List<MessageInfo>> loadMessages(int chatId) async {
    final hot = _histories[chatId];
    if (hot != null) return hot;
    final directory = await _root();
    if (directory == null) return const [];
    final messages = await _readMessages(directory, chatId);
    _histories[chatId] = messages;
    return messages;
  }

  /// Stores the messages of one conversation.
  Future<void> saveMessages(int chatId, List<MessageInfo> messages) async {
    _histories[chatId] = List<MessageInfo>.unmodifiable(messages);
    final directory = await _root();
    if (directory == null) return;
    await _writeJson(_messagesFile(directory, chatId), {
      'chat_id': chatId,
      'messages': messages.map((message) => message.toJson()).toList(),
    });
    await _trimConversations(directory);
  }

  /// Adds one message to a conversation's stored history.
  ///
  /// Used for messages that arrive while the app is running, so the offline
  /// copy is as complete as the server's.
  Future<void> appendMessage(int chatId, MessageInfo message) async {
    final messages = await loadMessages(chatId);
    final byId = <int, MessageInfo>{
      for (final stored in messages) stored.id: stored,
    };
    byId[message.id] = message;
    final merged = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    await saveMessages(chatId, merged);
  }

  /// Removes one message from a conversation's stored history.
  Future<void> removeMessage(int chatId, int messageId) async {
    final messages = await loadMessages(chatId);
    final kept = messages.where((message) => message.id != messageId).toList();
    if (kept.length == messages.length) return;
    await saveMessages(chatId, kept);
  }

  /// What the store currently holds.
  Future<OfflineStoreStats> stats() async {
    final directory = await _root();
    if (directory == null) return OfflineStoreStats.empty;
    await load();
    var totalBytes = 0;
    totalBytes += await _sizeOf(File('${directory.path}/chats.json'));
    totalBytes += await _sizeOf(_profilesFile(directory));
    var messageCount = 0;
    final messagesDirectory = Directory('${directory.path}/messages');
    if (await messagesDirectory.exists()) {
      try {
        await for (final entity in messagesDirectory.list()) {
          if (entity is! File) continue;
          totalBytes += await _sizeOf(entity);
          final data = await _readJson(entity);
          final items = data?['messages'];
          if (items is List) messageCount += items.length;
        }
      } catch (_) {}
    }
    return OfflineStoreStats(
      chatCount: _chats.length,
      messageCount: messageCount,
      profileCount: _profiles.length,
      totalBytes: totalBytes,
    );
  }

  /// Removes everything stored for this account.
  Future<void> clearAccount() async {
    _chats = const [];
    _chatsLoaded = true;
    _profiles.clear();
    _profilesLoaded = true;
    _histories.clear();
    final directory = await _root();
    if (directory == null) return;
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Removes the stored data of every account on this device.
  Future<void> clearAll() async {
    _chats = const [];
    _chatsLoaded = true;
    _profiles.clear();
    _profilesLoaded = true;
    _histories.clear();
    if (kIsWeb) return;
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory('${support.path}/offline');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// The directory this account's data lives in.
  ///
  /// Null where there is nowhere to put it: the web has no application
  /// directory, and a platform that cannot name one simply has no store.
  Future<Directory?> _root() async {
    if (kIsWeb) return null;
    try {
      final support = await getApplicationSupportDirectory();
      // The account id carries a server url and a user id, so it is hashed
      // rather than used as a path.
      final scope = _accountId == null
          ? 'default'
          : sha256.convert(utf8.encode(_accountId!)).toString();
      final directory = Directory('${support.path}/offline/$scope');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadChats(int generation) async {
    if (_chatsLoaded) return;
    final directory = await _root();
    if (directory == null) return;
    final data = await _readJson(File('${directory.path}/chats.json'));
    // The account may have changed while the disk was answering, in which case
    // this is another account's list.
    if (generation != _generation) return;
    final items = data?['chats'];
    final chats = <ChatInfo>[];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        try {
          chats.add(ChatInfo.fromJson(item.cast<String, dynamic>()));
        } catch (_) {
          // One unreadable conversation is not worth losing the rest over.
        }
      }
    }
    _chats = List<ChatInfo>.unmodifiable(chats);
    _chatsLoaded = true;
  }

  Future<void> _loadProfiles(int generation) async {
    if (_profilesLoaded) return;
    final directory = await _root();
    if (directory == null) return;
    final data = await _readJson(_profilesFile(directory));
    // See [_loadChats]: a late answer for another account is dropped.
    if (generation != _generation) return;
    final users = data?['users'];
    if (users is Map) {
      for (final user in users.entries) {
        final value = user.value;
        if (value is! Map) continue;
        try {
          _profiles['${user.key}'] = Profile.fromJson(
            value.cast<String, dynamic>(),
          );
        } catch (_) {
          // A person that cannot be read is simply not stored.
        }
      }
    }
    _profilesLoaded = true;
  }

  File _profilesFile(Directory directory) =>
      File('${directory.path}/profiles.json');

  File _messagesFile(Directory directory, int chatId) =>
      File('${directory.path}/messages/$chatId.json');

  Future<List<MessageInfo>> _readMessages(
    Directory directory,
    int chatId,
  ) async {
    final data = await _readJson(_messagesFile(directory, chatId));
    final items = data?['messages'];
    if (items is! List) return const [];
    final messages = <MessageInfo>[];
    for (final item in items) {
      if (item is! Map) continue;
      try {
        messages.add(MessageInfo.fromJson(item.cast<String, dynamic>()));
      } catch (_) {
        // One unreadable message is not worth losing the rest over.
      }
    }
    return messages;
  }

  /// Rewrites the profile file with [update] applied to its contents.
  Future<void> _updateProfiles(
    Directory directory,
    void Function(Map<String, dynamic>) update,
  ) async {
    final file = _profilesFile(directory);
    final data = await _readJson(file);
    final profiles = data ?? <String, dynamic>{};
    update(profiles);
    await _writeJson(file, profiles);
  }

  /// Drops the histories of the least recently used conversations.
  Future<void> _trimConversations(Directory directory) async {
    final messagesDirectory = Directory('${directory.path}/messages');
    if (!await messagesDirectory.exists()) return;
    final files = <_StoredFile>[];
    try {
      await for (final entity in messagesDirectory.list()) {
        if (entity is! File) continue;
        if (entity.path.endsWith('.part')) continue;
        try {
          files.add(_StoredFile(entity, (await entity.stat()).modified));
        } catch (_) {}
      }
    } catch (_) {}
    if (files.length <= maxCachedChats) return;
    files.sort((a, b) => a.modified.compareTo(b.modified));
    for (final item in files.take(files.length - maxCachedChats)) {
      try {
        await item.file.delete();
        final name = item.file.uri.pathSegments.last;
        final id = int.tryParse(name.split('.').first);
        if (id != null) _histories.remove(id);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> _readJson(File file) async {
    try {
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.cast<String, dynamic>();
    } catch (_) {
      // A cache file that cannot be read is a cache miss, not an error.
      return null;
    }
  }

  Future<void> _writeJson(File file, Map<String, dynamic> data) async {
    try {
      await file.parent.create(recursive: true);
      // Written aside and moved into place, so a crash halfway through leaves
      // the previous copy rather than a truncated file.
      final partial = File('${file.path}.part');
      await partial.writeAsString(jsonEncode(data), flush: true);
      await partial.rename(file.path);
    } catch (_) {
      // The cache is a convenience: failing to write it must never break the
      // app.
    }
  }

  Future<int> _sizeOf(File file) async {
    try {
      if (!await file.exists()) return 0;
      return (await file.stat()).size;
    } catch (_) {
      return 0;
    }
  }
}
