import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/main.dart';
import 'package:qutty/screens/chat.dart';
import 'package:qutty/screens/chats.dart';
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
}
