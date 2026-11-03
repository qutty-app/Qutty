import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/screens/auth/login.dart';

import 'support/fake_api.dart';

/// Builds the same app shell `main.dart` uses around the login screen.
Widget loginApp({Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const L10nScope(child: LoginScreen()),
);

void main() {
  group('apiExceptionFromResponse', () {
    tearDown(() => L10n.update(lookupAppLocalizations(const Locale('en'))));

    test('maps invalid_credentials to the sign-in message from the catalog', () {
      final exception = apiExceptionFromResponse(
        401,
        '{"error":"invalid_credentials","message":"username or password is incorrect"}',
        statusMessage: 'Request failed',
        request: 'POST /auth/login',
      );

      expect(exception.code, 'invalid_credentials');
      expect(exception.message, 'Incorrect username or password.');
      expect(
        exception.request,
        'POST /auth/login',
        reason: 'the request stays available for developer diagnostics',
      );
      expect(
        exception.toString(),
        isNot(contains('POST /auth/login')),
        reason: 'the transport shape must never reach the user',
      );
    });

    test('localizes the credential error for every supported language', () {
      final expected = {
        'en': 'Incorrect username or password.',
        'de': 'Benutzername oder Passwort ist falsch.',
        'es': 'Usuario o contraseña incorrectos.',
        'fr': 'Nom d\'utilisateur ou mot de passe incorrect.',
        'ru': 'Неверное имя пользователя или пароль.',
        'uk': 'Неправильне ім\'я користувача або пароль.',
      };

      for (final locale in AppLocalizations.supportedLocales) {
        L10n.update(lookupAppLocalizations(locale));
        final exception = apiExceptionFromResponse(
          401,
          '{"error":"invalid_credentials"}',
          statusMessage: 'Request failed',
        );

        expect(
          exception.message,
          expected[locale.languageCode],
          reason: 'missing translation for ${locale.languageCode}',
        );
      }
    });

    test('shows the server message for a code this build does not know', () {
      final exception = apiExceptionFromResponse(
        400,
        '{"error":"some_future_code","message":"This build is too old."}',
        statusMessage: 'Request failed',
      );

      expect(exception.code, 'some_future_code');
      expect(exception.message, 'This build is too old.');
    });

    test(
      'falls back to the caller supplied text when the body is not JSON',
      () {
        final exception = apiExceptionFromResponse(
          401,
          '<html>502 Bad Gateway</html>',
          statusMessage: 'Incorrect username or password.',
        );

        expect(exception.code, isEmpty);
        expect(exception.message, 'Incorrect username or password.');
        expect(exception.detail, '<html>502 Bad Gateway</html>');
      },
    );

    test('keeps the raw body only in detail, not in the message', () {
      final body =
          '{"error":"example_name","message":"","trace":"at handler.go:42"}';
      final exception = apiExceptionFromResponse(
        500,
        body,
        statusMessage: 'Request failed',
      );

      expect(exception.message, 'Request failed');
      expect(exception.detail, body);
    });

    test('recognizes the catalog spellings the backend currently emits', () {
      for (final code in <String>[
        'add_admins_permission_required',
        'bot_create_conflict',
        'chat_create_conflict',
        'creator_must_delete_chat',
        'forwarded_message_not_editable',
      ]) {
        final message = translateApiError(code);
        expect(message, isNotNull, reason: '$code is not mapped');
        expect(message, isNot(code));
      }
    });
  });

  group('login screen', () {
    testWidgets('shows "Incorrect username or password.", not the raw response', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          'POST /v1/auth/login':
              '{"error":"invalid_credentials","message":"username or password is incorrect"}',
        },
      );
      overrides.statusCodes['POST /v1/auth/login'] = 401;
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(loginApp());
      await tester.enterText(find.byType(TextField).at(0), 'example_name');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect username or password.'), findsOneWidget);
      expect(find.textContaining('POST /v1/auth/login'), findsNothing);
      expect(find.textContaining('{"error"'), findsNothing);
    });

    testWidgets('shows the credential text even when the body is unreadable', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {'POST /v1/auth/login': '<html>401 Unauthorized</html>'},
      );
      overrides.statusCodes['POST /v1/auth/login'] = 401;
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(loginApp());
      await tester.enterText(find.byType(TextField).at(0), 'example_name');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect username or password.'), findsOneWidget);
      expect(find.textContaining('<html>'), findsNothing);
    });

    testWidgets('localizes the credential error when the app is not English', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          'POST /v1/auth/login':
              '{"error":"invalid_credentials","message":"username or password is incorrect"}',
        },
      );
      overrides.statusCodes['POST /v1/auth/login'] = 401;
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(loginApp(locale: const Locale('ru')));
      await tester.enterText(find.byType(TextField).at(0), 'example_name');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Неверное имя пользователя или пароль.'),
        findsOneWidget,
      );
      expect(find.textContaining('POST /v1/auth/login'), findsNothing);
    });
  });
}
