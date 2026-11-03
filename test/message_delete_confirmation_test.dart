import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/main.dart';

import 'support/fake_api.dart';

MessageInfo _message({
  required int id,
  required int chatId,
  required String text,
}) => MessageInfo(
  id: id,
  chatId: chatId,
  senderId: 99,
  text: text,
  createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: id)),
);

Map<String, String> _chatRoutes(int chatId) => {
  '/v1/chats/$chatId':
      '{"id":$chatId,"chat_type":"chat","display_name":"Test chat","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
  '/v1/chats/$chatId/me':
      '{"user_id":1,"display_name":"Me","role":"member","permissions":["write_messages"],"joined_at":"2026-01-01T00:00:00Z"}',
  '/v1/chats/$chatId/messages': '[]',
};

void main() {
  late AppManager manager;
  late FakeApiHttpOverrides api;

  setUp(() {
    manager = AppManager.instance;
    manager.api.token = 'test-token';
    manager.profile = const Profile(
      id: 1,
      displayName: 'Me',
      bio: '',
      handles: [],
    );
    api = FakeApiHttpOverrides(routes: _chatRoutes(4248));
    HttpOverrides.global = api;
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  Future<FakeApiHttpOverrides> mountChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      router.go('/chat/4248');
      await tester.pumpAndSettle();
    }, createHttpClient: (_) => api.createHttpClient(null));
    return api;
  }

  testWidgets('asks before deleting one message', (tester) async {
    final overrides = await mountChat(tester);
    overrides.routes['DELETE /v1/chats/4248/messages/70'] = '';
    overrides.statusCodes['DELETE /v1/chats/4248/messages/70'] = 204;
    manager.onIncomingMessage(
      _message(id: 70, chatId: 4248, text: 'delete me'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.text('delete me'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete message?'), findsOneWidget);
    expect(find.text('delete me'), findsOneWidget);

    // Cancelling leaves both the dialog and the message behind.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message?'), findsNothing);
    expect(find.text('delete me'), findsOneWidget);
    expect(
      overrides.requests.where((request) => request.method == 'DELETE'),
      isEmpty,
    );

    // Confirming removes the message and sends the request.
    await tester.tap(find.text('delete me'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('delete me'), findsNothing);
    expect(
      overrides.requests.where((request) => request.method == 'DELETE'),
      hasLength(1),
    );
  });

  testWidgets('asks before deleting every selected message', (tester) async {
    final overrides = await mountChat(tester);
    overrides.routes['DELETE /v1/chats/4248/messages/80'] = '';
    overrides.routes['DELETE /v1/chats/4248/messages/81'] = '';
    overrides.statusCodes['DELETE /v1/chats/4248/messages/80'] = 204;
    overrides.statusCodes['DELETE /v1/chats/4248/messages/81'] = 204;
    manager.onIncomingMessage(
      _message(id: 80, chatId: 4248, text: 'first thing'),
    );
    manager.onIncomingMessage(
      _message(id: 81, chatId: 4248, text: 'second thing'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.longPress(find.text('first thing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('second thing'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete messages?'), findsOneWidget);
    expect(find.textContaining('2 messages'), findsOneWidget);

    // Cancelling keeps the selection so the user can carry on.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete messages?'), findsNothing);
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('first thing'), findsOneWidget);
    expect(find.text('second thing'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('first thing'), findsNothing);
    expect(find.text('second thing'), findsNothing);
    expect(
      overrides.requests.where((request) => request.method == 'DELETE'),
      hasLength(2),
    );
  });
}
