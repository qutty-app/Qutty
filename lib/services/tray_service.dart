import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Owns the native tray icon and the "hide to tray" behaviour.
///
/// On Windows and Linux the close button minimizes to a tray icon instead of
/// ending the process, so the websocket stays connected and local notifications
/// keep arriving with no window on screen. The native runner decides what
/// "closed" means -- this class only tells it whether that mode is on and
/// receives a request when the user asks for the window back.
///
/// macOS keeps its own Dock behaviour, so every call here is a no-op there and
/// on any build without the runner-side channel.
class TrayService {
  TrayService._();

  static final TrayService instance = TrayService._();

  /// Must match `kTrayChannel` in the Windows and Linux runners.
  static const MethodChannel _channel = MethodChannel('qutty/tray');

  /// Set once the native side has reported a tray icon, so the settings screen
  /// can hide the toggle on platforms that have none.
  bool _available = false;
  bool get isAvailable => _available;

  /// True on the two platforms whose runners implement the tray.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Asks the native side for the current state. Called once at startup: the
  /// runner can also report the state back, but a first read makes the Dart
  /// value right even when a frame arrived before this object existed.
  Future<void> initialize() async {
    if (!isSupported) return;
    try {
      _channel.setMethodCallHandler(_handleNativeCall);
    } on MissingPluginException {
      return;
    }
    try {
      _available = await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      // A build whose runner predates the tray, or a test.
      _available = false;
    } on PlatformException catch (error) {
      debugPrint('tray: availability check failed: ${error.message}');
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'restore':
        // The user double-clicked the tray icon while the window was hidden.
        // The runner shows the window on its own; Dart only needs to know so
        // any future "open chat from tray" action has a hook.
        _windowRestoreController.add(null);
      case 'availability':
        _available = call.arguments == true;
    }
    return null;
  }

  final _windowRestoreController = StreamController<void>.broadcast();

  /// Emits whenever the native side brought the window back from the tray.
  Stream<void> get onRestore => _windowRestoreController.stream;

  /// Tells the runner whether closing the window should hide it to the tray.
  ///
  /// The runner also persists this in SharedPreferences from Dart, but it has
  /// to be pushed down because the window procedure runs outside Flutter and
  /// cannot read Dart's preferences object.
  Future<void> setCloseToTray(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setCloseToTray', enabled);
    } on MissingPluginException {
      // Nothing to tell.
    } on PlatformException catch (error) {
      debugPrint('tray: could not set close-to-tray: ${error.message}');
    }
  }

  /// Hides the window without ending the process, for the "hide" menu item.
  Future<void> hideWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('hide');
    } on MissingPluginException {
      // Nothing to hide.
    } on PlatformException catch (error) {
      debugPrint('tray: could not hide window: ${error.message}');
    }
  }

  /// Shows the window again, e.g. after a notification tap.
  Future<void> showWindow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('show');
    } on MissingPluginException {
      // Nothing to show.
    } on PlatformException catch (error) {
      debugPrint('tray: could not show window: ${error.message}');
    }
  }

  void dispose() {
    if (!_windowRestoreController.isClosed) _windowRestoreController.close();
  }
}