import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../l10n/l10n.dart';

enum NativeCallActionType { accepted, declined, ended, timedOut }

class NativeCallAction {
  const NativeCallAction({required this.type, required this.chatId});

  final NativeCallActionType type;
  final int chatId;
}

class NativeCallService {
  NativeCallService._();

  static final NativeCallService instance = NativeCallService._();

  final StreamController<NativeCallAction> _actions =
      StreamController<NativeCallAction>.broadcast();
  final Map<int, String> _callIds = {};
  final Map<String, int> _chatIds = {};
  StreamSubscription<CallEvent?>? _eventSubscription;
  bool _initialized = false;
  bool _androidPermissionsRequested = false;

  @visibleForTesting
  bool enableNativeCalls = true;

  Stream<NativeCallAction> get actions => _actions.stream;

  bool get isSupported =>
      enableNativeCalls &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    _eventSubscription = FlutterCallkitIncoming.onEvent.listen(
      handleNativeEvent,
      onError: (Object error) {
        debugPrint('nativeCalls: event stream failed: $error');
      },
    );
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _initialized = false;
  }

  Future<void> showIncoming({
    required int chatId,
    required int userId,
    required String displayName,
  }) async {
    if (!isSupported) return;
    await initialize();
    final id = _callIds.putIfAbsent(chatId, _newCallId);
    _chatIds[id] = chatId;
    if (defaultTargetPlatform == TargetPlatform.android &&
        !_androidPermissionsRequested) {
      _androidPermissionsRequested = true;
      try {
        await FlutterCallkitIncoming.requestNotificationPermission({
          'title': L10n.current.appName,
          'rationaleMessagePermission':
              L10n.current.notificationChannelDescription,
          'postNotificationMessageRequired':
              L10n.current.notificationChannelDescription,
        });
        await FlutterCallkitIncoming.requestFullIntentPermission();
      } catch (error) {
        debugPrint('nativeCalls: permission request failed: $error');
      }
    }
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: id,
          nameCaller: displayName,
          appName: 'Qutty',
          handle: 'Chat $chatId',
          type: 0,
          duration: 60000,
          extra: <String, dynamic>{'chat_id': chatId, 'user_id': userId},
          android: AndroidParams(
            isCustomNotification: true,
            isShowCallID: false,
            isFullScreen: true,
            isImportant: true,
            ringtonePath: 'system_ringtone_default',
            incomingCallNotificationChannelName: 'Incoming calls',
            textAccept: L10n.current.chatJoinCall,
            textDecline: L10n.current.chatDismissCall,
          ),
          ios: const IOSParams(
            handleType: 'generic',
            supportsVideo: false,
            includesCallsInRecents: true,
            audioSessionMode: 'default',
          ),
        ),
      );
    } catch (error) {
      debugPrint('nativeCalls: could not show incoming call: $error');
    }
  }

  Future<void> startOutgoing({
    required int chatId,
    required String name,
  }) async {
    if (!isSupported) return;
    await initialize();
    final id = _callIds.putIfAbsent(chatId, _newCallId);
    _chatIds[id] = chatId;
    try {
      await FlutterCallkitIncoming.startCall(
        CallKitParams(
          id: id,
          nameCaller: name,
          appName: 'Qutty',
          handle: 'Chat $chatId',
          type: 1,
          extra: <String, dynamic>{'chat_id': chatId},
          android: const AndroidParams(isShowCallID: false),
          ios: const IOSParams(handleType: 'generic', supportsVideo: false),
        ),
      );
    } catch (error) {
      debugPrint('nativeCalls: could not start outgoing call UI: $error');
    }
  }

  Future<void> markConnected(int chatId) async {
    final id = _callIds[chatId];
    if (id == null || !isSupported) return;
    try {
      await FlutterCallkitIncoming.setCallConnected(id);
    } catch (error) {
      debugPrint('nativeCalls: could not mark call connected: $error');
    }
  }

  Future<void> endChatCall(int chatId) async {
    final id = _callIds.remove(chatId);
    if (id == null || !isSupported) return;
    _chatIds.remove(id);
    try {
      await FlutterCallkitIncoming.endCall(id);
    } catch (error) {
      debugPrint('nativeCalls: could not end native call UI: $error');
    }
  }

  @visibleForTesting
  void handleNativeEvent(CallEvent? event) {
    if (event == null) return;
    final chatId = switch (event) {
      CallEventActionCallAccept(:final callKitParams) => _chatIdFor(
        callKitParams.id,
        callKitParams.extra,
      ),
      CallEventActionCallDecline(:final callKitParams) => _chatIdFor(
        callKitParams.id,
        callKitParams.extra,
      ),
      CallEventActionCallEnded(:final callKitParams) => _chatIdFor(
        callKitParams.id,
        callKitParams.extra,
      ),
      CallEventActionCallTimeout(:final id) => _chatIdFor(id, null),
      _ => null,
    };
    if (chatId == null) return;
    final action = switch (event) {
      CallEventActionCallAccept() => NativeCallActionType.accepted,
      CallEventActionCallDecline() => NativeCallActionType.declined,
      CallEventActionCallEnded() => NativeCallActionType.ended,
      CallEventActionCallTimeout() => NativeCallActionType.timedOut,
      _ => null,
    };
    if (action != null && !_actions.isClosed) {
      _actions.add(NativeCallAction(type: action, chatId: chatId));
    }
  }

  int? _chatIdFor(String id, Map<String, dynamic>? extra) {
    final saved = _chatIds[id];
    if (saved != null) return saved;
    final value = extra?['chat_id'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _newCallId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
