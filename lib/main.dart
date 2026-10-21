import 'dart:async';
import 'dart:io' as io;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/router_notifier.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/screens/about_qutty.dart';
import 'package:qutty/screens/auth/login.dart';
import 'package:qutty/screens/call.dart';
import 'package:qutty/screens/chat.dart';
import 'package:qutty/screens/chats.dart';
import 'package:qutty/screens/create_chat_screen.dart';
import 'package:qutty/screens/fallback.dart';
import 'package:qutty/screens/edit_profile.dart';
import 'package:qutty/screens/femboy.dart';
import 'package:qutty/screens/profile.dart';
import 'package:qutty/screens/settings.dart';
import 'package:qutty/screens/customization.dart';
import 'package:qutty/screens/chat_settings.dart';
import 'package:qutty/screens/join_preview.dart';
import 'package:qutty/screens/font_screen.dart';
import 'package:qutty/screens/language_screen.dart';
import 'package:qutty/screens/debug.dart';
import 'package:qutty/screens/ugc_pack_screen.dart';
import 'package:qutty/screens/ugc_portal.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qutty/services/notification_service.dart';
import 'package:qutty/widgets/active_call_bar.dart';
import 'package:qutty/widgets/adaptive.dart';
import 'package:qutty/widgets/api_error_footer.dart';
import 'package:qutty/widgets/call_route_sync.dart';
import 'package:qutty/widgets/home_layout_sync.dart';

final manager = AppManager.instance;
final routerNotifier = RouterNotifier(manager);

final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: routerNotifier,
  redirect: (context, state) {
    if (manager.isLoading) return null;
    final authRoute = state.matchedLocation == '/auth';
    if (!manager.isLoggedIn) return authRoute ? null : '/auth';
    return authRoute ? '/' : null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _homePage(context, state),
    ),
    GoRoute(
      path: '/create-chat',
      builder: (_, state) => CreateChatScreen(
        chatType: state.uri.queryParameters['type'] == 'channel'
            ? 'channel'
            : 'chat',
      ),
    ),
    GoRoute(
      path: '/profile',
      redirect: (BuildContext context, GoRouterState state) {
        final String? currentUserId = AppManager.instance.profile?.id
            .toString();

        if (currentUserId != null) {
          return '/user/$currentUserId';
        } else {
          throw Exception(
            'Incorect state: Refer to binary to find exact asm instruction where it happend and fix it lol',
          );
        }
      },
    ),
    GoRoute(
      path: '/user/:id',
      builder: (_, state) => ProfileScreen(
        id: int.parse(state.pathParameters['id']!),
        type: "user",
      ),
    ),
    GoRoute(path: '/settings/about', builder: (_, _) => SettingsAbout()),
    GoRoute(
      path: '/join-preview',
      builder: (_, state) =>
          JoinPreviewScreen(rawLink: state.uri.queryParameters['link'] ?? ''),
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (_, _) => const EditProfileScreen(chatid: 0),
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/settings/customization',
      builder: (_, _) => const CustomizationScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (_, _) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/settings/font',
      builder: (_, _) => const FontScreen(),
    ),
    GoRoute(
      path: '/settings/developer/ugc',
      builder: (_, _) => const UgcPortalScreen(),
    ),
    GoRoute(
      path: '/uwu/femboy/qutty/rdprojects/67',
      builder: (_, state) => FemboyLegs(),
    ),
    GoRoute(
      path: '/sticker/:id',
      // A hand-typed id that is not a number is nobody's pack; the screen's
      // own failure state is a better answer than an exception here.
      builder: (_, state) => UgcPackScreen(
        packId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
    GoRoute(
      path: '/chat/:id/settings',
      builder: (_, state) =>
          ChatSettingsScreen(chatId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/chat/:id/profile',
      builder: (_, state) => ProfileScreen(
        id: int.parse(state.pathParameters['id']!),
        type: "chat",
      ),
    ),
    GoRoute(
      path: '/call/:id',
      builder: (_, state) =>
          CallScreen(chatId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/chat/:id',
      pageBuilder: (context, state) => _homePage(
        context,
        state,
        chatId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(path: '/settings/dev', builder: (_, state) => DebugSettings()),
  ],
  errorBuilder: (_, state) => NotFoundScreen(error: state.error),
);

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      showUnhandledApiError(details.exception, details.stack);
    };
    runApp(const RootApp());
    unawaited(manager.startNativeCalls());
    try {
      await manager.restore();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app startup',
        ),
      );
      return;
    }
    unawaited(manager.startDeepLinks());
    // Started after runApp so the router exists by the time a notification tap
    // is routed, and so a Firebase failure cannot delay the first frame.
    unawaited(manager.startNotifications());
    // QUTTYDBG temporary
    unawaited(Future.delayed(const Duration(seconds: 10), () async {
      final dbg = io.File('/tmp/qutty_hook.log');
      void log(String m) => dbg.writeAsStringSync('$m\n', mode: io.FileMode.append);
      await NotificationService.instance.initialize();
      final macos = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final perms = await macos?.checkPermissions();
      log(
        'QUTTYDBG perms isEnabled=${perms?.isEnabled} '
        'alert=${perms?.isAlertEnabled} badge=${perms?.isBadgeEnabled} '
        'sound=${perms?.isSoundEnabled}',
      );
      for (var i = 0; i < 3; i++) {
        await NotificationService.instance.show(
          NotificationPayload(
            title: 'QUTTYDBG banner test ${i + 1}',
            body: 'local notification',
            chatId: 1,
          ),
        );
        log('QUTTYDBG posted ${i + 1} at ${DateTime.now().toIso8601String()}');
        await Future.delayed(const Duration(seconds: 7));
      }
    }));
  }, showUnhandledApiError);
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> with WidgetsBindingObserver {
  int _dynamicColorRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    manager.addListener(_handlePendingNotification);
    _handlePendingNotification();
  }

  @override
  void dispose() {
    manager.removeListener(_handlePendingNotification);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        manager.setForeground(true);
        setState(() => _dynamicColorRevision++);
        // A token can rotate while the app is away, and messages sent during a
        // long background spell may only have arrived over FCM.
        unawaited(manager.onResumed());
      case AppLifecycleState.inactive:
        manager.setForeground(false);
      case AppLifecycleState.hidden:
        manager.setForeground(false);
      case AppLifecycleState.paused:
        manager.setForeground(false);
      case AppLifecycleState.detached:
        manager.setForeground(false);
    }
  }

  /// Routes a buffered notification tap.
  ///
  /// The intent is consumed rather than merely observed, so a tap navigates
  /// exactly once even though [AppManager] notifies on every state change.
  /// While logged out the intent is left buffered and this is a no-op: the
  /// pending state has not been routed yet, and sign-in notifies listeners, so
  /// the tap still lands once a session exists.
  void _handlePendingNotification() {
    if (!manager.isLoggedIn || manager.isLoading) return;
    final callChatId = manager.takePendingNativeCallChatId();
    if (callChatId != null) {
      router.go('/call/$callChatId');
      return;
    }
    final chatId = manager.takePendingNotificationChatId();
    if (chatId == null) return;
    router.go('/chat/$chatId');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: manager,
    builder: (context, _) => DynamicColorBuilder(
      key: ValueKey(_dynamicColorRevision),
      builder: (lightDynamic, darkDynamic) {
        const fallback = Color(0xff058deb); // Qutty Blue 3 per design.md.
        final light = _colorScheme(
          brightness: Brightness.light,
          fallback: fallback,
          dynamic: lightDynamic,
        );
        final dark = _colorScheme(
          brightness: Brightness.dark,
          fallback: fallback,
          dynamic: darkDynamic,
        );
        final baseText = Typography.material2021();
        return MaterialApp.router(
          title: 'Qutty',
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          // Null means "follow the device", which is what a user who never
          // touched the language setting expects.
          locale: manager.locale,
          builder: (context, child) => L10nScope(
            child: manager.isLoading
                ? const _StartupScreen()
                : CallRouteSync(
                    router: router,
                    child: HomeLayoutSync(
                      router: router,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
          ),
          themeMode: switch (manager.themePreference) {
            ThemePreference.system => ThemeMode.system,
            ThemePreference.dark => ThemeMode.dark,
            ThemePreference.light => ThemeMode.light,
          },
          theme: _buildTheme(light, baseText),
          darkTheme: _buildTheme(dark, baseText),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    ),
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

ColorScheme _colorScheme({
  required Brightness brightness,
  required Color fallback,
  required ColorScheme? dynamic,
}) {
  final seed = switch (manager.accentPreference) {
    AccentPreference.quttyBlue => fallback,
    AccentPreference.system => null,
    AccentPreference.custom => Color(manager.customAccentColor),
  };
  return seed == null
      ? (dynamic?.harmonized() ??
            ColorScheme.fromSeed(seedColor: fallback, brightness: brightness))
      : ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}

ThemeData _buildTheme(ColorScheme scheme, Typography baseText) {
  final isDark = scheme.brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Null when the user has not chosen a font, which leaves Flutter on the
    // platform's default rather than pinning one.
    fontFamily: manager.fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: baseText.black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: baseText.black.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: scheme.onSurfaceVariant,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurface),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      space: 1,
    ),
  );
}

Page<void> _homePage(BuildContext context, GoRouterState state, {int? chatId}) {
  final focusMessageId = int.tryParse(
    state.uri.queryParameters['message'] ?? '',
  );
  final child = _HomeScreen(chatId: chatId, focusMessageId: focusMessageId);
  if (isWideScreen(context)) {
    // One stable page identity for the whole two-pane layout, so switching
    // chats only swaps the right pane and the chat list keeps its state.
    //
    // A narrow layout can leave more than one shell page in the stack (a chat
    // pushed on top of the list) and widening the window builds them all as
    // shells. Two pages cannot share a key, so every shell after the first
    // falls back to its own key until [HomeLayoutSync] collapses the stack.
    final key = _homeMatchIndex(state) == 0
        ? const ValueKey('home')
        : state.pageKey;
    return NoTransitionPage<void>(key: key, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}

/// Position of [state] among the shell matches in the current route stack.
int _homeMatchIndex(GoRouterState state) {
  var index = 0;
  for (final match in router.routerDelegate.currentConfiguration.matches) {
    if (!isHomeLocation(match.matchedLocation)) continue;
    if (match.matchedLocation == state.matchedLocation &&
        match.pageKey == state.pageKey) {
      return index;
    }
    index++;
  }
  return index;
}

class _HomeScreen extends StatelessWidget {
  final int? chatId;
  final int? focusMessageId;
  const _HomeScreen({this.chatId, this.focusMessageId});

  @override
  Widget build(BuildContext context) {
    final chat = chatId == null
        ? null
        : ChatScreen(
            key: ValueKey(chatId),
            chatId: chatId!,
            focusMessageId: focusMessageId,
          );
    final content = isWideScreen(context)
        ? Row(
            children: [
              const SizedBox(width: 360, child: ChatsScreen()),
              const VerticalDivider(width: 1),
              Expanded(child: chat ?? const _SelectChatPlaceholder()),
            ],
          )
        : chat ?? const ChatsScreen();
    // A live call puts a small bar above whichever chat is open, so the call is
    // never lost by navigating away from it.
    return ActiveCallShell(child: content);
  }
}

class _SelectChatPlaceholder extends StatelessWidget {
  const _SelectChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.selectChat,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
