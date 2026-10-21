import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'push_transport.dart';

export 'notification_payload.dart';
export 'push_transport.dart' show PushTransport;

/// Owns everything notification-related: the local notification plugin, the push
/// transports, and the rules for when a message deserves to interrupt the user.
///
/// Every transport is optional and credential-gated, so a checkout with no
/// Firebase config and no APNs entitlement still starts, still shows local
/// notifications, and simply has no way to be reached while backgrounded. That
/// keeps `flutter run` working without any setup.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Must match the channel id the backend pins in its FCM payload, otherwise
  /// Android silently drops background notifications.
  static const String channelId = 'qutty_messages';

  /// Localized: Android shows the channel name in system notification settings.
  static String get channelName => L10n.current.notificationChannelMessages;

  static const String _transportKey = 'qutty.push_transport';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationPayload> _opened =
      StreamController<NotificationPayload>.broadcast();

  final ApnsBinding _apns = ApnsBinding();
  FcmBinding? _fcm;

  bool _initialized = false;
  bool _localReady = false;
  bool _permissionGranted = false;

  /// Called with a fresh token whenever one is available. AppManager owns the
  /// actual server registration, and needs to know which transport produced it.
  void Function(String token, PushTransport transport)? _tokenNotifier;

  /// Emits when the user taps a notification, in either the warm or the cold
  /// start case.
  Stream<NotificationPayload> get onOpened => _opened.stream;

  bool get permissionGranted => _permissionGranted;

  set onTokenRefresh(
    void Function(String token, PushTransport transport)? fn,
  ) => _tokenNotifier = fn;

  /// Consulted before raising an alert for a chat. AppManager owns the rule
  /// (preference enabled, and is the user already reading that chat) so the
  /// socket and push paths cannot drift apart.
  bool Function(int chatId)? shouldNotifyForChat;

  /// Every transport this build and platform can actually *choose*.
  ///
  /// The picker in debug settings renders from this, so an unavailable transport
  /// can never be selected. Note that this is not the same set as
  /// [reportedTransport]: a desktop app has no background transport to choose,
  /// but it still reports one because the socket is what delivers its messages.
  List<PushTransport> get availableTransports => [
    if (_apns.isAvailable) PushTransport.apns,
    if (_fcm?.isAvailable ?? false) PushTransport.fcm,
    if (backgroundSocketAvailable) PushTransport.websocket,
  ];

  /// The transport delivering messages right now, for display.
  ///
  /// Falls back to the socket on platforms that never had a push transport to
  /// choose from. On desktop the app has no meaningful background state, so
  /// there is no background transport to report, but the socket is genuinely
  /// what carries messages and a blank label would be misleading.
  PushTransport? get reportedTransport {
    final selected = _selected;
    if (selected != null) return selected;
    if (isDesktop) return PushTransport.websocket;
    return null;
  }

  /// Whether this is a desktop build, where the app is only ever in the
  /// foreground.
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Whether a notification should be shown for [chatId] right now.
  ///
  /// The rule is: stay quiet while the user is already looking at that exact
  /// conversation. Anything else -- another chat, the chat list, or a
  /// backgrounded app -- is worth an alert.
  bool shouldNotify({
    required bool isForeground,
    int? activeChatId,
    required int chatId,
  }) => !(isForeground && activeChatId == chatId);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocal();
    await _initFirebase();
    await _restoreTransport();
    await _startTransport();
  }

  Future<void> _initLocal() async {
    try {
      tzdata.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        // Asked for explicitly from the settings toggle so the prompt only
        // appears once the user has opted in, rather than on first launch.
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
        defaultPresentAlert: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      );
      await _local.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );

      final androidImpl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            channelName,
            description: L10n.current.notificationChannelDescription,
            importance: Importance.high,
          ),
        );
      }
      _localReady = true;
    } catch (error) {
      debugPrint('notifications: local notifications unavailable: $error');
    }
  }

  /// Firebase is initialised, not required -- and only on Android.
  ///
  /// iOS registers with APNs alone, because APNs is the one push service that
  /// needs nothing from a specific project. Initialising Firebase there would add
  /// a second transport the user did not ask for and make the picker offer a
  /// choice that should not exist.
  ///
  /// On Android it stays opt-in per build: a fork shipping no
  /// `google-services.json` throws here and has no FCM transport at all, which is
  /// what leaves the background socket as its only option.
  Future<void> _initFirebase() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp();
      _fcm = FcmBinding(FirebaseMessaging.instance, isUsable: true);
    } catch (error) {
      // The overwhelmingly common case: no Firebase config in this build.
      debugPrint('notifications: Firebase not configured, FCM disabled');
    }
  }

  Future<void> _restoreTransport() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = PushTransport.fromName(
        preferences.getString(_transportKey),
      );
      // A stored choice that is no longer available must not win: the user may
      // have switched to a build that cannot use it.
      if (stored != null && availableTransports.contains(stored)) {
        _selected = stored;
        return;
      }
      _selected = defaultTransport;
    } catch (error) {
      debugPrint('notifications: could not restore transport: $error');
      _selected = defaultTransport;
    }
  }

  PushTransport? _selected;

  /// The transport in use, or null when this build has none.
  PushTransport? get selectedTransport => _selected;

  /// The transport to use when the user has not chosen one. iOS has APNs and
  /// desktop has only the socket, so on those platforms there is nothing to
  /// choose and this is the only answer.
  PushTransport? get defaultTransport {
    if (_apns.isAvailable) return PushTransport.apns;
    if (_fcm?.isAvailable ?? false) return PushTransport.fcm;
    if (backgroundSocketAvailable) return PushTransport.websocket;
    return null;
  }

  /// Switches transports, re-registering with the server so the old token stops
  /// being used. Returns false when [transport] is not available here.
  Future<bool> selectTransport(PushTransport transport) async {
    if (!availableTransports.contains(transport)) return false;
    if (_selected == transport) return true;
    _selected = transport;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_transportKey, transport.name);
    } catch (error) {
      debugPrint('notifications: could not persist transport: $error');
    }
    await _startTransport();
    return true;
  }

  Future<void> _startTransport() async {
    final transport = _selected;
    if (transport == null) return;
    if (transport == PushTransport.websocket) {
      // The background socket lives in a foreground service and its own isolate,
      // so it survives this process being torn down, and it has no token to
      // register with the server. Starting it is left to the app's lifecycle:
      // the interactive socket is already connected while the app is open, and
      // two live connections would receive every message twice.
      onTransportChanged?.call(transport);
      return;
    }
    final binding = transport == PushTransport.apns ? _apns : _fcm;
    if (binding == null) return;
    await binding.start(
      onToken: (token) => _tokenNotifier?.call(token, transport),
      onOpened: _handleTransportTap,
      onMessage: _handleForegroundMessage,
    );
    onTransportChanged?.call(transport);
  }

  void _handleForegroundMessage(NotificationPayload payload) {
    final chatId = payload.chatId;
    // A transport only asks this app about a message that arrived while it was
    // in the foreground, and deciding whether to interrupt depends on whether
    // the user is already reading that conversation -- state only the app has.
    if (chatId == null) return;
    if (shouldNotifyForChat?.call(chatId) == false) return;
    unawaited(show(payload));
  }

  /// Notifies the owner that the active transport changed, so it can move its
  /// server registration and the background socket accordingly.
  void Function(PushTransport transport)? onTransportChanged;

  /// The registration token for whichever transport is selected, or null when
  /// that transport has no token to register.
  ///
  /// The background socket has none by definition: it receives messages over a
  /// connection the server already has, so there is nothing to look up.
  Future<String?> currentTransportToken() async {
    final transport = _selected;
    if (transport == null || transport == PushTransport.websocket) return null;
    final binding = transport == PushTransport.apns ? _apns : _fcm;
    return binding?.token();
  }

  /// How the server should address the token issued by [transport]: the provider
  /// that issued it, the bundle id it belongs to, and whether it came from
  /// Apple's sandbox.
  ///
  /// The transport is passed rather than read from the current selection so a
  /// registration is always described in terms of the transport that actually
  /// issued the token, even if the user switched transports in between.
  ///
  /// Empty strings are meaningful here rather than errors. FCM has no bundle id
  /// and no environment, and the server falls back to its configured defaults,
  /// so reporting them as absent is what lets one call serve every transport.
  ({String provider, String bundleId, bool sandbox}) tokenContextFor(
    PushTransport transport,
  ) {
    if (transport == PushTransport.apns) {
      return (
        provider: 'apns',
        // Read from the native side rather than hardcoded: a build with a
        // different bundle id has to report its own, and APNs rejects a push
        // whose topic does not match the token.
        bundleId: _apns.bundleId,
        sandbox: _apns.sandbox,
      );
    }
    return (provider: 'fcm', bundleId: '', sandbox: false);
  }

  /// Whether the app can hold a socket open in the background to receive
  /// messages without any push service.
  ///
  /// Android is the platform this is for. Desktop apps have no meaningful
  /// background state, so the socket is already running there and this reports
  /// false rather than pretending to offer a transport.
  bool get backgroundSocketAvailable =>
      !kIsWeb && ( defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS);

  /// Asks the OS for permission to post notifications. Safe to call repeatedly;
  /// the system only prompts once.
  Future<bool> requestPermission() async {
    var granted = _permissionGranted;

    // The local plugin and the push transports each own a separate permission
    // on Android, and neither implies the other: POST_NOTIFICATIONS gates every
    // notification, while the FCM token is obtainable without it.
    try {
      final androidImpl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        granted =
            (await androidImpl.requestNotificationsPermission()) ?? granted;
      }
      // v22 splits the former Darwin plugin into per-platform classes.
      final iosImpl = _local
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImpl != null) {
        granted =
            (await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
            )) ??
            granted;
      }
      final macosImpl = _local
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macosImpl != null) {
        granted =
            (await macosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: true,
            )) ??
            granted;
      }
    } catch (error) {
      debugPrint('notifications: local permission request failed: $error');
    }
    _permissionGranted = granted;

    // The selected transport owns the rest of the prompt, but its absence must
    // not veto the local permission above.
    final transport = _selected;
    if (transport != null) {
      final binding = transport == PushTransport.apns ? _apns : _fcm;
      if (binding != null) {
        _permissionGranted = await binding.requestPermission() || granted;
      }
    }
    return _permissionGranted;
  }

  void _handleTransportTap(NotificationPayload payload) {
    if (_opened.isClosed) return;
    _opened.add(payload);
  }

  void _handleResponse(NotificationResponse response) {
    final payload = decodeMessageData(
      _decodeResponsePayload(response.payload) ?? const {},
    );
    if (payload == null || _opened.isClosed) return;
    _opened.add(payload);
  }

  /// The plugin stores the tap payload as a JSON string.
  ///
  /// Only the routing keys are written when raising the notification, so this
  /// yields a map with no display text. [decodeMessageData] fills in placeholders
  /// for the parts a tap does not need, and an empty map decodes to null because
  /// there is nothing to route to.
  Map<String, Object?>? _decodeResponsePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map((key, value) => MapEntry('$key', value as Object?));
    } catch (error) {
      debugPrint('notifications: unreadable tap payload: $error');
      return null;
    }
  }

  /// Message ids already alerted on, bounded so a long session cannot grow this
  /// without limit.
  final Set<String> _recentlyShown = <String>{};
  static const int _recentlyShownLimit = 100;

  /// Posts a notification immediately. No-op when the plugin failed to
  /// initialise, so a missing platform implementation cannot break messaging.
  ///
  /// [NotificationPayload.messageId] collapses the two delivery paths into one
  /// alert: a message that arrives over both the socket and a push transport
  /// carries the same id and is only shown once.
  Future<void> show(NotificationPayload payload) async {
    if (!_localReady) return;
    final messageId = payload.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      if (!_recentlyShown.add(messageId)) return;
      if (_recentlyShown.length > _recentlyShownLimit) {
        _recentlyShown.remove(_recentlyShown.first);
      }
    }
    try {
      await requestPermission();
      await _local.show(
        id: _nextNotificationId(),
        title: payload.title,
        body: payload.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(payload.body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            presentBanner: true,
            interruptionLevel: InterruptionLevel.active,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentBanner: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        // The plugin carries the payload as a JSON string, so the tap handler
        // has to decode it back before routing.
        payload: jsonEncode({
          'type': 'message',
          'chat_id': payload.chatId,
          'message_id': payload.messageId,
        }),
      );
    } catch (error) {
      debugPrint('notifications: failed to post notification: $error');
    }
  }

  int _notificationId = 0;

  /// A distinct id per notification, otherwise a new message replaces the
  /// previous alert in the shade instead of stacking.
  int _nextNotificationId() => ++_notificationId;

  /// The platform string the backend records against a device token.
  static Future<String> currentPlatform() async {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  static Future<String> currentAppVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return '';
    }
  }

  void dispose() {
    if (!_opened.isClosed) _opened.close();
  }
}
