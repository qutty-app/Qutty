import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../api/api_service.dart';

/// What the media cache holds on disk.
class MediaCacheStats {
  /// How many files are stored.
  final int fileCount;

  /// How much space they take together.
  final int totalBytes;

  /// The largest the cache may grow.
  final int maxBytes;

  const MediaCacheStats({
    required this.fileCount,
    required this.totalBytes,
    required this.maxBytes,
  });

  /// How much of the allowance is used, from 0 to 1.
  double get usedFraction =>
      maxBytes <= 0 ? 0 : (totalBytes / maxBytes).clamp(0.0, 1.0);
}

/// One file in the cache, with the metadata eviction needs.
class _CachedFile {
  _CachedFile(this.file, this.size, this.modified);

  final File file;
  final int size;
  DateTime modified;
}

/// The on-disk cache of media the app has downloaded.
///
/// Media is the part of a conversation worth keeping: a picture is the same
/// picture tomorrow, and without it an offline chat is a column of
/// placeholders. Files are keyed by the URL they came from, so the same
/// picture is stored once no matter how many messages show it.
///
/// Which files are the account's is not a detail: a picture sent to one
/// account is not another account's to see, so the cache is scoped the way the
/// conversations are. Switching accounts switches the scope, and signing out
/// drops what the signed-out account left behind.
///
/// The cache is bounded. Once it grows past [maxBytes] the least recently
/// used files are dropped, so a long-lived install cannot fill the device.
///
/// What is stored is mirrored in memory, so a picture can be shown without
/// waiting for the disk to answer. The mirror is filled once per account by
/// [load] and kept up to date as files are downloaded and dropped.
class MediaCache {
  MediaCache._();

  /// The cache every part of the app shares.
  static final MediaCache instance = MediaCache._();

  /// How much space the cache may take by default: 256 MB.
  static const int defaultMaxBytes = 256 * 1024 * 1024;

  int _maxBytes = defaultMaxBytes;

  /// The largest the cache may grow, in bytes.
  int get maxBytes => _maxBytes;

  /// The account whose pictures are being cached.
  String? _accountId;

  /// Bumped whenever the scope changes or the cache is emptied, so a download
  /// that was already on its way cannot land in the new account's cache.
  int _generation = 0;

  /// The stored files, keyed by the name they are stored under.
  final Map<String, _CachedFile> _index = {};

  /// The files whose timestamp was already marked this session. The LRU order
  /// follows the last use, and one write per file is enough to say that.
  final Set<String> _touched = {};

  Future<void>? _warming;

  /// Downloads in flight, so two widgets asking for the same file at once
  /// share one request instead of racing for the same file name.
  final Map<String, Future<File?>> _inFlight = {};

  /// Points the cache at one account's pictures.
  ///
  /// Everything held in memory is dropped: it describes the previous account's
  /// files, and showing one account's pictures to another is exactly what the
  /// scope is there to prevent.
  void useAccount(String? accountId) {
    if (_accountId == accountId) return;
    _accountId = accountId;
    _generation++;
    _index.clear();
    _touched.clear();
    _inFlight.clear();
    _warming = null;
  }

  /// Reads what is already on disk into memory.
  ///
  /// The app calls this once at startup. Without it the cache looks empty and
  /// nothing is ever served from it, so it is safe to call more than once:
  /// the work is shared between callers and skipped once it has been done.
  Future<void> load() {
    final pending = _warming;
    if (pending != null) return pending;
    final future = _load();
    _warming = future;
    return future;
  }

  Future<void> _load() async {
    final directory = await _directory();
    if (directory == null) return;
    final files = await _scan(directory);
    _index
      ..clear()
      ..addEntries(files.map((item) => MapEntry(_nameOf(item.file), item)));
    // The cap may have been lowered while the app was not running, so what is
    // already on disk is brought back within it.
    await _evict();
  }

  /// Sets the cap and drops whatever no longer fits.
  Future<void> setMaxBytes(int value) async {
    _maxBytes = value < 0 ? 0 : value;
    await _evict();
  }

  /// The cached copy of [url], or null when it has not been downloaded.
  ///
  /// Answered from memory: a picture that is drawn on screen must not wait for
  /// the disk to say whether it is there.
  File? cachedFileFor(String url) {
    final name = fileNameFor(url);
    final cached = _index[name];
    if (cached == null) return null;
    // Reading the file is what makes it recently used, which is what decides
    // what survives when the cache is full.
    cached.modified = DateTime.now();
    if (_touched.add(name)) {
      unawaited(_touch(cached.file));
    }
    return cached.file;
  }

  /// The file name [url] is stored under.
  ///
  /// The name is the hash of the URL, so two different URLs cannot collide on
  /// one file, and the extension is kept so the file can be recognised as an
  /// image later without opening it.
  String fileNameFor(String url) {
    final digest = sha256.convert(utf8.encode(url)).toString();
    final extension = _extensionFor(url);
    return extension.isEmpty ? digest : '$digest.$extension';
  }

  /// Downloads [url] into the cache and returns the stored file.
  ///
  /// Returns null when the file could not be fetched, so the caller can fall
  /// back to the network.
  Future<File?> download(String url, {Map<String, String>? headers}) async {
    final name = fileNameFor(url);
    // The same picture does not change under its url, so a file that is
    // already stored is the answer.
    final stored = _index[name];
    if (stored != null) return stored.file;
    final pending = _inFlight[name];
    if (pending != null) return pending;
    final future = _download(url, headers);
    _inFlight[name] = future;
    try {
      return await future;
    } finally {
      // Only drop this request: a newer one may have taken the entry's place
      // while this one was in flight.
      if (identical(_inFlight[name], future)) _inFlight.remove(name);
    }
  }

  /// Downloads [url] into the cache without waiting for it to arrive.
  ///
  /// A file that is already cached is left alone: the point of the cache is
  /// not to fetch the same picture twice.
  void prefetch(String url, {Map<String, String>? headers}) {
    if (_index.containsKey(fileNameFor(url))) return;
    unawaited(download(url, headers: headers));
  }

  Future<File?> _download(String url, Map<String, String>? headers) async {
    final generation = _generation;
    final directory = await _directory();
    if (directory == null) return null;
    final name = fileNameFor(url);
    final target = File('${directory.path}/$name');
    final partial = File('${target.path}.part');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = userAgent;
      headers?.forEach((key, value) => request.headers[key] = value);
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      await response.stream.pipe(partial.openWrite());
      await partial.rename(target.path);
      // The account may have been switched or the cache emptied while the
      // file was arriving. It is stored where it was asked for, but it is not
      // this account's picture to show.
      if (generation != _generation) return null;
      final stat = await target.stat();
      _index[name] = _CachedFile(target, stat.size, stat.modified);
      _touched.add(name);
      await _evict();
      return target;
    } catch (_) {
      // A half-written file is worse than no file: it would be served as a
      // broken image for as long as it stays in the cache.
      await _delete(partial);
      return null;
    } finally {
      client.close();
    }
  }

  /// What the cache currently holds.
  Future<MediaCacheStats> stats() async {
    await load();
    return MediaCacheStats(
      fileCount: _index.length,
      totalBytes: _index.values.fold<int>(0, (sum, item) => sum + item.size),
      maxBytes: _maxBytes,
    );
  }

  /// Removes every cached file of the active account.
  Future<void> clear() async {
    final cached = _index.values.toList();
    _index.clear();
    _touched.clear();
    // A download already on its way was asked for before the clear, so its
    // file must not reappear in the cache afterwards.
    _generation++;
    // The mirror is empty now, so a later lookup has to look at the disk again
    // rather than trust a scan that predates the clear.
    _warming = null;
    for (final item in cached) {
      await _delete(item.file);
    }
  }

  /// Removes every cached file of every account on this device.
  Future<void> clearAll() async {
    _index.clear();
    _touched.clear();
    _inFlight.clear();
    _generation++;
    _warming = null;
    if (kIsWeb) return;
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory('${support.path}/media');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Drops the least recently used files until the cache fits in its cap.
  Future<void> _evict() async {
    var total = _index.values.fold<int>(0, (sum, item) => sum + item.size);
    if (total <= _maxBytes) return;
    final files = _index.entries.toList()
      ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
    for (final entry in files) {
      if (total <= _maxBytes) break;
      if (await _delete(entry.value.file)) {
        total -= entry.value.size;
        _index.remove(entry.key);
        _touched.remove(entry.key);
      }
    }
  }

  /// Every cached file on disk, with its size and last change.
  Future<List<_CachedFile>> _scan(Directory directory) async {
    final files = <_CachedFile>[];
    try {
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        // A partial download is not a cached file.
        if (entity.path.endsWith('.part')) continue;
        try {
          final stat = await entity.stat();
          files.add(_CachedFile(entity, stat.size, stat.modified));
        } catch (_) {}
      }
    } catch (_) {}
    return files;
  }

  Future<void> _touch(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Some platforms refuse to change the timestamp. The file is still
      // cached; it just sorts by when it was downloaded.
    }
  }

  Future<bool> _delete(File file) async {
    try {
      if (!await file.exists()) return false;
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _nameOf(File file) => file.uri.pathSegments.last;

  /// The directory this account's cached files live in.
  ///
  /// Null where there is nowhere to put them: the web has no application
  /// directory, and a platform that cannot name one simply has no cache.
  Future<Directory?> _directory() async {
    if (kIsWeb) return null;
    final accountId = _accountId;
    try {
      final support = await getApplicationSupportDirectory();
      // The account id carries a server url and a user id, so it is hashed
      // rather than used as a path.
      final scope = accountId == null
          ? 'default'
          : sha256.convert(utf8.encode(accountId)).toString();
      final directory = Directory('${support.path}/media/$scope');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (_) {
      return null;
    }
  }

  /// The extension of the file [url] points at, or an empty string when it
  /// has none worth keeping.
  ///
  /// The extension is only used to name the cached file, so an unusual one is
  /// dropped rather than carried into the file system.
  String _extensionFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final segments = uri.pathSegments;
    if (segments.isEmpty) return '';
    final segment = segments.last;
    final dot = segment.lastIndexOf('.');
    if (dot <= 0) return '';
    final extension = segment.substring(dot + 1).toLowerCase();
    if (!RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension)) return '';
    return extension;
  }
}
