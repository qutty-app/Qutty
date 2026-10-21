import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// A font the picker offers that is fetched on demand instead of shipped.
///
/// Bundling a font means putting its bytes in the app for every user whether or
/// not they ever pick it, so the catalog is downloaded and cached on first use.
class DownloadableFont {
  const DownloadableFont({
    required this.id,
    required this.label,
    required this.family,
    required this.sourceUrl,
  });

  /// Stable identifier, persisted as the user's selection.
  final String id;

  /// What the picker shows. Deliberately untranslated: these are font names, and
  /// a translated font name is not the name you would find the font under.
  final String label;

  /// The family name to ask the Google Fonts CSS API for.
  final String family;

  /// Where the font is published, shown to the user before they trust it.
  final String sourceUrl;
}

const downloadableFonts = <DownloadableFont>[
  DownloadableFont(
    id: 'noto_sans',
    label: 'Noto Sans',
    family: 'Noto Sans',
    sourceUrl: 'https://fonts.google.com/specimen/Noto+Sans',
  ),
];

/// Why a font could not be made available, so the UI can say something useful
/// instead of showing an exception string.
enum FontFailure { network, notFound, unreadable }

class FontException implements Exception {
  const FontException(this.failure);

  final FontFailure failure;

  @override
  String toString() => 'FontException(${failure.name})';
}

/// Google Fonts hands WOFF2 to anything that looks like a browser, and Flutter
/// cannot render WOFF2. A legacy User-Agent gets the original TTF back instead,
/// and because that path predates `unicode-range` subsetting it also returns
/// one complete file per weight rather than a dozen per-script slices.
const _legacyUserAgent = 'Mozilla/4.0';

/// The stylesheet request for a family. Separate from the download so it can be
/// asserted on directly.
Uri googleFontsStylesheet(String family) =>
    Uri.https('fonts.googleapis.com', '/css2', {'family': family});

/// Extracts the first TTF url from a Google Fonts stylesheet.
///
/// Returns null when there is none, which is what a family name that does not
/// exist looks like: the API answers 400 with a body containing no `@font-face`.
/// That is a typo in the catalog rather than a network problem, so it is
/// reported separately.
String? parseTruetypeUrl(String css) => RegExp(
  r"url\((https://[^)\s]+)\)\s*format\('truetype'\)",
).firstMatch(css)?.group(1);

/// Downloads [font] from Google Fonts and returns the font file's bytes.
Future<Uint8List> downloadGoogleFont(DownloadableFont font) async {
  final stylesheet = await _getText(googleFontsStylesheet(font.family));
  final url = parseTruetypeUrl(stylesheet);
  if (url == null) {
    throw const FontException(FontFailure.notFound);
  }
  return _getBytes(Uri.parse(url));
}

/// Downloads a font file the user picked off their device.
Future<Uint8List> downloadFontFile(String url) => _getBytes(Uri.parse(url));

Future<String> _getText(Uri uri) async {
  final response = await _send(uri);
  if (response.statusCode != 200) throw _failureFor(response.statusCode);
  return response.body;
}

Future<Uint8List> _getBytes(Uri uri) async {
  final response = await _send(uri);
  if (response.statusCode != 200) throw _failureFor(response.statusCode);
  final bytes = response.bodyBytes;
  if (bytes.isEmpty) {
    throw const FontException(FontFailure.unreadable);
  }
  return bytes;
}

FontException _failureFor(int statusCode) =>
    statusCode == 404
    ? const FontException(FontFailure.notFound)
    : const FontException(FontFailure.network);

Future<http.Response> _send(Uri uri) async {
  try {
    return await http.get(uri, headers: {'User-Agent': _legacyUserAgent});
  } catch (_) {
    throw const FontException(FontFailure.network);
  }
}

/// Whether [bytes] look like a font we can register.
///
/// A loose check, on purpose: it rules out what the picker can plausibly be
/// handed instead of a font -- an image, an HTML error page, an empty file --
/// without pretending to be a parser.
///
/// It checks the signature only, so a truncated download can still pass. The
/// engine does not reject that: it accepts the bytes and renders nothing, which
/// would look like the font silently failing to apply. Catching that properly
/// means reading the table directory, which is more validation than this needs.
bool looksLikeFont(Uint8List bytes) {
  if (bytes.length < 12) return false;
  // A signature table: 'ttcf' for a collection, 'OTTO' for CFF outlines, and
  // 0x00010000 for TrueType outlines. Anything else is not a font.
  final tag = String.fromCharCodes(bytes.sublist(0, 4));
  return tag == 'ttcf' || tag == 'OTTO' || tag == '\x00\x01\x00\x00';
}

int _loadCounter = 0;

/// Registers [bytes] with the engine and returns the family name to use.
///
/// A family can only be registered once per process and there is no way to
/// unregister it, so each load mints a fresh name instead of reusing the font's
/// id. Re-selecting a font the user already had therefore lands on a new family
/// rather than colliding with the copy still resident from last time.
Future<String> registerFont(Uint8List bytes) async {
  if (!looksLikeFont(bytes)) {
    throw const FontException(FontFailure.unreadable);
  }
  final family = 'qutty.user_font.${_loadCounter++}';
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
  return family;
}

/// The on-disk cache of one font file.
///
/// The bytes are cached rather than kept in preferences because a font is
/// hundreds of kilobytes to megabytes, which is well past what
/// `shared_preferences` should be holding. Keeping the file also means the font
/// survives a restart without another download.
Future<File> fontCacheFile(String name) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/fonts');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return File('${directory.path}/$name.ttf');
}

/// Reads a cached font, or null if it was never downloaded or has gone missing.
Future<Uint8List?> readCachedFont(String name) async {
  try {
    final file = await fontCacheFile(name);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> writeCachedFont(String name, Uint8List bytes) async {
  final file = await fontCacheFile(name);
  await file.writeAsBytes(bytes, flush: true);
}

/// Removes a cached font file, if it is there.
///
/// Returns whether there was anything to remove, so a caller can tell the
/// difference between a delete that worked and one that had already happened.
Future<bool> deleteCachedFont(String name) async {
  final file = await fontCacheFile(name);
  if (!await file.exists()) return false;
  await file.delete();
  return true;
}

/// The file name a font's bytes are cached under.
///
/// Every character outside `[A-Za-z0-9_-]` becomes an underscore, so dots and
/// path separators are flattened rather than merely escaped. An id that arrived
/// from a filename therefore cannot climb out of the cache directory.
String fontCacheName(String id) =>
    id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
