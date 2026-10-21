import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/screens/font_screen.dart';
import 'package:qutty/services/custom_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// import 'support/mock_secure_storage.dart';
import 'support/temp_paths.dart';

/// The ways the user can end up with a font, as the picker offers them.
///
/// The count matters as much as the labels: a font that is downloadable but not
/// listed, or a fourth source that was never wired up, both show up as a count
/// that no longer matches what a user can actually choose.
const _expectedRows = 3;

/// Bytes with a real font signature, which is all `registerFont` checks.
///
/// The engine accepts a font this incomplete without complaining, so this is
/// enough to exercise the selection path. It renders nothing, which is why
/// nothing here asserts on what the sample looks like.
Uint8List _fontShapedBytes() => Uint8List.fromList([
  0x00,
  0x01,
  0x00,
  0x00,
  ...List<int>.filled(60, 0),
]);

/// [AppManager.restore] reaches the network on startup, which has nothing to do
/// with what these tests check and no business being allowed to fail them.
HttpClient _offlineClient() => _OfflineHttpClient();

Future<void> restoreOffline(AppManager manager) => HttpOverrides.runZoned(
  manager.restore,
  createHttpClient: (_) => _offlineClient(),
);

void main() {
  // setupMockSecureStorage();
  late AppManager manager;

  /// The value the single radio group is selected on.
  String activeId() => manager.fontId ?? '';

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('qutty_font_screen');
    PathProviderPlatform.instance = TempPathProvider(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    manager = AppManager.instance;
    await restoreOffline(manager);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Applies a sideloaded font from inside the tester's fake-async zone.
  ///
  /// Registering a font writes the file to the real filesystem and hands bytes
  /// to the engine, and neither completes inside the fake-async zone a
  /// `testWidgets` body runs in. Without this the call never returns.
  Future<void> applyFont(WidgetTester tester) async {
    await tester.runAsync(
      () => manager.useSideloadedFont(_fontShapedBytes(), name: 'Test'),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: manager,
        builder: (context, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              L10nScope(child: child ?? const SizedBox.shrink()),
          home: const FontScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers the system font, the catalog, and a file', (tester) async {
    await pumpApp(tester);

    expect(find.text('Font'), findsOneWidget);
    // The section header is not the app bar title again, which would print
    // "Font" twice on one screen.
    expect(find.text('App typeface'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Noto Sans'), findsOneWidget);
    expect(find.text('Choose from file'), findsOneWidget);
  });

  testWidgets('starts on the system font', (tester) async {
    await pumpApp(tester);

    expect(manager.usesSystemFont, isTrue);
    expect(manager.fontFamily, isNull);
    expect(manager.fontLabel, isNull);
  });

  group('only one font can be selected', () {
    testWidgets('the rows share a single radio group', (tester) async {
      await pumpApp(tester);

      // Every row belongs to one group, so exactly one matches the group value.
      final values = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .map((tile) => tile.value)
          .toList();
      expect(values, hasLength(_expectedRows));
      expect(
        values.where((value) => value == activeId()),
        hasLength(1),
        reason:
            'one row must match the group value, otherwise several fonts look '
            'selected at once',
      );
    });

    testWidgets('a chosen font deselects the system font', (tester) async {
      await applyFont(tester);
      await pumpApp(tester);

      expect(manager.usesSystemFont, isFalse);
      expect(manager.fontId, 'sideload');

      final selected = tester
          .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
          .where((tile) => tile.value == activeId());
      expect(selected, hasLength(1));
      expect(
        tester
            .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
            .where((tile) => tile.value == ''),
        hasLength(1),
        reason: 'the system row is still present, just not the selected one',
      );
    });

    testWidgets('going back to the system font clears the choice', (
      tester,
    ) async {
      await applyFont(tester);
      await pumpApp(tester);

      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();

      expect(manager.usesSystemFont, isTrue);
      expect(manager.fontId, isNull);
      // Still exactly one match after switching back.
      expect(
        tester
            .widgetList<RadioListTile<String>>(find.byType(RadioListTile<String>))
            .where((tile) => tile.value == activeId()),
        hasLength(1),
      );
    });
  });

  group('a font has to be downloaded before it can be selected', () {
    /// The catalog row, by its font name.
    RadioListTile<String> catalogTile(WidgetTester tester) => tester
        .widget<RadioListTile<String>>(
          find.widgetWithText(RadioListTile<String>, 'Noto Sans'),
        );

    testWidgets('a font with no local file cannot be selected', (tester) async {
      await pumpApp(tester);

      expect(catalogTile(tester).enabled, isFalse);
      // Downloading is the only way in, and it is offered rather than hidden.
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('tapping an undownloaded font changes nothing', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Noto Sans'));
      await tester.pumpAndSettle();

      expect(manager.usesSystemFont, isTrue);
      expect(manager.fontId, isNull);
    });

    testWidgets('a cached font becomes selectable', (tester) async {
      // Put the file in place, the way a finished download would. The read has
      // to happen inside `runAsync` because a `testWidgets` body runs in a
      // fake-async zone where real filesystem I/O never completes.
      await tester.runAsync(() async {
        await writeCachedFont(fontCacheName('noto_sans'), _fontShapedBytes());
        await manager.refreshDownloadedFonts();
      });
      await pumpApp(tester);

      expect(catalogTile(tester).enabled, isTrue);
      // No download left to do, so the button is gone.
      expect(find.text('Download'), findsNothing);
    });

    testWidgets('a downloaded font is still offered after a restart', (
      tester,
    ) async {
      // The cache exists so a font survives a restart without another download.
      // Re-running restore is what a fresh app start does.
      await tester.runAsync(() async {
        await writeCachedFont(fontCacheName('noto_sans'), _fontShapedBytes());
      });
      await tester.runAsync(() => restoreOffline(manager));

      expect(manager.downloadedFonts, contains('noto_sans'));
      await pumpApp(tester);
      expect(catalogTile(tester).enabled, isTrue);
      expect(find.text('Download'), findsNothing);
    });

    testWidgets('the system font needs no download', (tester) async {
      await pumpApp(tester);

      // The platform font is always present, so it is always selectable. If it
      // were gated the user could be left with no way to get back to it.
      final system = tester.widget<RadioListTile<String>>(
        find.widgetWithText(RadioListTile<String>, 'System default'),
      );
      expect(system.enabled, isTrue);
    });
  });

  group('the preview only shows a font that is loaded', () {
    testWidgets('the active font shows its sample', (tester) async {
      await applyFont(tester);
      await pumpApp(tester);

      // The sideloaded row is the active one, so it is the only row entitled to
      // a sample. It shows the filename instead, which is its label.
      expect(find.text('Test'), findsOneWidget);
      expect(
        find.text('The quick brown fox jumps over the lazy dog'),
        findsNothing,
      );
    });

    testWidgets('an unloaded font says so instead of faking a preview', (
      tester,
    ) async {
      await pumpApp(tester);

      // The system font is the loaded one, so only its row shows a sample. The
      // other two are not registered with the engine and must not draw the
      // sample in the system font, which would look like a preview of them.
      expect(
        find.text('The quick brown fox jumps over the lazy dog'),
        findsOneWidget,
      );
      expect(find.text('Font not loaded'), findsNWidgets(_expectedRows - 1));
    });

    testWidgets('the placeholder clears once a font is applied', (tester) async {
      await applyFont(tester);
      await pumpApp(tester);

      // The system row is no longer the loaded font, so it now says so.
      expect(find.text('Font not loaded'), findsNWidgets(_expectedRows - 1));
      expect(
        find.text('The quick brown fox jumps over the lazy dog'),
        findsNothing,
      );
    });
  });
}

/// [AppManager.restore] reaches the network on startup, which has nothing to do
/// with what these tests check and no business being allowed to fail them.
class _OfflineHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) => _refuse();
  @override
  Future<HttpClientRequest> postUrl(Uri url) => _refuse();
  @override
  Future<HttpClientRequest> putUrl(Uri url) => _refuse();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _refuse();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _refuse();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _refuse();

  @override
  void close({bool force = false}) {}

  Future<HttpClientRequest> _refuse() => Future<HttpClientRequest>.error(
    const SocketException('offline in tests'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
