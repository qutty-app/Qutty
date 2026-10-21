import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How a native screen-picker attempt ended.
enum NativeScreenPickStatus {
  /// The user chose a source; [NativeScreenPick.sourceId] is set when it is a
  /// display, otherwise [NativeScreenPick.label] names the window.
  picked,

  /// The user dismissed the picker.
  cancelled,
}

/// The outcome of asking the OS for a screen-share source on macOS.
class NativeScreenPick {
  const NativeScreenPick({
    required this.status,
    this.sourceId,
    this.isScreen = false,
    this.label,
  });

  final NativeScreenPickStatus status;

  /// The display id (a `CGDirectDisplayID`) when a whole screen was chosen.
  final String? sourceId;

  /// True when a display was chosen rather than a window.
  final bool isScreen;

  /// A human label for a chosen window (its title), used to match it against
  /// the in-app source list.
  final String? label;
}

/// Bridges to the macOS `SCContentSharingPicker` (macOS 14+).
///
/// [pick] returns null whenever the native picker is not available -- a
/// non-macOS platform, macOS before 14, a missing plugin, or a platform error
/// -- so callers can fall back to the in-app source list.
class NativeScreenPicker {
  NativeScreenPicker._();

  static final NativeScreenPicker instance = NativeScreenPicker._();

  static const MethodChannel _channel = MethodChannel('qutty/screen_picker');

  Future<NativeScreenPick?> pick() async {
    if (defaultTargetPlatform != TargetPlatform.macOS) return null;
    Map<String, dynamic>? result;
    try {
      result = await _channel.invokeMapMethod<String, dynamic>('pick');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
    if (result == null) return null;
    switch (result['status'] as String?) {
      case 'picked':
        return NativeScreenPick(
          status: NativeScreenPickStatus.picked,
          sourceId: result['sourceId'] as String?,
          isScreen: result['type'] == 'screen',
          label: result['label'] as String?,
        );
      case 'cancelled':
        return const NativeScreenPick(status: NativeScreenPickStatus.cancelled);
      default:
        return null;
    }
  }
}
