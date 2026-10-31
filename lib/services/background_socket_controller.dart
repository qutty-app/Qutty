import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Starts and stops the Android foreground service that holds the websocket.
///
/// Only the platform side can do this, so every call is best-effort: on iOS and
/// desktop the transport does not exist and there is nothing to start, which is a
/// normal state rather than a failure to report.
class BackgroundSocketController {
  const BackgroundSocketController._();

  /// Must match the channel implemented in `MainActivity.kt`.
  static const MethodChannel channel = MethodChannel('qutty/background_socket');

  /// Whether this platform can hold a background socket at all.
  ///
  /// The check is duplicated in the native side as well, because the native side
  /// is what actually decides; this only avoids a pointless channel call.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> start() async {
    if (!isSupported) return false;
    return _invoke('start');
  }

  /// Asks the platform to let this app run in the background without limits,
  /// which is what the debug "keep websocket alive" switch relies on before the
  /// background socket is allowed to hold a connection open.
  static Future<bool> requestBackgroundUnlimited() async {
    if (!isSupported) return false;
    return _invoke('requestBackgroundUnlimited');
  }

  static Future<bool> stop() async {
    if (!isSupported) return false;
    return _invoke('stop');
  }

  static Future<bool> _invoke(String method, [dynamic arguments]) async {
    try {
      return await channel.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException catch (error) {
      debugPrint('backgroundSocket: $method failed: ${error.message}');
      return false;
    } on MissingPluginException {
      // A build without the native side, or a test.
      return false;
    }
  }
}
