import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/session_store.dart';
import '../api/web_socket_service.dart';
import '../l10n/l10n.dart';
import 'background_socket_controller.dart';
import 'push_transport.dart';

/// The Dart entrypoint run by `MessageSocketService` in a background isolate.
///
/// This is the transport that works for every Android build. FCM requires the
/// app to be registered in one specific Firebase project, so a build with a
/// different application id or signature has no FCM token at all. A socket needs
/// nothing from Google, so this connects straight to the server the user is
/// already signed in to.
///
/// It runs headless: the isolate has no UI, so notifications are posted through
/// the local notifications plugin exactly as the foreground path does, and the
/// rules about when to stay quiet are applied from the persisted preference.
@pragma('vm:entry-point')
void notificationSocketMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A background isolate gets no automatic plugin registration, and without
  // this the local notifications plugin is a no-op rather than an error, which
  // would look exactly like a silently broken background connection.
  try {
    DartPluginRegistrant.ensureInitialized();
  } catch (error) {
    debugPrint('backgroundSocket: plugin registration failed: $error');
  }

  final preferences = await SharedPreferences.getInstance();

  // Read before the notifier is built: creating the channel is the first thing
  // that needs a language, and a channel is only created once per install, so
  // a wrong name here would stick in system settings.
  Locale? savedLocale(SharedPreferences preferences) {
    final saved = preferences.getString('qutty.locale');
    if (saved == null) return null;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.toLanguageTag() == saved) return locale;
    }
    return null;
  }

  final notifications = _BackgroundNotifier();
  final l10n = resolveL10n(savedLocale(preferences));
  await notifications.initialize(l10n: l10n);

  // Re-read the preference on every reconnect instead of trusting the value
  // from when the service started: the user can turn notifications off from the
  // app while this isolate is already connected, and the isolate has no
  // ChangeNotifier to tell it.
  bool notificationsEnabled() =>
      preferences.getBool('qutty.notifications_enabled') ?? true;

  String selectedTransport() =>
      preferences.getString('qutty.push_transport') ?? 'websocket';

  final session = await SessionStore.readActive(
    preferences,
    fallbackBaseUrl: const String.fromEnvironment(
      'QUTTY_API_URL',
      defaultValue: 'https://qutty.app',
    ),
  );
  if (session == null) {
    // Signed out, or the session was cleared while the service was running.
    // Stopping the service is what removes the foreground notification;
    // returning alone would leave it behind nothing.
    debugPrint('backgroundSocket: no session, stopping');
    await BackgroundSocketController.stop();
    return;
  }

  debugPrint('backgroundSocket: connected as ${session.label}');

  // The user is never reading a conversation from a headless isolate, so
  // suppression only depends on the preference.
  final socket = WebSocketService(
    baseUrl: session.baseUrl,
    token: session.token,
  );

  socket.events.listen((event) async {
    if (event.opcode == 7) {
      if (event.payload['type'] != 'started' ||
          !notificationsEnabled() ||
          selectedTransport() != 'websocket') {
        return;
      }
      final chatId = (event.payload['chat_id'] as num?)?.toInt();
      if (chatId == null) return;
      final caller = event.payload['display_name'] as String? ?? '';
      await notifications.show(
        NotificationPayload(
          title: l10n.appName,
          body: l10n.chatIncomingCall(caller),
          chatId: chatId,
        ),
      );
      return;
    }
    if (event.opcode != 4) return;
    for (final item in event.payload['messages']) {
      if (item is! Map) continue;
      final data = item.map((key, value) => MapEntry('$key', value));
      final payload = decodeMessageData(data);
      if (payload == null) continue;
      if (!notificationsEnabled()) continue;
      // A transport that the user has not selected must not raise anything:
      // switching to FCM in the debug settings has to actually stop the socket
      // from notifying, and the service is torn down separately.
      if (selectedTransport() != 'websocket') continue;
      await notifications.show(
        NotificationPayload(
          title: payload.title,
          body: payload.body,
          chatId: payload.chatId,
          messageId: payload.messageId,
        ),
      );
    }
  });

  await socket.connect();
}

/// Posts notifications from a headless isolate.
///
/// Deliberately not `NotificationService`: that type is a singleton holding
/// Firebase and permission state for the interactive process, and reaching for
/// it from here would either duplicate it or silently do nothing. What this
/// needs is narrower than what the app needs, so it is implemented separately.
class _BackgroundNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  int _nextId = 0;

  Future<void> initialize({required AppLocalizations l10n}) async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // The channel has to exist before a notification can be posted to it. It
      // is also created by the interactive process, but this isolate can run
      // first after a reboot, so it cannot assume that.
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          'qutty_messages',
          l10n.notificationChannelMessages,
          description: l10n.notificationChannelDescription,
          importance: Importance.high,
        ),
      );
    } catch (error) {
      debugPrint('backgroundSocket: notifications unavailable: $error');
    }
  }

  Future<void> show(NotificationPayload payload) async {
    try {
      await _plugin.show(
        id: ++_nextId,
        title: payload.title,
        body: payload.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'qutty_messages',
            'Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode({
          'type': 'message',
          'chat_id': '${payload.chatId}',
        }),
      );
    } catch (error) {
      debugPrint('backgroundSocket: failed to post notification: $error');
    }
  }
}
