import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/screens/language_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'support/mock_secure_storage.dart';

/// [AppManager.restore] reaches the network on startup, which has nothing to do
/// with what these tests check and no business being allowed to fail them.
HttpClient _offlineClient() => _OfflineHttpClient();

Future<void> restoreOffline(AppManager manager) => HttpOverrides.runZoned(
  manager.restore,
  createHttpClient: (_) => _offlineClient(),
);

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

void main() {
  // setupMockSecureStorage();
  late AppManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = AppManager.instance;
    await restoreOffline(manager);
  });

  /// A miniature app shaped like `main.dart`: the manager owns the locale, and
  /// [L10nScope] is what publishes the resolved strings to non-widget code.
  ///
  /// The [ListenableBuilder] is not optional here. It is what turns a locale
  /// change into a rebuild of [MaterialApp], so a harness that leaves it out
  /// would pass this file's assertions while the app itself never re-translated.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: manager,
        builder: (context, _) => MaterialApp(
          locale: manager.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              L10nScope(child: child ?? const SizedBox.shrink()),
          home: const LanguageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the picker offers the system default and every shipped language',
    (tester) async {
      await pumpApp(tester);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      // Each name is an endonym, so the list reads correctly to someone who
      // cannot read the language the app is currently in.
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('Українська'), findsOneWidget);
    },
  );

  testWidgets('choosing a language retranslates the screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(manager.locale, const Locale('de'));
    // The title is rendered from the new locale, not re-fetched on navigation.
    expect(find.text('Sprache'), findsOneWidget);
    expect(find.text('Systemstandard'), findsOneWidget);
    // The picker keeps showing the endonyms, so a user can navigate back out
    // of a language they cannot read.
    expect(find.text('English'), findsOneWidget);
  });

  test('choosing the system default clears the stored locale', () async {
    await manager.setLocale(const Locale('fr'));
    expect(manager.locale, const Locale('fr'));

    await manager.setLocale(null);

    expect(manager.locale, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('qutty.locale'), isNull);
  });

  test('the locale is persisted under a stable language tag', () async {
    await manager.setLocale(const Locale('uk'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('qutty.locale'), 'uk');
  });

  test('an unsupported stored locale falls back to the system', () async {
    SharedPreferences.setMockInitialValues({'qutty.locale': 'ja'});
    await restoreOffline(manager);

    expect(manager.locale, isNull);
  });

  test('a stored locale is restored on the next start', () async {
    SharedPreferences.setMockInitialValues({'qutty.locale': 'es'});
    await restoreOffline(manager);

    expect(manager.locale, const Locale('es'));
  });

  testWidgets('L10n.current tracks the locale so non-widget code agrees', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(L10n.current.languageTitle, 'Language');

    await manager.setLocale(const Locale('ru'));
    await tester.pumpAndSettle();

    expect(L10n.current.languageTitle, 'Язык');
  });
}
