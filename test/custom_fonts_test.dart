import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qutty/services/custom_fonts.dart';

import 'support/fake_api.dart';
import 'support/temp_paths.dart';

/// The stylesheet a legacy-User-Agent request gets: one complete TTF, no
/// `unicode-range` slicing. Captured from the real endpoint.
const _legacyStylesheet = '''
@font-face {
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 400;
  font-stretch: normal;
  src: url(https://fonts.gstatic.com/s/notosans/v42/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d.ttf) format('truetype');
}
''';

/// The stylesheet a browser-User-Agent request gets for the same family: eight
/// WOFF2 faces split by script. Flutter cannot render WOFF2 at all, so this is
/// the response the download path has to avoid getting.
const _browserStylesheet = '''
/* cyrillic-ext */
@font-face {
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 400;
  font-stretch: 100%;
  src: url(https://fonts.gstatic.com/s/notosans/v42/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A-9X6VLYyWtZ3rKW9w.woff2) format('woff2');
  unicode-range: U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F;
}
/* latin */
@font-face {
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 400;
  font-stretch: 100%;
  src: url(https://fonts.gstatic.com/s/notosans/v42/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99d.ttf) format('truetype');
  unicode-range: U+0000-00FF, U+0131, U+0152-0153;
}
''';

/// What the API answers for a family that does not exist. The absence of any
/// `@font-face` is the signal, not the status alone.
const _missingFamilyBody = '400 Bad Request';

/// A byte string that passes [looksLikeFont] on its signature but is not a real
/// font, standing in for a truncated download.
Uint8List _truncated() => Uint8List.fromList([
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  ...List<int>.filled(40, 0),
]);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('qutty_fonts');
    PathProviderPlatform.instance = TempPathProvider(tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('the Google Fonts stylesheet', () {
    test('yields the TTF url the legacy request gets', () {
      expect(parseTruetypeUrl(_legacyStylesheet), contains('.ttf'));
    });

    test('picks the latin face out of a browser response, ignoring woff2', () {
      // A browser response is the trap: its first face is woff2, which Flutter
      // cannot render, and which would silently produce a font that draws
      // nothing. Taking the last face is what makes this work.
      final url = parseTruetypeUrl(_browserStylesheet);
      expect(url, isNotNull);
      expect(url, contains('.ttf'));
      expect(url, isNot(contains('.woff2')));
    });

    test('is null when the family does not exist', () {
      expect(parseTruetypeUrl(_missingFamilyBody), isNull);
    });
  });

  group('font signatures', () {
    test('accepts the three signatures a font can arrive with', () {
      expect(looksLikeFont(Uint8List.fromList(utf8.encode('OTTO${'x' * 8}'))), isTrue);
      expect(
        looksLikeFont(Uint8List.fromList([0, 1, 0, 0, ...List<int>.filled(8, 0)])),
        isTrue,
      );
      expect(looksLikeFont(Uint8List.fromList(utf8.encode('ttcf${'x' * 8}'))), isTrue);
    });

    test('rejects things that are not fonts', () {
      // What the picker can plausibly be handed instead of a font.
      expect(looksLikeFont(Uint8List.fromList(utf8.encode('<!DOCTYPE h'))), isFalse);
      expect(looksLikeFont(Uint8List.fromList(utf8.encode('short'))), isFalse);
      expect(looksLikeFont(Uint8List(0)), isFalse);
    });

    test('refuses to register something that is not a font', () async {
      // The engine accepts whatever it is handed and renders nothing for it, so
      // the check has to happen before the font reaches it rather than after.
      await expectLater(
        registerFont(Uint8List.fromList(utf8.encode('<!DOCTYPE html>'))),
        throwsA(
          isA<FontException>().having(
            (e) => e.failure,
            'failure',
            FontFailure.unreadable,
          ),
        ),
      );
    });
  });

  group('downloads', () {
    test('asks for the legacy response, then fetches the font', () async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/css2': _legacyStylesheet,
          '/s/notosans/v42/font.ttf': 'b64:$_tinyTiffBase64',
        },
      );
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      final bytes = await downloadGoogleFont(downloadableFonts.first);

      expect(bytes, isNotEmpty);
      // The UA is the whole reason this returns a TTF, so it is asserted rather
      // than trusted: with a browser UA the same call yields woff2.
      // Header names are case-insensitive and the client normalises them, so
      // the lookup is too rather than depending on which case arrived.
      expect(
        overrides.requests.first.headers.entries
            .firstWhere((e) => e.key.toLowerCase() == 'user-agent')
            .value,
        'Mozilla/4.0',
      );
      expect(overrides.requests.first.path, '/css2');
      expect(overrides.requests.length, 2);
    });

    test('reports a family that does not exist as notFound', () async {
      HttpOverrides.global = FakeApiHttpOverrides(
        routes: {'/css2': _missingFamilyBody},
      );
      addTearDown(() => HttpOverrides.global = null);

      await expectLater(
        downloadGoogleFont(downloadableFonts.first),
        throwsA(
          isA<FontException>().having(
            (e) => e.failure,
            'failure',
            FontFailure.notFound,
          ),
        ),
      );
    });

    test('reports being offline as a network failure', () async {
      HttpOverrides.global = FakeApiHttpOverrides(failAll: true);
      addTearDown(() => HttpOverrides.global = null);

      await expectLater(
        downloadGoogleFont(downloadableFonts.first),
        throwsA(
          isA<FontException>().having(
            (e) => e.failure,
            'failure',
            FontFailure.network,
          ),
        ),
      );
    });
  });

  group('the on-disk cache', () {
    test('round-trips a font', () async {
      final bytes = _truncated();
      await writeCachedFont('noto_sans', bytes);

      expect(await readCachedFont('noto_sans'), bytes);
    });

    test('is null for a font that was never downloaded', () async {
      expect(await readCachedFont('never_seen'), isNull);
    });

    test('puts the file under a fonts directory', () async {
      final file = await fontCacheFile('noto_sans');
      expect(file.path, contains('${Platform.pathSeparator}fonts'));
      expect(file.path, endsWith('noto_sans.ttf'));
    });

    test('flattens an id that is not a safe file name', () {
      expect(fontCacheName('Noto Sans'), 'Noto_Sans');
      // Dots are stripped along with separators, so a hostile id cannot climb
      // out of the cache directory even before the extension is appended.
      expect(fontCacheName('../../etc/passwd'), '______etc_passwd');
      expect(fontCacheName('../../etc/passwd'), isNot(contains('..')));
    });
  });
}

/// A base64 TTF: the real header of a font file, long enough to look like one
/// to the signature check.
const _tinyTiffBase64 =
    'AAABAAEAAQEAAAEAIABAAABAAAAAAAv7';
