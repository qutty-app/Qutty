import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:qutty/l10n/l10n.dart';

import 'notification_payload.dart';

export 'notification_payload.dart';

/// How a device receives notifications while the app is not in the foreground.
///
/// The transports are not interchangeable, and which ones exist depends on the
/// platform and the build:
///
///  - [apns] is always available on iOS. APNs issues device tokens to any app
///    with the push entitlement without asking which project or team issued it,
///    so an iOS build with a different bundle id or a different signing team
///    still works against this server.
///  - [fcm] needs the app to be registered in one specific Firebase project, so
///    it only works for builds that ship that project's credentials.
///  - [websocket] needs no push service at all. The app holds a socket open, so
///    it works for any build, at the cost of battery and a permanent
///    notification.
enum PushTransport {
  apns('APN'),
  fcm('FCM'),
  websocket('Websocket');

  const PushTransport(this.label);

  /// Short name shown in the debug settings, per the requested display.
  final String label;

  /// Localized explanation of how this transport delivers messages.
  String get description => switch (this) {
    PushTransport.apns => L10n.current.transportApns,
    PushTransport.fcm => L10n.current.transportFcm,
    PushTransport.websocket => L10n.current.transportWebsocket,
  };

  static PushTransport? fromName(String? name) {
    for (final transport in PushTransport.values) {
      if (transport.name == name) return transport;
    }
    return null;
  }
}

/// Owns the native side of one push transport: token acquisition, token
/// refresh, and taps.
///
/// A transport that the current platform or build cannot support reports
/// [isAvailable] false rather than throwing, so the picker can simply hide it.
abstract class PushTransportBinding {
  PushTransportBinding(this.transport);

  final PushTransport transport;

  bool get isAvailable => false;

  /// Starts listening. Safe to call when unavailable, where it does nothing.
  ///
  /// [onOpened] is a tap and routes to a conversation. [onMessage] is a message
  /// that arrived while the app was in the foreground and needs the alert
  /// decision to be made before anything is shown.
  Future<void> start({
    required void Function(String token) onToken,
    required void Function(NotificationPayload) onOpened,
    required void Function(NotificationPayload) onMessage,
  }) async {}

  /// Asks the OS for permission. Returns false when unsupported or denied.
  Future<bool> requestPermission() async => false;

  /// The current registration token, or null when there is none.
  Future<String?> token() async => null;

  /// Releases listeners and channels.
  Future<void> dispose() async {}
}

/// Reports the push notification payload shape shared by every transport.
typedef TransportPayloadBuilder =
    NotificationPayload? Function(Map<String, String?> data);

/// Exposes APNs to Dart through the method channel implemented in
/// `ios/Runner/AppDelegate.swift`.
///
/// The native side is the only thing that can talk to APNs: iOS issues device
/// tokens in response to `registerForRemoteNotifications`, and only the app
/// process receives them. It is also the authority on the bundle id and the APNs
/// environment, so both are read from the token callback rather than hardcoded.
class ApnsBinding extends PushTransportBinding {
  ApnsBinding() : super(PushTransport.apns);

  /// Must match `channelName` in AppDelegate.swift.
  static const MethodChannel channel = MethodChannel('qutty/apns');

  @override
  bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// The most recent token the native side reported. APNs has no "get token"
  /// call, so the value has to be cached from the registration callback to
  /// stay available for re-registration.
  String? _lastToken;

  /// The app identifier this build is signed as, reported by the native side.
  /// The server addresses APNs pushes by it, so a fork has to send its own
  /// rather than have the server assume the official one.
  String? _bundleId;

  /// Whether the token came from Apple's sandbox, which is decided by the
  /// provisioning profile rather than by the build mode.
  bool _sandbox = false;

  /// The bundle id to register with the server, or empty when the token has not
  /// arrived yet.
  String get bundleId => _bundleId ?? '';

  /// Whether the current token belongs to Apple's sandbox.
  bool get sandbox => _sandbox;

  @override
  Future<void> start({
    required void Function(String token) onToken,
    required void Function(NotificationPayload) onOpened,
    required void Function(NotificationPayload) onMessage,
  }) async {
    if (!isAvailable) return;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'token':
          final parsed = _parseToken(call.arguments);
          if (parsed != null) {
            _lastToken = parsed.token;
            _bundleId = parsed.bundleId;
            _sandbox = parsed.sandbox;
            onToken(parsed.token);
          }
        case 'tokenError':
          debugPrint(
            'notifications: APNs registration failed: ${call.arguments}',
          );
        case 'opened':
          final payload = _decodeNativePayload(call.arguments);
          if (payload != null) onOpened(payload);
        case 'message':
          // Arrived while the app was in the foreground. The system banner was
          // suppressed natively so this app could apply its own rule about
          // whether to alert at all.
          final payload = _decodeNativePayload(call.arguments);
          if (payload != null) onMessage(payload);
      }
    });
    // Tells the native side Dart is listening. Anything captured during launch is
    // flushed in response, which is how a cold-start tap survives.
    try {
      await channel.invokeMethod<void>('ready');
    } on PlatformException catch (error) {
      debugPrint('notifications: APNs channel unavailable: ${error.message}');
    } on MissingPluginException {
      // Expected in tests and on a build without the native side.
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!isAvailable) return false;
    try {
      return await channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException catch (error) {
      debugPrint('notifications: APNs permission failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String?> token() async => _lastToken;

  /// The payload arrives as a nested map from the platform channel rather than
  /// a flat string map, so it is flattened before being decoded.
  static NotificationPayload? _decodeNativePayload(Object? arguments) {
    if (arguments is! Map) return null;
    return decodeMessageData(arguments.cast<String, Object?>());
  }

  /// A parsed `token` callback: the device token plus the two facts the server
  /// cannot work out for itself.
  static ({String token, String bundleId, bool sandbox})? _parseToken(
    Object? arguments,
  ) {
    if (arguments is! Map) return null;
    final token = arguments['token']?.toString() ?? '';
    if (token.isEmpty) return null;
    return (
      token: token,
      bundleId: arguments['bundle_id']?.toString() ?? '',
      // readBool rather than casting: a bool crossing the platform channel as
      // a value type is not always a Dart bool.
      sandbox: arguments['sandbox'] == true,
    );
  }
}

/// Exposes Firebase Cloud Messaging to Dart.
class FcmBinding extends PushTransportBinding {
  FcmBinding(this._messaging, {required this.isUsable})
    : super(PushTransport.fcm);

  /// Wraps the Firebase messaging instance.
  ///
  /// [isUsable] reports whether Firebase initialised, which depends on the
  /// build shipping this project's credentials. A fork without them has no FCM
  /// transport, which is the whole reason [PushTransport.websocket] exists.
  final FirebaseMessaging _messaging;
  final bool isUsable;

  @override
  bool get isAvailable => isUsable;

  @override
  Future<void> start({
    required void Function(String token) onToken,
    required void Function(NotificationPayload) onOpened,
    required void Function(NotificationPayload) onMessage,
  }) async {
    if (!isAvailable) return;
    // Foreground: Firebase does not display a notification itself, so the
    // message is handed to the app to decide whether to raise one.
    FirebaseMessaging.onMessage.listen((message) {
      final payload = decodeMessageData({
        ...message.data,
        if (message.notification?.title != null)
          'title': message.notification!.title!,
        if (message.notification?.body != null)
          'body': message.notification!.body!,
      });
      if (payload != null) onMessage(payload);
    });

    // Background and cold-start taps.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = decodeMessageData(message.data);
      if (payload != null) onOpened(payload);
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final payload = decodeMessageData(initial.data);
      if (payload != null) onOpened(payload);
    }

    // A rotated token has to be re-registered or the server keeps pushing to
    // a token the device no longer holds.
    _messaging.onTokenRefresh.listen(onToken);
    final current = await _messaging.getToken();
    if (current != null && current.isNotEmpty) onToken(current);
  }

  @override
  Future<bool> requestPermission() async {
    if (!isAvailable) return false;
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (error) {
      debugPrint('notifications: FCM permission failed: $error');
      return false;
    }
  }

  @override
  Future<String?> token() async {
    if (!isAvailable) return null;
    try {
      return await _messaging.getToken();
    } catch (error) {
      debugPrint('notifications: could not read FCM token: $error');
      return null;
    }
  }
}

/// Decodes the wire format produced by the backend. Returns null for anything
/// that is not a chat message, so an unknown push type is ignored rather than
/// shown as an empty alert.
///
/// The values are typed as [Object] because they arrive from three places with
/// three types: FCM hands over `Map<String, dynamic>`, APNs over an untyped
/// platform-channel map, and a tapped local notification over a JSON object.
NotificationPayload? decodeMessageData(Map<String, Object?> raw) {
  if (raw.isEmpty) return null;
  if ((raw['type']?.toString() ?? '') != 'message') return null;
  final chatId = int.tryParse(raw['chat_id']?.toString() ?? '');
  if (chatId == null) return null;
  final title = raw['title']?.toString().trim() ?? '';
  final sender = raw['sender_name']?.toString().trim() ?? '';
  final text = raw['text']?.toString().trim() ?? '';
  return NotificationPayload(
    title: title.isEmpty ? L10n.current.appName : title,
    body: text.isNotEmpty
        ? text
        : (sender.isEmpty ? L10n.current.notificationNewMessage : sender),
    chatId: chatId,
    messageId: raw['message_id']?.toString().trim(),
  );
}
