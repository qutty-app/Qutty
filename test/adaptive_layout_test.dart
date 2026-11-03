import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/main.dart';
import 'package:qutty/screens/chat.dart';
import 'package:qutty/screens/chats.dart';
import 'package:qutty/widgets/adaptive.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/home_layout_sync.dart';

/// Drains every exception the test binding recorded, ignoring the debug-only
/// RenderFlex overflow a resize frame can emit before the pages settle.
/// Anything else (the duplicate-key assertions this file guards against) is
/// rethrown through [expect].
void expectNoBuildErrors(WidgetTester tester) {
  final unexpected = <Object>[];
  while (true) {
    final exception = tester.takeException();
    if (exception == null) break;
    final overflow =
        exception is FlutterError && exception.message.contains('overflowed');
    if (!overflow) unexpected.add(exception);
  }
  expect(unexpected, isEmpty);
}

void main() {
  Future<void> pumpRouter(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Mirrors the wrapper RootApp installs around the navigator.
        builder: (context, child) =>
            HomeLayoutSync(router: router, child: child ?? const SizedBox()),
      ),
    );
  }

  testWidgets('wide layout keeps chat list state when switching chats', (
    tester,
  ) async {
    await pumpRouter(tester);
    router.go('/');
    await tester.pump();

    final listState = tester.state(find.byType(ChatsScreen));
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('Select a chat'), findsOneWidget);

    router.go('/chat/1');
    await tester.pump();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Select a chat'), findsNothing);
    expect(
      identical(tester.state(find.byType(ChatsScreen)), listState),
      isTrue,
      reason: 'chat list must not be remounted when opening a chat',
    );

    router.go('/chat/2');
    await tester.pump();

    expect(
      identical(tester.state(find.byType(ChatsScreen)), listState),
      isTrue,
      reason: 'chat list must not be remounted when switching chats',
    );

    router.go('/');
    await tester.pump();

    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('Select a chat'), findsOneWidget);
    expect(
      identical(tester.state(find.byType(ChatsScreen)), listState),
      isTrue,
    );
  });

  testWidgets('narrow layout still pushes a separate chat page', (
    tester,
  ) async {
    await pumpRouter(tester, size: const Size(400, 800));
    router.go('/');
    await tester.pump();

    expect(find.byType(ChatsScreen), findsOneWidget);
    expect(find.byType(ChatScreen), findsNothing);

    router.push('/chat/1');
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(
      find.byType(ChatsScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'narrow layout must keep the chat list page beneath the chat',
    );
  });

  testWidgets('wide layout tolerates a second shell page in the stack', (
    tester,
  ) async {
    await pumpRouter(tester);
    router.go('/chat/1');
    await tester.pump();
    // A stray push while a wide shell is already shown used to give both shell
    // pages the same key and crash the navigator with duplicate page keys.
    router.push('/chat/2');
    await tester.pumpAndSettle();

    expectNoBuildErrors(tester);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('widening collapses a pushed chat back into one shell', (
    tester,
  ) async {
    await pumpRouter(tester, size: const Size(400, 800));
    router.go('/');
    await tester.pump();
    router.push('/chat/1');
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1400, 900);
    await tester.pumpAndSettle();

    expectNoBuildErrors(tester);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/chat/1',
    );
    expect(
      find.byType(ChatsScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'the wide layout must end up with a single two-pane shell',
    );
  });

  testWidgets('wide layout drags the chat list down to an avatar rail', (
    tester,
  ) async {
    await pumpRouter(tester);
    router.go('/');
    await tester.pump();

    final handle = find.byKey(const ValueKey('chat-list-resize-handle'));
    expect(handle, findsOneWidget);
    expect(
      tester.getSize(find.byType(ChatsScreen)).width,
      kChatListDefaultWidth,
    );

    await tester.drag(handle, const Offset(-600, 0));
    // The handle also recognises double-taps, so let its tap timer expire
    // before the test ends.
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(ChatsScreen)).width,
      kChatListMinWidth,
      reason: 'the list must be allowed to collapse to the avatar rail',
    );
  });

  testWidgets('chat list hides its text when the pane is narrow', (
    tester,
  ) async {
    final manager = AppManager.instance;
    final previousChats = manager.chats;
    manager.chats = [
      ChatInfo(
        id: 1,
        chatType: 'chat',
        displayName: 'Chat One',
        bio: '',
        handles: const [],
        createdAt: DateTime.utc(2026, 1, 1),
        lastMessageForDumbAssChatList: 'Hello there',
      ),
    ];
    addTearDown(() => manager.chats = previousChats);

    Widget build(double width) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Center(
        child: SizedBox(width: width, height: 600, child: const ChatsScreen()),
      ),
    );

    await tester.pumpWidget(build(kChatListDefaultWidth));
    await tester.pump();
    expect(find.text('Chat One'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);

    await tester.pumpWidget(build(kChatListMinWidth));
    await tester.pump();
    expect(find.text('Chat One'), findsNothing);
    expect(find.text('Hello there'), findsNothing);
    expect(find.byType(Avatar), findsOneWidget);
  });
}
