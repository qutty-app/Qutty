import 'dart:convert';
import 'dart:io';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/main.dart';
import 'package:qutty/screens/call.dart';
import 'package:qutty/screens/chat.dart';
import 'package:qutty/services/native_call_service.dart';
import 'package:qutty/widgets/call_route_sync.dart';
import 'package:qutty/widgets/ugc.dart';

import 'support/composer.dart';
import 'support/fake_api.dart';

const _debounce = Duration(milliseconds: 450);

MessageInfo _message({
  required int id,
  required int chatId,
  required int senderId,
  required String text,
}) => MessageInfo(
  id: id,
  chatId: chatId,
  senderId: senderId,
  text: text,
  createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: id)),
);

/// One UGC item, shaped like the backend's item row.
Map<String, dynamic> _sticker(int id, {int packId = 1}) => {
  'id': id,
  'owner_id': 5,
  'pack_id': packId,
  'name': 'Wave $id',
  'url': '/v1/file/ugc/$id.png',
  'key': 'ugc/$id.png',
  'width': 128,
  'height': 128,
  'file_size': 1024,
  'content_type': 'image/png',
};

/// One UGC pack, shaped like the backend's pack row.
Map<String, dynamic> _pack(int id, String name) => {
  'id': id,
  'owner_id': 5,
  'display_name': name,
  'description': '',
  'flags': '',
  'item_count': 1,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};

void main() {
  late AppManager manager;

  setUp(() {
    manager = AppManager.instance;
    manager.enableCallRingtone = false;
    manager.enableVoiceConnection = false;
    manager.resetActiveCallForTesting();
    NativeCallService.instance.enableNativeCalls = false;
    manager.api.token = null;
    manager.profile = null;
    manager.forceReadCount = false;
    // A call tapped into action outside `mountApp`'s zone would otherwise reach
    // the real network. This is the fallback for those calls.
    HttpOverrides.global = FakeApiHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  void login() {
    manager.api.token = 'test-token';
    manager.profile = const Profile(
      id: 1,
      displayName: 'Me',
      bio: '',
      handles: [],
    );
  }

  Future<void> mountApp(
    WidgetTester tester, {
    String location = '/',
    FakeApiHttpOverrides? apiOverrides,
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final overrides = apiOverrides ?? FakeApiHttpOverrides();
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => CallRouteSync(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      router.go(location);
      await tester.pumpAndSettle();
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  }

  Future<void> openChat(
    WidgetTester tester,
    int chatId, {
    FakeApiHttpOverrides? apiOverrides,
  }) async {
    final routes = <String, String>{};
    for (final id in {4244, 4245, 4246, 4248, 4249, chatId}) {
      routes.addAll({
        '/v1/chats/$id':
            '{"id":$id,"chat_type":"chat","display_name":"Test chat","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
        '/v1/chats/$id/me':
            '{"user_id":1,"display_name":"Me","role":"member","permissions":["write_messages"],"joined_at":"2026-01-01T00:00:00Z"}',
        '/v1/chats/$id/messages': '[]',
      });
    }
    routes.addAll(apiOverrides?.routes ?? const {});
    final overrides = apiOverrides ?? FakeApiHttpOverrides(routes: routes);
    if (apiOverrides != null) apiOverrides.routes.addAll(routes);
    await mountApp(tester, location: '/chat/$chatId', apiOverrides: overrides);
  }

  test(
    'subscribeMessages emits messages pushed via onIncomingMessage',
    () async {
      final received = <MessageInfo>[];
      final subscription = manager.subscribeMessages(4242).listen(received.add);

      manager.onIncomingMessage(
        _message(id: 1, chatId: 4242, senderId: 7, text: 'hello realtime'),
      );
      await Future<void>.delayed(_debounce);

      expect(received, hasLength(1));
      expect(received.single.text, 'hello realtime');

      await subscription.cancel();
    },
  );

  test('subscribeMessages only emits for the subscribed chat', () async {
    final received = <MessageInfo>[];
    final subscription = manager.subscribeMessages(4243).listen(received.add);

    manager.onIncomingMessage(
      _message(id: 2, chatId: 9999, senderId: 7, text: 'other chat'),
    );
    manager.onIncomingMessage(
      _message(id: 3, chatId: 4243, senderId: 7, text: 'right chat'),
    );
    await Future<void>.delayed(_debounce);

    expect(received, hasLength(1));
    expect(received.single.text, 'right chat');

    await subscription.cancel();
  });

  test('unread counters track a chat with no prior state', () {
    expect(() => manager.incrementUnread(5555), returnsNormally);
    expect(manager.unreadCount(5555), 1);
  });

  test(
    'ForwardManifest.forMessage keeps a re-forward attributed to its origin',
    () {
      final plain = MessageInfo(
        id: 3,
        chatId: 5,
        senderId: 1,
        text: 'original',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final manifest = ForwardManifest.forMessage(plain);
      expect(manifest.chatId, 5);
      expect(manifest.messageId, 3);
      // A message that is not itself a forward is its own origin.
      expect(manifest.forwardMessageId, 3);

      final copy = MessageInfo(
        id: 10,
        chatId: 5,
        senderId: 1,
        text: 'original',
        forwarded: 3,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final reforward = ForwardManifest.forMessage(copy);
      expect(reforward.messageId, 10);
      // Forwarding a copy points back at the original rather than chaining.
      expect(reforward.forwardMessageId, 3);
      expect(reforward.toJson(), {
        'chat_id': 5,
        'message_id': 10,
        'forward_message_id': 3,
      });
    },
  );

  test('MessageInfo.fromJson parses the forward author', () {
    final fromUser = MessageInfo.fromJson({
      'id': 1,
      'chat_id': 5,
      'sender_id': 1,
      'text': 'hello',
      'forwarded': 3,
      'forward_author': {
        'type': 'user',
        'id': 42,
        'display_name': 'Alice',
        'avatar_url': 'alice.png',
      },
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(fromUser.isForward, isTrue);
    expect(fromUser.forwardAuthor, isNotNull);
    expect(fromUser.forwardAuthor!.type, 'user');
    expect(fromUser.forwardAuthor!.isChannel, isFalse);
    expect(fromUser.forwardAuthor!.id, 42);
    expect(fromUser.forwardAuthor!.displayName, 'Alice');
    expect(fromUser.forwardAuthor!.avatarUrl, 'alice.png');

    final fromChannel = MessageInfo.fromJson({
      'id': 2,
      'chat_id': 5,
      'sender_id': 1,
      'text': 'broadcast',
      'forwarded': 3,
      'forward_author': {
        'type': 'channel',
        'id': 9,
        'display_name': 'News',
      },
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(fromChannel.forwardAuthor!.isChannel, isTrue);
    expect(fromChannel.forwardAuthor!.displayName, 'News');

    // A plain message carries no author object.
    final plain = MessageInfo.fromJson({
      'id': 3,
      'chat_id': 5,
      'sender_id': 1,
      'text': 'plain',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(plain.isForward, isFalse);
    expect(plain.forwardAuthor, isNull);
  });

  test('MessageInfo parses and preserves the replied-to id', () {
    final reply = MessageInfo.fromJson({
      'id': 4,
      'chat_id': 5,
      'sender_id': 1,
      'text': 'my answer',
      'replied': 9,
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(reply.isReply, isTrue);
    expect(reply.replied, 9);
    // Editing a reply must not turn it into a plain message.
    expect(reply.copyWith(text: 'edited', isEdited: true).replied, 9);

    final plain = MessageInfo.fromJson({
      'id': 5,
      'chat_id': 5,
      'sender_id': 1,
      'text': 'plain',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(plain.isReply, isFalse);
    expect(plain.replied, 0);
  });

  test('voice call events update active chat state and clear on end', () {
    const started = VoiceCallEvent(
      type: 'started',
      chatId: 5556,
      userId: 12,
      displayName: 'Caller',
    );

    manager.onVoiceCallEvent(started);
    expect(manager.activeVoiceCallForChat(5556), started);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 5556,
        userId: 12,
        displayName: '',
      ),
    );
    expect(manager.activeVoiceCallForChat(5556), isNull);
  });

  test('group calls do not ring but stay joinable', () {
    manager.chats = [
      ChatInfo(
        id: 7001,
        chatType: 'chat',
        displayName: 'Group',
        bio: '',
        handles: const [],
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    const started = VoiceCallEvent(
      type: 'started',
      chatId: 7001,
      userId: 12,
      displayName: 'Caller',
    );

    manager.onVoiceCallEvent(started);
    expect(manager.incomingVoiceCall, isNull);
    expect(manager.incomingVoiceCallForChat(7001), isNull);
    expect(manager.activeVoiceCallForChat(7001), started);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 7001,
        userId: 12,
        displayName: '',
      ),
    );
    manager.chats = const [];
  });

  test('native answer action identifies the chat to open', () async {
    final nativeCalls = NativeCallService.instance;
    final received = <NativeCallAction>[];
    final subscription = nativeCalls.actions.listen(received.add);
    nativeCalls.handleNativeEvent(
      const CallEventActionCallAccept(
        CallKitParams(id: 'native-call-test', extra: {'chat_id': 5557}),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single.type, NativeCallActionType.accepted);
    expect(received.single.chatId, 5557);
    await subscription.cancel();
  });

  testWidgets('incoming realtime message renders in an open chat', (
    tester,
  ) async {
    await openChat(tester, 4244);
    expect(find.text('realtime bubble'), findsNothing);

    manager.onIncomingMessage(
      _message(id: 10, chatId: 4244, senderId: 99, text: 'realtime bubble'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    expect(
      find.text('realtime bubble'),
      findsOneWidget,
      reason: 'a message pushed over the socket must render without a refetch',
    );

    // Leaving the chat must cancel the listener, so later pushes cannot mutate
    // a disposed State.
    router.go('/');
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsNothing);

    manager.onIncomingMessage(
      _message(id: 11, chatId: 4244, senderId: 99, text: 'after leaving'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    expect(find.text('after leaving'), findsNothing);
  });

  testWidgets('incoming voice call opens the call page over the active chat', (
    tester,
  ) async {
    login();
    await openChat(tester, 4246);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 4246,
        userId: 99,
        displayName: 'Caller',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CallScreen), findsOneWidget);
    expect(find.text('Caller is calling'), findsOneWidget);
    expect(find.text('Join call'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss call'));
    await tester.pumpAndSettle();
    expect(find.byType(CallScreen), findsNothing);
    expect(find.byType(ChatScreen), findsOneWidget);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 4246,
        userId: 99,
        displayName: '',
      ),
    );

    // Leave the chat so the shared router does not carry it into the next test.
    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('incoming call preserves a draft in the chat composer', (
    tester,
  ) async {
    login();
    const chatId = 4249;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId':
            '{"id":$chatId,"chat_type":"chat","display_name":"Draft chat","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
        '/v1/chats/$chatId/me':
            '{"user_id":1,"display_name":"Me","role":"member","permissions":["write_messages"],"joined_at":"2026-01-01T00:00:00Z"}',
        '/v1/chats/$chatId/messages': '[]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);
    expect(
      api.requests.map((request) => '${request.method} ${request.path}'),
      contains('GET /v1/chats/$chatId'),
      reason: 'routed chat requests: ${api.requests}',
    );
    await tester.pumpAndSettle();
    final composer = find.byWidgetPredicate(
      (widget) =>
          widget is ExtendedTextField &&
          widget.decoration?.hintText == 'Write a message',
    );
    expect(composer, findsOneWidget);
    await enterComposerText(tester, 'unsent draft');

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: chatId,
        userId: 987656,
        displayName: 'Incoming caller',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CallScreen), findsOneWidget);
    expect(find.text('Incoming caller is calling'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss call'));
    await tester.pumpAndSettle();
    expect(composer, findsOneWidget);
    // The composer draws an unescaped `<ugc:id>` as an emoji, so its content
    // is read from the controller rather than from a rendered text widget.
    expect(composerText(tester), 'unsent draft');

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: chatId,
        userId: 987656,
        displayName: '',
      ),
    );

    // Leave the chat so the shared router does not carry it into the next test.
    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('incoming call page shows the caller and its actions', (
    tester,
  ) async {
    manager.setActiveChat(null);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CallScreen(chatId: 4247),
      ),
    );
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 4247,
        userId: 987654,
        displayName: 'Ringing caller',
      ),
    );
    await tester.pump();

    expect(find.text('Ringing caller'), findsOneWidget);
    expect(find.text('Ringing caller is calling'), findsOneWidget);
    expect(find.text('Join call'), findsOneWidget);
    expect(find.text('Dismiss call'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss call'));
    await tester.pump();
    expect(find.text('Ringing caller is calling'), findsNothing);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 4247,
        userId: 987654,
        displayName: '',
      ),
    );
  });

  testWidgets('accepting a call keeps the page open as the in-call surface', (
    tester,
  ) async {
    login();
    await mountApp(tester);
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 4246,
        userId: 99,
        displayName: 'Caller',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CallScreen), findsOneWidget);

    await tester.tap(find.text('Join call'));
    await tester.pumpAndSettle();

    // Same route, now showing the active call rather than a ringing one.
    expect(find.byType(CallScreen), findsOneWidget);
    expect(find.text('Join call'), findsNothing);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsOneWidget);

    await manager.leaveCall();
    await tester.pumpAndSettle();
    expect(find.byType(CallScreen), findsNothing);
  });

  testWidgets('an active call can be minimised to a bar above the chat', (
    tester,
  ) async {
    login();
    await mountApp(tester);
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 4246,
        userId: 99,
        displayName: 'Caller',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join call'));
    await tester.pumpAndSettle();
    expect(find.byType(CallScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Minimize call'));
    await tester.pumpAndSettle();

    expect(find.byType(CallScreen), findsNothing);
    expect(find.byTooltip('Minimize call'), findsNothing);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsOneWidget);
    expect(find.byTooltip('Mute microphone'), findsOneWidget);

    await manager.leaveCall();
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsNothing);
  });

  test('a second incoming call is ignored while already in a call', () async {
    login();
    final overrides = FakeApiHttpOverrides();
    await HttpOverrides.runZoned(() async {
      await manager.startCall(1);
      expect(manager.inActiveCall, isTrue);

      manager.onVoiceCallEvent(
        const VoiceCallEvent(
          type: 'started',
          chatId: 2,
          userId: 99,
          displayName: 'Other caller',
        ),
      );
      expect(manager.incomingVoiceCall, isNull);
      expect(manager.activeVoiceCallForChat(2), isNull);

      await manager.leaveCall();
      expect(manager.inActiveCall, isFalse);

      // Once free, the next call rings as normal again.
      manager.onVoiceCallEvent(
        const VoiceCallEvent(
          type: 'started',
          chatId: 3,
          userId: 99,
          displayName: 'Later caller',
        ),
      );
      expect(manager.incomingVoiceCall?.chatId, 3);
      manager.onVoiceCallEvent(
        const VoiceCallEvent(
          type: 'ended',
          chatId: 3,
          userId: 99,
          displayName: '',
        ),
      );
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  });

  test('a second incoming call is ignored while another is ringing', () async {
    login();
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 2,
        userId: 99,
        displayName: 'First caller',
      ),
    );
    expect(manager.incomingVoiceCall?.chatId, 2);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 3,
        userId: 98,
        displayName: 'Second caller',
      ),
    );
    expect(manager.incomingVoiceCall?.chatId, 2);
    expect(manager.activeVoiceCallForChat(3), isNull);

    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 2,
        userId: 99,
        displayName: '',
      ),
    );
    expect(manager.incomingVoiceCall, isNull);

    // Once free, the next call rings as normal again.
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'started',
        chatId: 3,
        userId: 98,
        displayName: 'Later caller',
      ),
    );
    expect(manager.incomingVoiceCall?.chatId, 3);
    manager.onVoiceCallEvent(
      const VoiceCallEvent(
        type: 'ended',
        chatId: 3,
        userId: 98,
        displayName: '',
      ),
    );
  });

  testWidgets('a redelivered realtime message is not duplicated', (
    tester,
  ) async {
    await openChat(tester, 4245);

    final message = _message(
      id: 20,
      chatId: 4245,
      senderId: 99,
      text: 'exactly once',
    );
    manager.onIncomingMessage(message);
    await tester.pump();
    await tester.pump(_debounce);
    expect(find.text('exactly once'), findsOneWidget);

    // Re-delivery of the same id (reconnect replay, or an echo of our own send)
    // must not append a second bubble.
    manager.onIncomingMessage(message);
    await tester.pump();
    await tester.pump(_debounce);
    expect(find.text('exactly once'), findsOneWidget);
  });

  testWidgets('a message deleted over the socket drops from the open chat', (
    tester,
  ) async {
    await openChat(tester, 4254);
    manager.onIncomingMessage(
      _message(id: 50, chatId: 4254, senderId: 99, text: 'doomed bubble'),
    );
    await tester.pump();
    await tester.pump(_debounce);
    expect(find.text('doomed bubble'), findsOneWidget);

    // The server reports the deletion (opcode 10) from another member.
    manager.onMessageDeleted(4254, 50);
    await tester.pump();
    await tester.pump(_debounce);

    expect(
      find.text('doomed bubble'),
      findsNothing,
      reason:
          'a deletion reported over the socket must remove the bubble '
          'without a refetch',
    );

    // Leaving the chat must cancel the change listener too, so a later
    // deletion cannot mutate a disposed State.
    router.go('/');
    await tester.pumpAndSettle();
    manager.onMessageDeleted(4254, 51);
    await tester.pump();
    await tester.pump(_debounce);
  });

  testWidgets('a message edited over the socket is replaced in the open chat', (
    tester,
  ) async {
    await openChat(tester, 4255);
    manager.onIncomingMessage(
      _message(id: 60, chatId: 4255, senderId: 99, text: 'first draft'),
    );
    await tester.pump();
    await tester.pump(_debounce);
    expect(find.text('first draft'), findsOneWidget);

    // The server reports the edit (opcode 9) from another member, carrying the
    // whole replacement message.
    manager.onMessageEdited(
      _message(id: 60, chatId: 4255, senderId: 99, text: 'second draft'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    expect(find.text('first draft'), findsNothing);
    expect(find.text('second draft'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
  });

  test(
    'read receipts move a member cursor forward and drive reader counts',
    () async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/chats/9001/members':
              '[{"user_id":1,"display_name":"Me","role":"member","permissions":[],"last_read_message_id":10},'
              '{"user_id":2,"display_name":"Peer","role":"member","permissions":[],"last_read_message_id":8}]',
        },
      );
      HttpOverrides.global = overrides;
      manager.profile = const Profile(
        id: 1,
        displayName: 'Me',
        bio: '',
        handles: [],
      );

      final early = _message(id: 8, chatId: 9001, senderId: 1, text: 'early');
      final latest = _message(
        id: 10,
        chatId: 9001,
        senderId: 1,
        text: 'latest',
      );
      final future = _message(
        id: 12,
        chatId: 9001,
        senderId: 1,
        text: 'future',
      );

      // Until the member cursors load, the message's own snapshot is the only
      // source and this helper defers to it.
      expect(manager.readCountForMessage(early), isNull);

      await manager.refreshReadCursors(9001);
      expect(manager.readCountForMessage(early), 2); // both cursors reach id 8
      expect(manager.readCountForMessage(latest), 1); // only this member (10)
      expect(manager.readCountForMessage(future), 0); // nobody has got there

      // The peer catches up to the newest message.
      manager.onReadReceipt(
        const ReadReceipt(
          chatId: 9001,
          userId: 2,
          lastReadMessageId: 12,
          readCount: 2,
          memberCount: 2,
        ),
      );
      expect(manager.readCountForMessage(latest), 2);
      expect(manager.readCountForMessage(future), 1); // only the peer so far

      // A stale or out-of-order receipt must not pull the cursor backwards.
      manager.onReadReceipt(
        const ReadReceipt(
          chatId: 9001,
          userId: 2,
          lastReadMessageId: 5,
          readCount: 1,
        ),
      );
      expect(manager.readCountForMessage(latest), 2);
    },
  );

  testWidgets('long press starts multi-select and swaps the app bar', (
    tester,
  ) async {
    login();
    await openChat(tester, 4248);
    manager.onIncomingMessage(
      _message(id: 30, chatId: 4248, senderId: 99, text: 'first thing'),
    );
    manager.onIncomingMessage(
      _message(id: 31, chatId: 4248, senderId: 99, text: 'second thing'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    // Nothing is selected yet, so the ordinary chat app bar is showing.
    expect(find.text('first thing'), findsOneWidget);
    expect(find.text('Test chat'), findsOneWidget);
    expect(find.textContaining('selected'), findsNothing);

    await tester.longPress(find.text('first thing'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    // The selection bar replaces the chat title.
    expect(find.text('Test chat'), findsNothing);

    // Tapping another message adds it instead of opening the action menu.
    await tester.tap(find.text('second thing'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Reply'), findsNothing);

    // The stop button leaves selection mode and restores the chat app bar.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);
    expect(find.text('Test chat'), findsOneWidget);
  });

  testWidgets('right click opens the message action menu at the pointer', (
    tester,
  ) async {
    login();
    await openChat(tester, 4249);
    manager.onIncomingMessage(
      _message(id: 40, chatId: 4249, senderId: 99, text: 'menu target'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    await tester.tap(find.text('menu target'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Choosing Select switches into multi-select with this message picked.
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });

  group('sticker gestures in a message', () {
    /// The routes a message that mentions `<ugc:5>` needs: the item itself, the
    /// pack it belongs to, and the caller's saved packs.
    Map<String, String> ugcRoutes({bool packSaved = true}) => {
      '/v1/ugc/items/5': jsonEncode(_sticker(5)),
      '/v1/ugc/packs/1': jsonEncode(_pack(1, 'Cats')),
      '/v1/ugc/favorites/packs': jsonEncode(
        packSaved ? [_pack(1, 'Cats')] : <dynamic>[],
      ),
    };

    /// Runs [body] with a desktop platform pinned.
    ///
    /// Tests otherwise report themselves as Android, which is the touch case.
    /// The override is cleared before [body] returns, because the framework
    /// checks for changed debug variables before tear-downs run.
    Future<void> asDesktop(Future<void> Function() body) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await body();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    /// Leaves the shared router outside the chat route.
    ///
    /// A test that ends inside a chat the next test's routes do not serve would
    /// otherwise have its screen re-mounted there and fail on `GET /chats/<id>`.
    Future<void> leaveChat(WidgetTester tester) async {
      router.go('/');
      await tester.pumpAndSettle();
    }

    /// Opens [chatId] holding one message and returns the transport behind it.
    ///
    /// The transport is installed globally as well as inside the app's zone,
    /// because the popup's own requests start from a tap, which runs outside
    /// `mountApp`'s zone.
    Future<FakeApiHttpOverrides> openWithMessage(
      WidgetTester tester, {
      required int chatId,
      required int messageId,
      required String text,
      bool packSaved = true,
    }) async {
      login();
      final api = FakeApiHttpOverrides(routes: ugcRoutes(packSaved: packSaved));
      HttpOverrides.global = api;
      await openChat(tester, chatId, apiOverrides: api);
      manager.onIncomingMessage(
        _message(id: messageId, chatId: chatId, senderId: 99, text: text),
      );
      await tester.pump();
      await tester.pump(_debounce);
      return api;
    }

    testWidgets('a tap on an emoji opens its popup, which inserts it', (
      tester,
    ) async {
      await openWithMessage(
        tester,
        chatId: 4260,
        messageId: 70,
        text: 'look <ugc:5> here',
      );
      expect(find.byType(UgcView), findsOneWidget);

      await tester.tap(find.byType(UgcView));
      await tester.pumpAndSettle();

      // The popup names the pack and the sticker, the same pair the picker's
      // popup shows.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cats'),
        ),
        findsOneWidget,
      );
      expect(find.text('Wave 5'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Insert'));
      await tester.pumpAndSettle();

      expect(composerText(tester), '<ugc:5>');
      await leaveChat(tester);
    });

    testWidgets('a tap on a sticker drop offers the same popup', (tester) async {
      await openWithMessage(
        tester,
        chatId: 4261,
        messageId: 71,
        text: '<ugc:5>',
      );

      await tester.tap(find.byType(UgcView));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cats'),
        ),
        findsOneWidget,
      );
      await leaveChat(tester);
    });

    testWidgets('the popup heart saves the sticker pack', (tester) async {
      final api = await openWithMessage(
        tester,
        chatId: 4262,
        messageId: 72,
        text: '<ugc:5>',
        packSaved: false,
      );

      await tester.tap(find.byType(UgcView));
      await tester.pumpAndSettle();

      // Nothing has saved this pack yet, so the heart offers to.
      await tester.tap(find.byTooltip('Save pack'));
      await tester.pumpAndSettle();

      expect(
        api.requests.any(
          (r) => r.method == 'POST' && r.path == '/v1/ugc/favorites/packs',
        ),
        isTrue,
      );
      await leaveChat(tester);
    });

    testWidgets('a long press on a touch device opens the message menu', (
      tester,
    ) async {
      await openWithMessage(
        tester,
        chatId: 4263,
        messageId: 73,
        text: '<ugc:5>',
      );

      await tester.longPress(find.byType(UgcView));
      await tester.pumpAndSettle();

      // The sticker's long press is the menu, not the start of multi-select.
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
      await leaveChat(tester);
    });

    testWidgets('on a desktop a long press still starts a selection', (
      tester,
    ) async {
      await asDesktop(() async {
        await openWithMessage(
          tester,
          chatId: 4264,
          messageId: 74,
          text: '<ugc:5>',
        );

        await tester.longPress(find.byType(UgcView));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Reply'), findsNothing);
      });
      await leaveChat(tester);
    });

    testWidgets('on a desktop the menu comes from the right click', (
      tester,
    ) async {
      await asDesktop(() async {
        await openWithMessage(
          tester,
          chatId: 4265,
          messageId: 75,
          text: '<ugc:5>',
        );

        await tester.tap(find.byType(UgcView), buttons: kSecondaryButton);
        await tester.pumpAndSettle();

        expect(find.text('Reply'), findsOneWidget);
      });
      await leaveChat(tester);
    });
  });

  testWidgets('a forwarded message shows the forwarded label', (tester) async {
    login();
    const chatId = 4251;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId/messages':
            '[{"id":60,"chat_id":$chatId,"sender_id":99,"text":"copied text","forwarded":42,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    expect(find.text('copied text'), findsOneWidget);
    expect(find.text('Forwarded'), findsOneWidget);

    // The router is shared across tests, so leave the chat route for the next.
    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('forwarding a message posts a manifest for the picked chat', (
    tester,
  ) async {
    login();
    const chatId = 4252;
    const targetId = 8001;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats':
            '[{"id":$chatId,"chat_type":"chat","display_name":"Test chat","handles":[],"created_at":"2026-01-01T00:00:00Z"},'
            '{"id":$targetId,"chat_type":"chat","display_name":"Target chat","handles":[],"created_at":"2026-01-01T00:00:00Z"}]',
        'POST /v1/chats/$targetId/messages':
            '{"id":900,"chat_id":$targetId,"sender_id":1,"text":"please forward me","forwarded":50,"created_at":"2026-01-01T00:00:00Z"}',
      },
    );
    // The picker is driven from a tap, which runs outside mountApp's zone and
    // would otherwise reach the empty global fallback instead of these routes.
    HttpOverrides.global = api;
    await openChat(tester, chatId, apiOverrides: api);
    manager.onIncomingMessage(
      _message(id: 50, chatId: chatId, senderId: 99, text: 'please forward me'),
    );
    await tester.pump();
    await tester.pump(_debounce);
    // The destination list is the chat list; seed it so the picker does not
    // depend on a refresh having landed.
    manager.chats = [
      ChatInfo(
        id: chatId,
        chatType: 'chat',
        displayName: 'Test chat',
        bio: '',
        handles: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      ChatInfo(
        id: targetId,
        chatType: 'chat',
        displayName: 'Target chat',
        bio: '',
        handles: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    await tester.tap(find.text('please forward me'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    // The menu's Forward entry opens the destination picker instead of the
    // placeholder "not available" response.
    await tester.tap(find.text('Forward'));
    await tester.pumpAndSettle();
    expect(find.text('Forward to'), findsOneWidget);

    // The chat list behind the dialog can show the same title, so tap the row
    // inside the picker itself.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Target chat'),
      ),
    );
    await tester.pumpAndSettle();

    final post = api.requests.firstWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/v1/chats/$targetId/messages',
    );
    expect(post.body, contains('"forward"'));
    expect(post.body, contains('"chat_id":$chatId'));
    expect(post.body, contains('"message_id":50'));
    expect(post.body, contains('"forward_message_id":50'));
    // The confirmation shows on the chat's Scaffold (and the list's Scaffold on
    // a wide layout), so more than one copy can be present.
    expect(find.text('Forwarded to Target chat'), findsWidgets);

    // The router is shared across tests, so leave the chat route for the next.
    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('the selection bar forwards every selected message', (
    tester,
  ) async {
    login();
    const chatId = 4253;
    const targetId = 8002;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats':
            '[{"id":$chatId,"chat_type":"chat","display_name":"Test chat","handles":[],"created_at":"2026-01-01T00:00:00Z"},'
            '{"id":$targetId,"chat_type":"chat","display_name":"Target chat","handles":[],"created_at":"2026-01-01T00:00:00Z"}]',
        'POST /v1/chats/$targetId/messages':
            '{"id":900,"chat_id":$targetId,"sender_id":1,"text":"","created_at":"2026-01-01T00:00:00Z"}',
      },
    );
    HttpOverrides.global = api;
    await openChat(tester, chatId, apiOverrides: api);
    manager.onIncomingMessage(
      _message(id: 70, chatId: chatId, senderId: 99, text: 'first thing'),
    );
    manager.onIncomingMessage(
      _message(id: 71, chatId: chatId, senderId: 99, text: 'second thing'),
    );
    await tester.pump();
    await tester.pump(_debounce);
    manager.chats = [
      ChatInfo(
        id: chatId,
        chatType: 'chat',
        displayName: 'Test chat',
        bio: '',
        handles: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      ChatInfo(
        id: targetId,
        chatType: 'chat',
        displayName: 'Target chat',
        bio: '',
        handles: const [],
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    await tester.longPress(find.text('first thing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('second thing'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Forward').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Target chat'),
      ),
    );
    await tester.pumpAndSettle();

    final posts = api.requests
        .where(
          (request) =>
              request.method == 'POST' &&
              request.path == '/v1/chats/$targetId/messages',
        )
        .toList();
    expect(posts, hasLength(2));
    expect(posts[0].body, contains('"message_id":70'));
    expect(posts[1].body, contains('"message_id":71'));
    // A completed forward leaves multi-select behind.
    expect(find.textContaining('selected'), findsNothing);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('replying quotes the target and sends it as reply_to', (
    tester,
  ) async {
    login();
    const chatId = 4254;
    final api = FakeApiHttpOverrides(
      routes: {
        'POST /v1/chats/$chatId/messages':
            '{"id":901,"chat_id":$chatId,"sender_id":1,"text":"my answer","replied":80,"created_at":"2026-01-01T00:00:00Z"}',
      },
    );
    HttpOverrides.global = api;
    await openChat(tester, chatId, apiOverrides: api);
    manager.onIncomingMessage(
      _message(id: 80, chatId: chatId, senderId: 99, text: 'original text'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    await tester.tap(find.text('original text'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    // The composer shows the quote while the answer is being written: the text
    // is now in both the original bubble and the banner.
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('original text'), findsNWidgets(2));

    await enterComposerText(tester, 'my answer');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    final post = api.requests.firstWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/v1/chats/$chatId/messages',
    );
    expect(post.body, contains('"reply_to":80'));

    // The sent bubble quotes the parent, and the composer is back to a plain
    // send: the quoted text now appears both in the original and in the reply.
    expect(find.text('my answer'), findsOneWidget);
    expect(find.text('original text'), findsNWidgets(2));
    expect(find.text('Reply'), findsNothing);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('dismissing the reply banner leaves a plain send', (
    tester,
  ) async {
    login();
    const chatId = 4255;
    final api = FakeApiHttpOverrides(
      routes: {
        'POST /v1/chats/$chatId/messages':
            '{"id":902,"chat_id":$chatId,"sender_id":1,"text":"my answer","created_at":"2026-01-01T00:00:00Z"}',
      },
    );
    HttpOverrides.global = api;
    await openChat(tester, chatId, apiOverrides: api);
    manager.onIncomingMessage(
      _message(id: 81, chatId: chatId, senderId: 99, text: 'original text'),
    );
    await tester.pump();
    await tester.pump(_debounce);

    await tester.tap(find.text('original text'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);

    await enterComposerText(tester, 'my answer');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    final post = api.requests.firstWhere(
      (request) =>
          request.method == 'POST' &&
          request.path == '/v1/chats/$chatId/messages',
    );
    expect(post.body, isNot(contains('reply_to')));

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a reply to an unloaded message falls back to a label', (
    tester,
  ) async {
    login();
    const chatId = 4256;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId/messages':
            '[{"id":82,"chat_id":$chatId,"sender_id":99,"text":"my answer","replied":7,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    // Message 7 is not in the loaded page, so the quote cannot be resolved.
    expect(find.text('my answer'), findsOneWidget);
    expect(find.text('Original message'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a direct-chat message shows a double tick once the peer reads it', (
    tester,
  ) async {
    login();
    const chatId = 4250;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId':
            '{"id":$chatId,"chat_type":"dm","peer_user_id":2,"display_name":"Peer","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
        '/v1/chats/$chatId/messages':
            '[{"id":5,"chat_id":$chatId,"sender_id":1,"text":"hi there","read_count":2,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    expect(find.text('hi there'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a direct-chat message shows a single tick until the peer reads it', (
    tester,
  ) async {
    login();
    const chatId = 4251;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId':
            '{"id":$chatId,"chat_type":"dm","peer_user_id":2,"display_name":"Peer","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
        '/v1/chats/$chatId/messages':
            '[{"id":6,"chat_id":$chatId,"sender_id":1,"text":"not yet","read_count":1,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    expect(find.text('not yet'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNothing);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('forceReadCount shows the reader number in a direct chat', (
    tester,
  ) async {
    login();
    manager.forceReadCount = true;
    const chatId = 4253;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId':
            '{"id":$chatId,"chat_type":"dm","peer_user_id":2,"display_name":"Peer","bio":"","permissions":[],"created_at":"2026-01-01T00:00:00Z","handles":[]}',
        '/v1/chats/$chatId/messages':
            '[{"id":8,"chat_id":$chatId,"sender_id":1,"text":"counted","read_count":2,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    expect(find.text('counted'), findsOneWidget);
    // The number replaces the tick, so the tick-only layout is gone.
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets('a group message shows how many members have read it', (
    tester,
  ) async {
    login();
    const chatId = 4252;
    final api = FakeApiHttpOverrides(
      routes: {
        '/v1/chats/$chatId/messages':
            '[{"id":7,"chat_id":$chatId,"sender_id":1,"text":"group hi","read_count":3,"created_at":"2026-01-01T00:00:00Z"}]',
      },
    );
    await openChat(tester, chatId, apiOverrides: api);

    expect(find.text('group hi'), findsOneWidget);
    expect(find.byIcon(Icons.remove_red_eye_outlined), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a call started by this client reads Calling until someone joins',
    (tester) async {
      login();
      final overrides = FakeApiHttpOverrides();
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CallScreen(chatId: 4246),
          ),
        );
        await manager.startCall(4246);
        await tester.pump();

        expect(find.text('Calling…'), findsOneWidget);
        expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsNothing);

        await manager.leaveCall();
        await tester.pump();
        expect(find.text('Calling…'), findsNothing);
      }, createHttpClient: (_) => overrides.createHttpClient(null));
    },
  );

  testWidgets('the in-call surface exposes webcam and audio controls', (
    tester,
  ) async {
    login();
    final overrides = FakeApiHttpOverrides();
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CallScreen(chatId: 4246),
        ),
      );
      await manager.startCall(4246);
      await tester.pump();

      // Camera starts off, so the control offers to turn it on.
      expect(find.byTooltip('Camera on'), findsOneWidget);
      expect(find.byTooltip('Share screen'), findsOneWidget);
      expect(find.byTooltip('Mute microphone'), findsOneWidget);

      await manager.leaveCall();
      await tester.pump();
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  });

  test('formatCallDuration grows from mm:ss to hh:mm:ss to dd:hh:mm:ss', () {
    expect(formatCallDuration(const Duration(seconds: 0)), '00:00');
    expect(
      formatCallDuration(const Duration(minutes: 5, seconds: 32)),
      '05:32',
    );
    expect(
      formatCallDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '01:02:03',
    );
    expect(
      formatCallDuration(
        const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
      ),
      '01:02:03:04',
    );
    expect(formatCallDuration(const Duration(days: 3)), '03:00:00:00');
  });
}
