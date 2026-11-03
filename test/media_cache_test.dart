import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qutty/services/media_cache.dart';

import 'support/fake_api.dart';
import 'support/temp_paths.dart';

void main() {
  late Directory temp;
  final cache = MediaCache.instance;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qutty_media_test');
    PathProviderPlatform.instance = TempPathProvider(temp.path);
    await cache.setMaxBytes(MediaCache.defaultMaxBytes);
    // Each test starts on the same scope, so a previous test's account cannot
    // decide which directory this one writes to.
    cache.useAccount(null);
    // Emptying the cache also makes the next lookup scan the directory the
    // path provider now points at instead of the previous test's.
    await cache.clear();
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } catch (_) {
      // A leftover temp directory is not worth failing a test over.
    }
  });

  /// The folder the cache writes to while no account is active.
  ///
  /// An account named `null` is scoped to `default`, which is what the tests
  /// run on.
  Directory cacheDirectory() =>
      Directory('${temp.path}/media/default')..createSync(recursive: true);

  /// Creates a file in the cache directory with [bytes] bytes of content.
  File storeFile(String url, int bytes, {required DateTime modified}) {
    final file = File('${cacheDirectory().path}/${cache.fileNameFor(url)}')
      ..writeAsBytesSync(List<int>.filled(bytes, 1));
    file.setLastModifiedSync(modified);
    return file;
  }

  test('names a file after its url so one picture is stored once', () {
    final first = cache.fileNameFor('https://cdn.example/a.png');
    expect(cache.fileNameFor('https://cdn.example/a.png'), first);
    expect(first, isNot(cache.fileNameFor('https://cdn.example/b.png')));
    // The extension is kept so the file can be recognised as an image.
    expect(first, endsWith('.png'));
    // A url without a usable extension still gets a stable name.
    final plain = cache.fileNameFor('https://cdn.example/media/7');
    expect(plain, hasLength(64));
    expect(plain, isNot(contains('.')));
  });

  test('serves a stored picture without asking the network again', () async {
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3, 4])}',
      },
    );
    Future<File?> fetch() => HttpOverrides.runZoned(
      () => cache.download('https://cdn.example/media/a.png'),
      createHttpClient: overrides.createHttpClient,
    );

    final file = await fetch();
    expect(file, isNotNull);
    expect(await file!.readAsBytes(), [1, 2, 3, 4]);
    expect(overrides.requests, hasLength(1));
    expect(
      cache.cachedFileFor('https://cdn.example/media/a.png')?.path,
      file.path,
    );

    // Asking a second time is answered from the cache.
    expect(await fetch(), isNotNull);
    expect(overrides.requests, hasLength(1));
  });

  test('does not prefetch a picture that is already stored', () async {
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
    );
    await HttpOverrides.runZoned(
      () => cache.download('https://cdn.example/media/a.png'),
      createHttpClient: overrides.createHttpClient,
    );
    cache.prefetch('https://cdn.example/media/a.png');
    await Future<void>.delayed(Duration.zero);
    expect(overrides.requests, hasLength(1));
  });

  test('compares a stored picture with the origin before serving it', () async {
    final url = 'https://cdn.example/media/a.png';
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3, 4])}',
      },
      responseHeaders: {
        'GET /media/a.png': {'etag': '"v1"'},
        'HEAD /media/a.png': {'etag': '"v1"'},
      },
    );
    Future<T> zone<T>(Future<T> Function() body) => HttpOverrides.runZoned(
      body,
      createHttpClient: overrides.createHttpClient,
    );

    final file = await zone(() => cache.download(url));
    expect(file, isNotNull);
    // The validators are kept next to the file for the next launch.
    expect(File('${file!.path}.meta.json').existsSync(), isTrue);

    final validated = await zone(() => cache.validatedFileFor(url));
    expect(validated?.path, file.path);
    expect(overrides.requests.map((request) => request.method), [
      'GET',
      'HEAD',
    ]);

    // The answer is remembered for the session, so drawing it again is free.
    await zone(() => cache.validatedFileFor(url));
    expect(overrides.requests, hasLength(2));
  });

  test('replaces a stored picture when the origin changed', () async {
    final url = 'https://cdn.example/media/a.png';
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
      responseHeaders: {
        'GET /media/a.png': {'etag': '"v1"'},
        'HEAD /media/a.png': {'etag': '"v1"'},
      },
    );
    Future<T> zone<T>(Future<T> Function() body) => HttpOverrides.runZoned(
      body,
      createHttpClient: overrides.createHttpClient,
    );

    await zone(() => cache.download(url));

    // The same URL now serves different bytes under a new ETag.
    overrides.routes['/media/a.png'] = 'b64:${base64Encode([4, 5, 6])}';
    overrides.responseHeaders['GET /media/a.png'] = {'etag': '"v2"'};
    overrides.responseHeaders['HEAD /media/a.png'] = {'etag': '"v2"'};

    final replaced = await zone(() => cache.validatedFileFor(url));
    expect(await replaced!.readAsBytes(), [4, 5, 6]);
    expect(overrides.requests.map((request) => request.method), [
      'GET',
      'HEAD',
      'GET',
    ]);

    // The replacement is what later draws see.
    await zone(() => cache.validatedFileFor(url));
    expect(overrides.requests, hasLength(3));
  });

  test('forgets a stored picture the origin no longer has', () async {
    final url = 'https://cdn.example/media/a.png';
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
      responseHeaders: {
        'GET /media/a.png': {'etag': '"v1"'},
        'HEAD /media/a.png': {'etag': '"v1"'},
      },
    );
    Future<T> zone<T>(Future<T> Function() body) => HttpOverrides.runZoned(
      body,
      createHttpClient: overrides.createHttpClient,
    );

    final file = await zone(() => cache.download(url));
    overrides.statusCodes['HEAD /media/a.png'] = 404;

    expect(await zone(() => cache.validatedFileFor(url)), isNull);
    expect(file!.existsSync(), isFalse);
    expect(cache.cachedFileFor(url), isNull);
  });

  test('reads what is already on disk into the cache', () async {
    final file = storeFile(
      'https://cdn.example/a.png',
      12,
      modified: DateTime(2026, 1, 1),
    );
    // Nothing is known about the disk until it is read.
    expect(cache.cachedFileFor('https://cdn.example/a.png'), isNull);

    await cache.load();
    expect(cache.cachedFileFor('https://cdn.example/a.png')?.path, file.path);

    final stats = await cache.stats();
    expect(stats.fileCount, 1);
    expect(stats.totalBytes, 12);
    expect(stats.maxBytes, MediaCache.defaultMaxBytes);
  });

  test('keeps one account out of another account\'s pictures', () async {
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
    );
    Future<File?> fetch() => HttpOverrides.runZoned(
      () => cache.download('https://cdn.example/media/a.png'),
      createHttpClient: overrides.createHttpClient,
    );

    cache.useAccount('account-a');
    expect(await fetch(), isNotNull);

    // The same device, a different account: the picture is not theirs.
    cache.useAccount('account-b');
    expect(cache.cachedFileFor('https://cdn.example/media/a.png'), isNull);
    await cache.load();
    expect((await cache.stats()).fileCount, 0);

    // Coming back finds it again.
    cache.useAccount('account-a');
    await cache.load();
    expect(cache.cachedFileFor('https://cdn.example/media/a.png'), isNotNull);
  });

  test('a download that lands after a switch is not shown', () async {
    cache.useAccount('account-a');
    final download = cache.download('https://cdn.example/media/a.png');

    // The account changes while the picture is still on its way.
    cache.useAccount('account-b');
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
    );
    final file = await HttpOverrides.runZoned(
      () => download,
      createHttpClient: overrides.createHttpClient,
    );

    expect(file, isNull);
    expect(cache.cachedFileFor('https://cdn.example/media/a.png'), isNull);
  });

  test('emptying every account removes the whole cache', () async {
    final overrides = FakeApiHttpOverrides(
      routes: {
        '/media/a.png': 'b64:${base64Encode([1, 2, 3])}',
      },
    );
    cache.useAccount('account-a');
    await HttpOverrides.runZoned(
      () => cache.download('https://cdn.example/media/a.png'),
      createHttpClient: overrides.createHttpClient,
    );
    expect(Directory('${temp.path}/media').existsSync(), isTrue);

    await cache.clearAll();

    expect(cache.cachedFileFor('https://cdn.example/media/a.png'), isNull);
    expect(Directory('${temp.path}/media').existsSync(), isFalse);
    expect((await cache.stats()).fileCount, 0);
  });

  test(
    'drops the least recently used pictures once it runs out of room',
    () async {
      storeFile(
        'https://cdn.example/old.png',
        100,
        modified: DateTime(2026, 1, 1),
      );
      storeFile(
        'https://cdn.example/middle.png',
        100,
        modified: DateTime(2026, 1, 2),
      );
      storeFile(
        'https://cdn.example/new.png',
        100,
        modified: DateTime(2026, 1, 3),
      );
      await cache.load();

      await cache.setMaxBytes(250);

      expect(cache.cachedFileFor('https://cdn.example/old.png'), isNull);
      expect(cache.cachedFileFor('https://cdn.example/middle.png'), isNotNull);
      expect(cache.cachedFileFor('https://cdn.example/new.png'), isNotNull);
      final stats = await cache.stats();
      expect(stats.totalBytes, 200);
      expect(stats.fileCount, 2);
    },
  );

  test('emptying the cache removes the files and forgets them', () async {
    final file = storeFile(
      'https://cdn.example/a.png',
      8,
      modified: DateTime(2026, 1, 1),
    );
    await cache.load();
    expect(cache.cachedFileFor('https://cdn.example/a.png'), isNotNull);

    await cache.clear();

    expect(cache.cachedFileFor('https://cdn.example/a.png'), isNull);
    expect(file.existsSync(), isFalse);
    expect((await cache.stats()).fileCount, 0);
  });

  test('a partial download is not served as a picture', () async {
    File(
      '${cacheDirectory().path}/${cache.fileNameFor('https://cdn.example/a.png')}.part',
    ).writeAsBytesSync([1, 2, 3]);

    await cache.load();

    expect(cache.cachedFileFor('https://cdn.example/a.png'), isNull);
    expect((await cache.stats()).fileCount, 0);
  });
}
