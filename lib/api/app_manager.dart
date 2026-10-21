import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app_links/app_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'
    show Helper, desktopCapturer, SourceType;
import 'package:audioplayers/audioplayers.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../services/background_socket_controller.dart';
import '../services/custom_fonts.dart';
import '../services/native_call_service.dart';
import '../services/notification_service.dart';
import 'api_service.dart';
import 'join_link.dart';
import 'session_store.dart';
import 'ugc_link.dart';
import 'ugc_tags.dart';
import 'web_socket_service.dart';

enum ThemePreference { system, dark, light }

enum AccentPreference { quttyBlue, system, custom }

/// One screen or window offered by the desktop screen-share picker.
class ScreenShareSource {
  const ScreenShareSource({
    required this.id,
    required this.name,
    required this.isScreen,
    this.thumbnail,
  });

  /// The native source id passed to the capturer as the device id.
  final String id;
  final String name;

  /// True for a whole screen, false for a single window.
  final bool isScreen;

  /// A JPEG thumbnail when the platform provides one (Windows/Linux).
  final Uint8List? thumbnail;
}

class VoiceCallEvent {
  final String type;
  final int chatId;
  final int userId;
  final String displayName;

  const VoiceCallEvent({
    required this.type,
    required this.chatId,
    required this.userId,
    required this.displayName,
  });

  factory VoiceCallEvent.fromJson(Map<String, dynamic> json) => VoiceCallEvent(
    type: json['type'] as String? ?? '',
    chatId: (json['chat_id'] as num).toInt(),
    userId: (json['user_id'] as num).toInt(),
    displayName: json['display_name'] as String? ?? '',
  );
}

/// The call this client is currently connected to.
///
/// Lives on [AppManager] rather than a screen so the call survives navigating
/// between chats: the LiveKit room is connected once, and every surface (the
/// `/call/:id` page and the minimised top bar) reads the same session.
class ActiveCall {
  ActiveCall({
    required this.chatId,
    required this.ownsCall,
    required this.displayName,
    this.avatarUrl = '',
    this.isDirect = false,
  });

  final int chatId;

  /// True when this client started the call and is therefore allowed to end it
  /// for everyone, rather than merely leaving.
  final bool ownsCall;
  final String displayName;

  /// Whether the call is in a direct (one-to-one) chat, which keeps the large
  /// stage layout; group calls use the slot layout instead.
  final bool isDirect;

  /// The chat's picture, shown in place of a generic call icon.
  final String avatarUrl;

  Room? room;
  bool connecting = true;
  bool microphoneEnabled = true;
  bool cameraEnabled = false;
  bool screenShareEnabled = false;
  bool speakerEnabled = true;

  /// When the second participant joined, or null while the call is still
  /// waiting for someone else to pick up. Until then the call is only ringing
  /// out and is subject to [AppManager._callJoinTimeout].
  DateTime? activeSince;

  /// Listener kept so it can be detached from the room before disconnecting.
  VoidCallback? participantListener;

  /// True while the call is collapsed to the small bar. The full `/call/:id`
  /// page is shown only while this is false.
  bool minimized = false;

  bool get connected => room != null;

  /// Whether a second participant is present, so the timer is running.
  bool get active => activeSince != null;

  /// Time elapsed since the second participant joined.
  Duration get duration {
    final since = activeSince;
    if (since == null) return Duration.zero;
    return DateTime.now().difference(since);
  }
}

/// Formats a call duration as `mm:ss`, widening to `hh:mm:ss` past an hour and
/// `dd:hh:mm:ss` past a day.
String formatCallDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (days > 0) {
    return '${two(days)}:${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  if (hours > 0) {
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

class AppManager extends ChangeNotifier {
  AppManager._();
  static final AppManager instance = AppManager._();

  final ApiService api = ApiService();
  Profile? profile;
  List<ChatInfo> chats = const [];
  List<AccountRecord> accounts = const [];
  String? activeAccountId;

  /// Cached message stream per chat. Use [subscribeMessages] to obtain.
  final Map<int, StreamController<MessageInfo>> _messageStreams = {};

  /// Cached stream of in-place message changes (edits and deletions) per chat.
  /// Use [subscribeMessageChanges] to obtain.
  final Map<int, StreamController<MessageChange>> _messageChangeStreams = {};
  final Map<int, MessageInfo?> _lastMessage = {};
  final Map<int, int> _unread = {};

  /// Read cursor of every member we know about: chatId -> userId -> last read
  /// message id. Seeded from the member list and moved forward by live read
  /// receipts so a message's reader count can be recomputed locally instead of
  /// waiting for the message to be fetched again.
  final Map<int, Map<int, int>> _readCursors = {};

  /// Chats whose member cursors have been loaded. Until a chat is in here its
  /// messages' own snapshot `readCount` is the only source of truth.
  final Set<int> _readCursorsLoaded = {};

  /// UGC items resolved by id, so a message that mentions `<ugc:123>` draws the
  /// sticker without a request per frame. Filled by [ensureUgcItems] and read by
  /// the message renderer.
  final Map<int, UgcItem> _ugcItems = {};

  /// Ids whose fetch is in flight, so a rebuild does not ask twice.
  final Set<int> _ugcItemsLoading = {};

  /// Ids the server could not resolve. Kept so a missing item does not retry on
  /// every rebuild for the life of the process.
  final Set<int> _ugcItemsMissing = {};
  final StreamController<VoiceCallEvent> _voiceCallEvents =
      StreamController<VoiceCallEvent>.broadcast();
  final Map<int, VoiceCallEvent> _activeVoiceCalls = {};
  final Set<int> _dismissedVoiceCalls = {};
  final Set<int> _acceptedNativeVoiceCalls = {};
  ActiveCall? _activeCall;
  AudioPlayer? _voiceRingtonePlayer;
  Timer? _voiceRingtoneFallback;
  bool _voiceRingtoneActive = false;
  int _voiceRingtoneGeneration = 0;

  /// How long a call may ring without a second participant before it is ended.
  static const callJoinTimeout = Duration(seconds: 60);

  /// Fires [callJoinTimeout] after a call connects with nobody else in it.
  Timer? _callJoinTimer;

  /// Ticks once a second while a call is active so the duration on screen
  /// advances even when nothing else changes.
  Timer? _callTicker;

  @visibleForTesting
  bool enableCallRingtone = true;

  /// When false, joining a call adopts the session state without opening a real
  /// LiveKit room. Widget tests use this so they can exercise the call UI
  /// without a media server.
  @visibleForTesting
  bool enableVoiceConnection = true;

  bool isLoading = true;
  WebSocketService? socket;
  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;
  /// A link the OS handed the app -- a chat invite or a shared sticker pack --
  /// waiting for the widget tree to route it.
  String? pendingDeepLink;
  AppLinks? _appLinks;
  StreamSubscription<WsEvent>? _socketSub;
  StreamSubscription<ConnectionStatus>? _socketStatusSub;
  Future<void>? _chatsRefreshInFlight;
  Timer? _chatsRefreshDebounce;
  StreamSubscription<NotificationPayload>? _notificationTapSub;
  StreamSubscription<NativeCallAction>? _nativeCallActionSub;
  int? _pendingNativeCallChatId;

  /// Server-side id of this install's push registration, so the device can be
  /// detached individually rather than wiping every device on the account.
  int? _deviceId;

  /// The transport currently carrying notifications. Null means this build has
  /// no way to be reached while backgrounded, which is not an error state: the
  /// socket still delivers while the app is open.
  PushTransport? _transport;

  /// The transport currently in use, for display in the debug settings.
  PushTransport? get pushTransport => _transport;

  /// Whether the app is in the foreground. Drives whether an incoming message
  /// is worth a local notification.
  bool isForeground = true;

  /// The chat currently on screen, or null when no chat is open. A message for
  /// this chat is not worth notifying about while the app is in the foreground.
  int? activeChatId;

  Stream<VoiceCallEvent> get voiceCallEvents => _voiceCallEvents.stream;

  /// The call this client is connected to, or null when not in a call.
  ActiveCall? get activeCall => _activeCall;

  /// Whether this client is in (or connecting to) a call. Used to ignore
  /// additional incoming calls, matching how a phone only rings one line.
  bool get inActiveCall => _activeCall != null;

  VoiceCallEvent? activeVoiceCallForChat(int chatId) =>
      _activeVoiceCalls[chatId];

  /// Whether [chatId] is a group or channel chat.
  ///
  /// Calls there never ring: no incoming screen, ringtone or native call UI is
  /// raised, and members join manually from the chat. An unknown chat is treated
  /// as direct so a cold-start one-to-one call still rings.
  bool isGroupChat(int chatId) {
    final chat = chats.where((item) => item.id == chatId).firstOrNull;
    return chat != null && chat.chatType != 'dm';
  }

  VoiceCallEvent? incomingVoiceCallForChat(int chatId) {
    final event = _activeVoiceCalls[chatId];
    if (event == null ||
        event.userId == profile?.id ||
        _dismissedVoiceCalls.contains(chatId) ||
        isGroupChat(chatId)) {
      return null;
    }
    return event;
  }

  VoiceCallEvent? get incomingVoiceCall => _activeVoiceCalls.values
      .where(
        (event) =>
            event.userId != profile?.id &&
            !_dismissedVoiceCalls.contains(event.chatId) &&
            !isGroupChat(event.chatId),
      )
      .firstOrNull;

  void dismissIncomingVoiceCall(int chatId) {
    if (!_activeVoiceCalls.containsKey(chatId)) return;
    _dismissedVoiceCalls.add(chatId);
    unawaited(NativeCallService.instance.endChatCall(chatId));
    _syncVoiceRingtone();
    notifyListeners();
  }

  Future<void> startNativeCalls() async {
    final nativeCalls = NativeCallService.instance;
    await nativeCalls.initialize();
    _nativeCallActionSub ??= nativeCalls.actions.listen(
      _handleNativeCallAction,
    );
  }

  int? takePendingNativeCallChatId() {
    final value = _pendingNativeCallChatId;
    _pendingNativeCallChatId = null;
    return value;
  }

  bool consumeAcceptedNativeVoiceCall(int chatId) =>
      _acceptedNativeVoiceCalls.remove(chatId);

  /// Accepts an incoming call from the in-app call page.
  ///
  /// Joins the room directly: the ringing state clears, the call page stays
  /// mounted and switches from its ringing UI to the active-call UI, and the
  /// route is unchanged because it is already `/call/:chatId`.
  Future<void> acceptIncomingVoiceCall(int chatId) => joinCall(chatId);

  /// The name to show for a call: the chat's name when it is known, otherwise a
  /// generic "Conversation" so a call started before the chat list loads still
  /// has something to render.
  String _callDisplayName(int chatId) =>
      chats.where((chat) => chat.id == chatId).firstOrNull?.displayName ??
      L10n.current.chatConversation;

  /// The picture to show for a call: the chat's avatar when it has one, so a
  /// call shows the person rather than a generic handset.
  String avatarUrlForChat(int chatId) =>
      chats.where((chat) => chat.id == chatId).firstOrNull?.avatarUrl ?? '';

  /// Whether [chatId] is a direct chat, which decides the in-call layout.
  bool _callIsDirect(int chatId) =>
      chats.where((chat) => chat.id == chatId).firstOrNull?.chatType == 'dm';

  /// Starts a call in [chatId] and becomes its owner.
  ///
  /// The session is published before the token request so every surface can
  /// show a connecting state, and is rolled back if the server refuses.
  Future<void> startCall(int chatId) async {
    if (_activeCall != null) return;
    final call = ActiveCall(
      chatId: chatId,
      ownsCall: true,
      displayName: _callDisplayName(chatId),
      avatarUrl: avatarUrlForChat(chatId),
      isDirect: _callIsDirect(chatId),
    );
    _activeCall = call;
    notifyListeners();
    try {
      final voice = await api.startVoice(chatId);
      await _connectActiveCall(call, voice);
      if (identical(_activeCall, call) && call.ownsCall && call.connected) {
        await startNativeOutgoingCall(chatId, call.displayName);
      }
    } catch (_) {
      if (identical(_activeCall, call)) {
        _activeCall = null;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Joins the call already ringing in [chatId].
  Future<void> joinCall(int chatId) async {
    if (_activeCall != null) return;
    // A call answered before login (a cold-start native answer) cannot be
    // joined yet; the buffered chat id is consumed once a session exists.
    if (!isLoggedIn) return;
    dismissIncomingVoiceCall(chatId);
    final call = ActiveCall(
      chatId: chatId,
      ownsCall: false,
      displayName: _callDisplayName(chatId),
      avatarUrl: avatarUrlForChat(chatId),
      isDirect: _callIsDirect(chatId),
    );
    _activeCall = call;
    notifyListeners();
    try {
      final voice = await api.voiceToken(chatId);
      await _connectActiveCall(call, voice);
    } catch (_) {
      if (identical(_activeCall, call)) {
        _activeCall = null;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> _connectActiveCall(ActiveCall call, VoiceToken voice) async {
    call.speakerEnabled = callLoudspeaker;
    call.microphoneEnabled = callMicOn;
    if (!enableVoiceConnection) {
      if (!identical(_activeCall, call)) return;
      call.connecting = false;
      // Without a media server there is no participant list to watch. A joiner
      // is treated as already connected to the other side so the UI shows the
      // active-call surface; a call this client started stays in the ringing
      // state, matching a real call nobody has answered yet.
      if (!call.ownsCall) call.activeSince = DateTime.now();
      markNativeVoiceCallConnected(call.chatId);
      notifyListeners();
      return;
    }
    final room = Room();
    await room.connect(voice.url, voice.token);
    if (!identical(_activeCall, call)) {
      await room.disconnect();
      return;
    }
    final participant = room.localParticipant;
    await participant?.setMicrophoneEnabled(
      callMicOn,
      audioCaptureOptions: callAudioCaptureOptions,
    );
    await AudioManager.instance.setSpeakerOutputPreferred(callLoudspeaker);
    await _applyMicrophoneVolume();
    if (callCameraOn) {
      await participant?.setCameraEnabled(
        true,
        cameraCaptureOptions: CameraCaptureOptions(
          cameraPosition: _callCameraPosition,
          deviceId: videoInputDeviceId,
        ),
      );
      call.cameraEnabled = true;
    }
    call.room = room;
    call.connecting = false;
    markNativeVoiceCallConnected(call.chatId);
    _watchCallParticipants(call, room);
    notifyListeners();
  }

  /// Watches the room so the call switches from "calling" to active as soon as
  /// a second participant joins, and gives up after [callJoinTimeout] if nobody
  /// does.
  void _watchCallParticipants(ActiveCall call, Room room) {
    call.participantListener = () {
      _refreshCallActivity(call, room.remoteParticipants.length);
    };
    room.addListener(call.participantListener!);
    _refreshCallActivity(call, room.remoteParticipants.length);
  }

  /// Recomputes whether the call has a second participant and arms or clears
  /// the timers accordingly.
  void _refreshCallActivity(ActiveCall call, int remoteParticipantCount) {
    if (!identical(_activeCall, call)) return;
    if (remoteParticipantCount > 0 && !call.active) {
      call.activeSince = DateTime.now();
      _callJoinTimer?.cancel();
      _callJoinTimer = null;
      _callTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!identical(_activeCall, call) || !call.active) {
          _callTicker?.cancel();
          _callTicker = null;
          return;
        }
        notifyListeners();
      });
    } else if (remoteParticipantCount == 0 && !call.active) {
      _callJoinTimer ??= Timer(callJoinTimeout, () {
        _callJoinTimer = null;
        if (identical(_activeCall, call) && !call.active) {
          // Nobody joined in time, so the call is shut down for everyone.
          unawaited(_teardownActiveCall(notifyServer: true));
        }
      });
    }
    final room = call.room;
    if (room != null) unawaited(_applyRemoteAudioVolume(room));
    notifyListeners();
  }

  void _stopCallTimers() {
    _callJoinTimer?.cancel();
    _callJoinTimer = null;
    _callTicker?.cancel();
    _callTicker = null;
  }

  /// Leaves the active call, ending the room when this client owns it.
  Future<void> leaveCall() => _teardownActiveCall(notifyServer: true);

  /// Drops the local session.
  ///
  /// [notifyServer] is false when the room already ended on the server, so
  /// reacting to that must not send a second `end` back.
  Future<void> _teardownActiveCall({required bool notifyServer}) async {
    final call = _activeCall;
    if (call == null) return;
    _activeCall = null;
    _stopCallTimers();
    final room = call.room;
    final listener = call.participantListener;
    if (room != null && listener != null) room.removeListener(listener);
    call.participantListener = null;
    if (room != null) await room.disconnect();
    if (notifyServer && call.ownsCall) {
      try {
        await api.endVoice(call.chatId);
      } on ApiException {
        // The local participant has already left; a failed end is harmless.
      }
    }
    endNativeVoiceCall(call.chatId);
    notifyListeners();
  }

  Future<void> toggleCallMicrophone() async {
    final call = _activeCall;
    final participant = call?.room?.localParticipant;
    if (call == null || participant == null) return;
    final enabled = !call.microphoneEnabled;
    await participant.setMicrophoneEnabled(
      enabled,
      audioCaptureOptions: callAudioCaptureOptions,
    );
    call.microphoneEnabled = enabled;
    notifyListeners();
  }

  /// Turns the outgoing webcam on or off for the active call.
  Future<void> toggleCallWebcam() async {
    final call = _activeCall;
    final participant = call?.room?.localParticipant;
    if (call == null || participant == null) return;
    final enabled = !call.cameraEnabled;
    await participant.setCameraEnabled(
      enabled,
      cameraCaptureOptions: CameraCaptureOptions(
        cameraPosition: _callCameraPosition,
      ),
    );
    call.cameraEnabled = enabled;
    notifyListeners();
  }

  /// Starts or stops sharing this device's screen into the active call.
  ///
  /// On the desktop this shares the default screen without prompting; the
  /// picker-driven flow uses [startCallScreenShare] instead.
  Future<void> toggleCallScreenShare() async {
    final call = _activeCall;
    final participant = call?.room?.localParticipant;
    if (call == null || participant == null) return;
    final enabled = !call.screenShareEnabled;
    await participant.setScreenShareEnabled(enabled, captureScreenAudio: true);
    call.screenShareEnabled = enabled;
    notifyListeners();
  }

  /// Lists the screens and windows a desktop user can choose to share.
  ///
  /// Empty on platforms without a source picker (web, mobile). Throws when the
  /// platform channel is unavailable so the caller can surface a retry.
  Future<List<ScreenShareSource>> listScreenShareSources() async {
    if (!lkPlatformIsDesktop()) return const [];
    final sources = await desktopCapturer.getSources(
      types: const [SourceType.Screen, SourceType.Window],
    );
    return [
      for (final source in sources)
        ScreenShareSource(
          id: source.id,
          name: source.name,
          isScreen: source.type == SourceType.Screen,
          thumbnail: source.thumbnail,
        ),
    ];
  }

  /// Begins sharing the specific screen or window chosen in the picker.
  Future<void> startCallScreenShare(String sourceId) async {
    final call = _activeCall;
    final participant = call?.room?.localParticipant;
    if (call == null || participant == null) return;
    await participant.setScreenShareEnabled(
      true,
      captureScreenAudio: true,
      screenShareCaptureOptions: ScreenShareCaptureOptions(sourceId: sourceId),
    );
    call.screenShareEnabled = true;
    notifyListeners();
  }

  /// Stops the active screen share, if any.
  Future<void> stopCallScreenShare() async {
    final call = _activeCall;
    final participant = call?.room?.localParticipant;
    if (call == null || participant == null) return;
    if (!call.screenShareEnabled) return;
    await participant.setScreenShareEnabled(false);
    call.screenShareEnabled = false;
    notifyListeners();
  }

  /// Switches call audio between the loudspeaker and the earpiece.
  Future<void> toggleCallSpeaker() async {
    final call = _activeCall;
    if (call == null) return;
    final enabled = !call.speakerEnabled;
    await AudioManager.instance.setSpeakerOutputPreferred(enabled);
    call.speakerEnabled = enabled;
    notifyListeners();
  }

  /// Collapses the active call to the small bar shown above every chat.
  void minimizeActiveCall() {
    final call = _activeCall;
    if (call == null || call.minimized) return;
    call.minimized = true;
    notifyListeners();
  }

  /// Re-opens the full `/call/:id` page for a minimised call.
  void expandActiveCall() {
    final call = _activeCall;
    if (call == null || !call.minimized) return;
    call.minimized = false;
    notifyListeners();
  }

  /// Drops all local call state without touching the server or LiveKit.
  ///
  /// Tests share the singleton, so one that rings or joins a call must be able
  /// to clear it, ringing calls included, without a network round-trip before
  /// the next test runs.
  @visibleForTesting
  void resetActiveCallForTesting() {
    _activeCall = null;
    _stopCallTimers();
    _activeVoiceCalls.clear();
    _dismissedVoiceCalls.clear();
    _acceptedNativeVoiceCalls.clear();
    _syncVoiceRingtone();
  }

  Future<void> startNativeOutgoingCall(int chatId, String displayName) =>
      NativeCallService.instance.startOutgoing(
        chatId: chatId,
        name: displayName,
      );

  void markNativeVoiceCallConnected(int chatId) {
    unawaited(NativeCallService.instance.markConnected(chatId));
  }

  void endNativeVoiceCall(int chatId) {
    _acceptedNativeVoiceCalls.remove(chatId);
    unawaited(NativeCallService.instance.endChatCall(chatId));
  }

  void _handleNativeCallAction(NativeCallAction action) {
    switch (action.type) {
      case NativeCallActionType.accepted:
        _acceptedNativeVoiceCalls.add(action.chatId);
        _pendingNativeCallChatId = action.chatId;
        // The user answered on the native screen, so the in-app ringing surface
        // (including the call page) stands down while the call joins. The chat
        // id stays buffered for the cold-start case, where the session is not
        // restored yet and the join has to wait for the router.
        _dismissedVoiceCalls.add(action.chatId);
        if (isLoggedIn) {
          unawaited(joinCall(action.chatId));
        }
        _syncVoiceRingtone();
        notifyListeners();
      case NativeCallActionType.declined:
      case NativeCallActionType.timedOut:
        dismissIncomingVoiceCall(action.chatId);
      case NativeCallActionType.ended:
        if (_acceptedNativeVoiceCalls.remove(action.chatId)) {
          // The user hung up from the native call UI, so drop the matching
          // session. An ended call that was never accepted is just a ringing
          // notification going away.
          if (_activeCall?.chatId == action.chatId) {
            unawaited(leaveCall());
          }
        } else {
          dismissIncomingVoiceCall(action.chatId);
        }
    }
  }

  /// Set by a notification tap before the app is ready to route. Consumed by
  /// the widget tree once the router exists, mirroring [pendingDeepLink].
  int? pendingNotificationChatId;

  static const _apiUrlKey = SessionStore.apiUrlKey;
  static const _accountsKey = SessionStore.accountsKey;
  static const _activeAccountKey = SessionStore.activeAccountKey;
  static const _activeProfileKey = 'qutty.active_profile';
  static const _developerInfoKey = 'qutty.developer_info';
  static const _forceReadCountKey = 'qutty.force_read_count';
  static const _themePreferenceKey = 'qutty.theme_preference';
  static const _accentPreferenceKey = 'qutty.accent_pregree';
  static const _customAccentColorKey = 'qutty.custom_accent_color';
  static const _notificationsEnabledKey = 'qutty.notifications_enabled';
  static const _localeKey = 'qutty.locale';
  static const _fontIdKey = 'qutty.font_id';
  static const _fontLabelKey = 'qutty.font_label';
  static const _fontBytesKey = 'qutty.font_bytes';
  static const _callLoudspeakerKey = 'qutty.call_loudspeaker';
  static const _callMicOnKey = 'qutty.call_mic_on';
  static const _callCameraOnKey = 'qutty.call_camera_on';
  static const _callCameraFaceKey = 'qutty.call_camera_face';
  static const _callScreenShareKey = 'qutty.call_screen_share';
  static const _audioInputKey = 'qutty.audio_input_device';
  static const _audioInputLabelKey = 'qutty.audio_input_device_label';
  static const _audioOutputKey = 'qutty.audio_output_device';
  static const _audioOutputLabelKey = 'qutty.audio_output_device_label';
  static const _videoInputKey = 'qutty.video_input_device';
  static const _videoInputLabelKey = 'qutty.video_input_device_label';
  static const _noiseReductionKey = 'qutty.audio_noise_reduction';
  static const _echoCancellationKey = 'qutty.audio_echo_cancellation';
  static const _autoGainControlKey = 'qutty.audio_agc';
  static const _highPassFilterKey = 'qutty.audio_hpf';
  static const _micVolumeKey = 'qutty.audio_mic_volume';
  static const _speakerVolumeKey = 'qutty.audio_speaker_volume';
  static const _fallbackSelectorKey = 'qutty.fallback_selector_cast';
  static const _forceGroupCallKey = 'qutty.force_group_call_layout';

  /// Cache name for the one font the user brought themselves.
  ///
  /// A single slot: picking a second file replaces the first, so the cache holds
  /// one sideloaded font rather than growing with every file ever picked.
  static const _sideloadFontId = 'sideload';

  bool get isLoggedIn => api.token != null && profile != null;
  bool developerInfo = false;

  /// When true, direct chats show how many members have read a message instead
  /// of a check mark. Groups and channels always show the count, so this only
  /// changes direct-chat presentation.
  bool forceReadCount = false;

  /// Debug switch that forces the in-app screen-share picker even where the OS
  /// or browser provides its own.
  bool fallbackSelectorCast = false;

  /// Debug switch that uses the group call layout even in direct calls.
  bool forceGroupCall = false;

  /// True when the OS or browser shows its own picker (web, Android, iOS), so
  /// the app should let it handle the choice rather than listing sources.
  /// macOS is excluded because its native picker is driven by the app's own
  /// channel.
  bool get platformOwnsScreenSharePicker => !lkPlatformIsDesktop();

  ThemePreference themePreference = ThemePreference.system;
  AccentPreference accentPreference = AccentPreference.quttyBlue;
  int customAccentColor = 0xff058deb;

  /// Whether new calls pull up the webcam automatically.
  bool callCameraOn = false;

  /// Which camera (`front` or `back`) is used for calls.
  String callCameraFace = 'front';

  /// Whether call audio plays through the loudspeaker rather than the earpiece.
  bool callLoudspeaker = true;

  /// Whether the microphone is enabled when a call starts.
  bool callMicOn = true;

  /// Whether screen sharing is offered inside calls.
  bool callScreenShareAllowed = true;

  /// The audio input (microphone) device id chosen in settings, or null to let
  /// the platform pick the default.
  String? audioInputDeviceId;
  String? audioInputDeviceLabel;

  /// The audio output (speaker) device id chosen in settings, or null to let
  /// the platform pick the default.
  String? audioOutputDeviceId;
  String? audioOutputDeviceLabel;

  /// The video input (camera) device id chosen in settings, or null to let the
  /// platform pick the default.
  String? videoInputDeviceId;
  String? videoInputDeviceLabel;

  /// Whether background noise suppression and echo cancellation are applied to
  /// the microphone during calls.
  bool noiseReduction = true;
  bool echoCancellation = true;
  bool autoGainControl = true;
  bool highPassFilter = true;

  /// Microphone capture volume, from 0 (silent) to 1 (full).
  double microphoneVolume = 1;

  /// Speaker playback volume, from 0 (silent) to 1 (full).
  double speakerVolume = 1;

  CameraPosition get _callCameraPosition =>
      callCameraFace == 'back' ? CameraPosition.back : CameraPosition.front;

  /// Master switch for notifications. Turning it off unregisters the push token
  /// so the backend stops sending to this device entirely.
  bool notificationsEnabled = true;

  /// The language the user picked, or null to follow the device language.
  ///
  /// Kept as a [Locale] rather than a language name so the app can distinguish
  /// a language from a country without the two being conflated in storage.
  Locale? _locale;

  /// The locale to hand to `MaterialApp.locale`, or null to let it resolve from
  /// the platform.
  Locale? get locale => _locale;

  /// The font the user picked, or null for the platform default.
  ///
  /// This is the family name registered with the engine rather than the font's
  /// own name, because the app cannot ask the platform what it will call a font
  /// it loaded at runtime. It belongs on `ThemeData.fontFamily`.
  String? _fontFamily;

  String? _fontId;
  String? _fontLabel;

  /// The family to set on the theme, or null to leave the platform default.
  String? get fontFamily => _fontFamily;

  /// The id of the chosen font, or null when using the platform default.
  String? get fontId => _fontId;

  /// The name to show in settings for the chosen font.
  String? get fontLabel => _fontLabel;

  /// Whether the app is using the platform's own font rather than a chosen one.
  bool get usesSystemFont => _fontFamily == null;

  /// Catalog font ids whose file is already on disk.
  ///
  /// A font is only offered once it is local. Reading the cache here rather than
  /// in the picker keeps it to one pass per app start instead of one per visit
  /// to the screen, and keeps filesystem access out of a widget's lifecycle.
  Set<String> _downloadedFonts = const {};

  Set<String> get downloadedFonts => _downloadedFonts;

  /// Re-checks which catalog fonts are cached.
  Future<void> refreshDownloadedFonts() async {
    final found = <String>{};
    for (final font in downloadableFonts) {
      if (await readCachedFont(fontCacheName(font.id)) != null) {
        found.add(font.id);
      }
    }
    _downloadedFonts = found;
    notifyListeners();
  }

  int unreadCount(int chatId) => _unread[chatId] ?? 0;
  MessageInfo? lastMessage(int chatId) => _lastMessage[chatId];

  Future<void> restore() async {
    isLoading = true;
    notifyListeners();
    try {
      await _restoreSavedSession();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreSavedSession() async {
    final preferences = await SharedPreferences.getInstance();
    accounts = await SessionStore.readAccounts(preferences);
    if (accounts.isEmpty) {
      final legacyToken = preferences.getString(SessionStore.tokenKey);
      final savedUrl = preferences.getString(_apiUrlKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        final baseUrl = savedUrl?.isNotEmpty == true ? savedUrl! : api.baseUrl;
        accounts = [
          AccountRecord(
            id: _accountId(baseUrl, legacyToken),
            label: L10n.current.settingsAccountDefaultLabel,
            baseUrl: baseUrl,
            token: legacyToken,
          ),
        ];
        await _persistAccounts(preferences);
      }
    }
    activeAccountId = preferences.getString(_activeAccountKey);
    final active =
        accounts
            .where((account) => account.id == activeAccountId)
            .firstOrNull ??
        accounts.firstOrNull;
    if (active != null) {
      activeAccountId = active.id;
      api.baseUrl = active.baseUrl;
      api.token = active.token;
    }
    developerInfo = preferences.getBool(_developerInfoKey) ?? false;
    forceReadCount = preferences.getBool(_forceReadCountKey) ?? false;
    fallbackSelectorCast = preferences.getBool(_fallbackSelectorKey) ?? false;
    forceGroupCall = preferences.getBool(_forceGroupCallKey) ?? false;
    themePreference = _themePreferenceFromString(
      preferences.getString(_themePreferenceKey),
    );
    accentPreference = _accentPreferenceFromString(
      preferences.getString(_accentPreferenceKey),
    );
    customAccentColor = preferences.getInt(_customAccentColorKey) ?? 0xff058deb;
    notificationsEnabled =
        preferences.getBool(_notificationsEnabledKey) ?? true;
    callCameraOn = preferences.getBool(_callCameraOnKey) ?? false;
    callCameraFace = preferences.getString(_callCameraFaceKey) ?? 'front';
    callLoudspeaker = preferences.getBool(_callLoudspeakerKey) ?? true;
    callMicOn = preferences.getBool(_callMicOnKey) ?? true;
    callScreenShareAllowed = preferences.getBool(_callScreenShareKey) ?? true;
    audioInputDeviceId = preferences.getString(_audioInputKey);
    audioInputDeviceLabel = preferences.getString(_audioInputLabelKey);
    audioOutputDeviceId = preferences.getString(_audioOutputKey);
    audioOutputDeviceLabel = preferences.getString(_audioOutputLabelKey);
    videoInputDeviceId = preferences.getString(_videoInputKey);
    videoInputDeviceLabel = preferences.getString(_videoInputLabelKey);
    noiseReduction = preferences.getBool(_noiseReductionKey) ?? true;
    echoCancellation =
        preferences.getBool(_echoCancellationKey) ?? noiseReduction;
    autoGainControl =
        preferences.getBool(_autoGainControlKey) ?? noiseReduction;
    highPassFilter = preferences.getBool(_highPassFilterKey) ?? false;
    microphoneVolume = preferences.getDouble(_micVolumeKey) ?? 1;
    speakerVolume = preferences.getDouble(_speakerVolumeKey) ?? 1;
    _locale = _localeFromString(preferences.getString(_localeKey));
    await _restoreFont(preferences);
    await refreshDownloadedFonts();
    if (active != null) {
      // Restore the cached profile first so a saved session survives brief
      // network outages at startup instead of dumping the user to the login
      // screen.
      profile = _profileFromPreferences(preferences);
      try {
        profile = await api.me();
        await _saveActiveAccount();
        await refreshChats();
        await connectWebSocket();
        unawaited(syncPushRegistration());
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await _clearInvalidActiveSession(preferences);
        }
      } catch (_) {
        // Keep the persisted session; refresh will be retried on the next
        // launch or via reconnect.
      }
    }
  }

  Future<void> _clearInvalidActiveSession(SharedPreferences preferences) async {
    final invalidAccountId = activeAccountId;
    if (invalidAccountId != null) {
      accounts = accounts
          .where((account) => account.id != invalidAccountId)
          .toList();
      await SessionStore.deleteAccountToken(invalidAccountId);
    }
    await SessionStore.deleteToken();
    await preferences.remove(_activeProfileKey);
    activeAccountId = accounts.firstOrNull?.id;
    await preferences.setString(_activeAccountKey, activeAccountId ?? '');
    await _persistAccounts(preferences);
    api.token = null;
    profile = null;
    chats = const [];
  }

  Future<void> login(String username, String password) async {
    api.token = await api.login(username, password);
    profile = await api.me();
    await _saveActiveAccount();
    await refreshChats();
    await connectWebSocket();
    unawaited(syncPushRegistration());
    notifyListeners();
  }

  Future<void> loginWithToken(String token) async {
    await api.loginWithToken(token);
    profile = await api.me();
    await _saveActiveAccount();
    await refreshChats();
    await connectWebSocket();
    unawaited(syncPushRegistration());
    notifyListeners();
  }

  Future<void> register(String username, String password, String email) async {
    await api.register(username: username, password: password, email: email);
    await login(username, password);
  }

  Future<void> refreshChats() async {
    // api.chats() is an N+1 fan-out, so overlapping refreshes only add load and
    // can land out of order. Collapse concurrent callers onto one request.
    final pending = _chatsRefreshInFlight;
    if (pending != null) return pending;
    final future = _loadChats();
    _chatsRefreshInFlight = future;
    try {
      await future;
    } finally {
      _chatsRefreshInFlight = null;
    }
  }

  Future<void> _loadChats() async {
    chats = await api.chats();
    notifyListeners();
  }

  /// Debounces the chat-list refresh triggered by realtime messages so a burst
  /// of incoming messages costs one list refresh instead of one per message.
  void _scheduleChatsRefresh() {
    _chatsRefreshDebounce?.cancel();
    _chatsRefreshDebounce = Timer(const Duration(milliseconds: 400), () {
      _chatsRefreshDebounce = null;
      // Background refresh: a failure must not surface as an unhandled error,
      // the list simply stays as-is until the next successful refresh.
      unawaited(refreshChats().catchError((_) {}));
    });
  }

  Future<void> setApiUrl(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final changed = normalized != api.baseUrl;
    if (changed) {
      // The push token belongs to the old server; drop it before the base URL
      // moves out from under the request.
      await _unregisterAllDevices();
      _deviceId = null;
      // UGC item ids belong to the server being left; drop the resolved images.
      clearUgcItems();
    }
    api.baseUrl = normalized;
    await _saveActiveAccount();
    if (api.token != null) {
      await connectWebSocket();
    }
    if (changed) unawaited(syncPushRegistration());
    notifyListeners();
  }

  /// Called when the app returns to the foreground.
  ///
  /// Messages sent while the app was away may have been delivered only by FCM,
  /// so the chat list is re-synced, and the push token is re-registered because
  /// FCM can rotate it at any time.
  Future<void> onResumed() async {
    if (!isLoggedIn) return;
    try {
      await refreshChats();
      await syncPushRegistration();
    } on ApiException catch (error) {
      debugPrint('notifications: resume sync failed: ${error.message}');
    }
    // The peer may have read the open conversation while we were backgrounded;
    // refresh its cursors so the reader counts are current again.
    final chatId = activeChatId;
    if (chatId != null) await refreshReadCursors(chatId);
    notifyListeners();
  }

  Future<void> setDeveloperInfo(bool value) async {
    developerInfo = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_developerInfoKey, value);
    notifyListeners();
  }

  Future<void> setForceReadCount(bool value) async {
    if (forceReadCount == value) return;
    forceReadCount = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_forceReadCountKey, value);
    notifyListeners();
  }

  Future<void> setFallbackSelectorCast(bool value) async {
    fallbackSelectorCast = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_fallbackSelectorKey, value);
    notifyListeners();
  }

  Future<void> setForceGroupCall(bool value) async {
    forceGroupCall = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_forceGroupCallKey, value);
    notifyListeners();
  }

  Future<void> setCallCameraOn(bool value) async {
    callCameraOn = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_callCameraOnKey, value);
    notifyListeners();
  }

  Future<void> setCallCameraFace(String value) async {
    callCameraFace = value == 'back' ? 'back' : 'front';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_callCameraFaceKey, callCameraFace);
    notifyListeners();
  }

  Future<void> setCallLoudspeaker(bool value) async {
    callLoudspeaker = value;
    final call = _activeCall;
    if (call != null) {
      call.speakerEnabled = value;
      await AudioManager.instance.setSpeakerOutputPreferred(value);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_callLoudspeakerKey, value);
    notifyListeners();
  }

  Future<void> setCallMicOn(bool value) async {
    callMicOn = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_callMicOnKey, value);
    notifyListeners();
  }

  Future<void> setCallScreenShareAllowed(bool value) async {
    callScreenShareAllowed = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_callScreenShareKey, value);
    notifyListeners();
  }

  /// Lists the microphones available on this device.
  Future<List<MediaDevice>> audioInputDevices() =>
      Hardware.instance.audioInputs();

  /// Lists the speakers available on this device.
  Future<List<MediaDevice>> audioOutputDevices() =>
      Hardware.instance.audioOutputs();

  /// Lists the cameras available on this device.
  Future<List<MediaDevice>> videoInputDevices() =>
      Hardware.instance.videoInputs();

  /// The capture options used whenever the microphone is (re)enabled, so the
  /// chosen device and noise-reduction preference apply to every call.
  AudioCaptureOptions get callAudioCaptureOptions => AudioCaptureOptions(
    deviceId: audioInputDeviceId,
    noiseSuppression: noiseReduction,
    echoCancellation: echoCancellation,
    autoGainControl: autoGainControl,
    highPassFilter: highPassFilter,
  );

  Future<void> setNoiseReduction(bool value) async {
    noiseReduction = value;
    if (!value) {
      echoCancellation = false;
      autoGainControl = false;
      highPassFilter = false;
    }
    await _applyAudioProcessing();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_noiseReductionKey, value);
    if (!value) {
      await preferences.setBool(_echoCancellationKey, false);
      await preferences.setBool(_autoGainControlKey, false);
      await preferences.setBool(_highPassFilterKey, false);
    }
    notifyListeners();
  }

  Future<void> _applyAudioProcessing() async {
    final track = _localAudioTrack();
    if (track != null) {
      try {
        // ignore: experimental_member_use
        await track.setAudioProcessingOptions(
          // ignore: experimental_member_use
          AudioProcessingOptions(
            echoCancellation: echoCancellation,
            noiseSuppression: noiseReduction,
            autoGainControl: autoGainControl,
            highPassFilter: highPassFilter,
          ),
        );
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> setMicrophoneVolume(double value) async {
    microphoneVolume = value.clamp(0.0, 1.0);
    await _applyMicrophoneVolume();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_micVolumeKey, microphoneVolume);
    notifyListeners();
  }

  Future<void> setSpeakerVolume(double value) async {
    speakerVolume = value.clamp(0.0, 1.0);
    final call = _activeCall;
    if (call != null && call.room != null) {
      await _applyRemoteAudioVolume(call.room!);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_speakerVolumeKey, speakerVolume);
    notifyListeners();
  }

  Future<void> setAudioInputDevice(MediaDevice device) async {
    final useDefault = device.deviceId.isEmpty;
    audioInputDeviceId = useDefault ? null : device.deviceId;
    audioInputDeviceLabel = useDefault ? null : device.label;
    final room = _activeCall?.room;
    if (room != null && !useDefault) {
      try {
        await room.setAudioInputDevice(device);
      } catch (_) {
        // Selecting a device is a platform best-effort; the preference still
        // applies to the next call.
      }
    }
    final preferences = await SharedPreferences.getInstance();
    if (useDefault) {
      await preferences.remove(_audioInputKey);
      await preferences.remove(_audioInputLabelKey);
    } else {
      await preferences.setString(_audioInputKey, device.deviceId);
      await preferences.setString(_audioInputLabelKey, device.label);
    }
    notifyListeners();
  }

  Future<void> setAudioOutputDevice(MediaDevice device) async {
    final useDefault = device.deviceId.isEmpty;
    audioOutputDeviceId = useDefault ? null : device.deviceId;
    audioOutputDeviceLabel = useDefault ? null : device.label;
    final room = _activeCall?.room;
    if (room != null && !useDefault) {
      try {
        await room.setAudioOutputDevice(device);
      } catch (_) {
        // Selecting a device is a platform best-effort; the preference still
        // applies to the next call.
      }
    }
    final preferences = await SharedPreferences.getInstance();
    if (useDefault) {
      await preferences.remove(_audioOutputKey);
      await preferences.remove(_audioOutputLabelKey);
    } else {
      await preferences.setString(_audioOutputKey, device.deviceId);
      await preferences.setString(_audioOutputLabelKey, device.label);
    }
    notifyListeners();
  }

  Future<void> setVideoInputDevice(MediaDevice device) async {
    final useDefault = device.deviceId.isEmpty;
    videoInputDeviceId = useDefault ? null : device.deviceId;
    videoInputDeviceLabel = useDefault ? null : device.label;
    final room = _activeCall?.room;
    if (room != null && !useDefault) {
      try {
        await room.setVideoInputDevice(device);
      } catch (_) {
        // Selecting a device is a platform best-effort; the preference still
        // applies to the next call.
      }
    }
    final preferences = await SharedPreferences.getInstance();
    if (useDefault) {
      await preferences.remove(_videoInputKey);
      await preferences.remove(_videoInputLabelKey);
    } else {
      await preferences.setString(_videoInputKey, device.deviceId);
      await preferences.setString(_videoInputLabelKey, device.label);
    }
    notifyListeners();
  }

  /// The active call's local microphone track, if one exists.
  LocalAudioTrack? _localAudioTrack() {
    final publications =
        _activeCall?.room?.localParticipant?.audioTrackPublications;
    if (publications == null) return null;
    for (final publication in publications) {
      final track = publication.track;
      if (track is LocalAudioTrack) return track;
    }
    return null;
  }

  Future<void> _applyMicrophoneVolume() async {
    final track = _localAudioTrack();
    if (track == null) return;
    try {
      await Helper.setVolume(microphoneVolume, track.mediaStreamTrack);
    } catch (_) {
      // Capture gain is not exposed on every platform.
    }
  }

  /// Applies the chosen speaker volume to every remote audio track currently in
  /// the call.
  Future<void> _applyRemoteAudioVolume(Room room) async {
    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track == null) continue;
        try {
          await Helper.setVolume(speakerVolume, track.mediaStreamTrack);
        } catch (_) {
          // Playback volume may not be adjustable on every platform.
        }
      }
    }
  }

  /// Boots the notification stack and wires tap handling. Called once from
  /// main() after restore(), because it must run outside the widget tree.
  Future<void> startNotifications() async {
    final service = NotificationService.instance;
    // Both delivery paths must agree on when to alert, so the rule is owned
    // here and handed to the service rather than duplicated.
    service.shouldNotifyForChat = shouldNotifyForChatId;

    // Subscribed before initialize(): a cold-start tap is delivered during
    // initialisation, and the stream is a broadcast, so a listener attached
    // afterwards would miss the one event that mattered.
    _notificationTapSub ??= service.onOpened.listen(handleNotificationTap);

    // The transport is reported back so the server registration can name the
    // provider that issued the token, and so the background socket can be
    // started or stopped when the user switches to or away from it.
    service.onTransportChanged = (transport) {
      _transport = transport;
      unawaited(syncPushRegistration());
      unawaited(_syncBackgroundSocket());
      notifyListeners();
    };
    service.onTokenRefresh = (token, transport) {
      _transport = transport;
      unawaited(_registerPushToken(token, transport));
    };

    await service.initialize();
    _transport = service.selectedTransport;
    await syncPushRegistration();
  }

  /// Registers or unregisters the push token depending on the current
  /// preference. Safe to call repeatedly; failures are non-fatal because
  /// notifications are not required for the app to work.
  Future<void> syncPushRegistration() async {
    if (!isLoggedIn || !notificationsEnabled) return;
    final service = NotificationService.instance;

    // The background socket receives messages over the existing connection and
    // has no token to register, so there is nothing to send to the server.
    final transport = _transport ?? service.selectedTransport;
    if (transport == null || transport == PushTransport.websocket) return;
    try {
      final token = await service.currentTransportToken();
      if (token == null || token.isEmpty) return;
      await _registerPushToken(token, transport);
    } catch (error) {
      debugPrint('notifications: device registration failed: $error');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (notificationsEnabled == value) return;
    notificationsEnabled = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsEnabledKey, value);
    notifyListeners();
    if (!value) {
      // The background socket holds a connection and a foreground notification
      // on the user's behalf. Turning notifications off has to release both,
      // rather than leaving a live connection for a channel nothing will be
      // posted to.
      await BackgroundSocketController.stop();
    }
    if (!isLoggedIn) return;
    // The preference is device-local, so only this install is detached: another
    // phone signed into the same account keeps its notifications.
    if (value) {
      await syncPushRegistration();
    } else {
      await _unregisterThisDevice();
    }
  }

  Future<void> _registerPushToken(String token, PushTransport transport) async {
    if (token.isEmpty || !isLoggedIn || !notificationsEnabled) return;
    try {
      // The provider, bundle id and sandbox flag all describe the token being
      // registered rather than this build in general. FCM has no bundle id and no
      // environment, and the server falls back to its defaults for those.
      final context = NotificationService.instance.tokenContextFor(transport);
      final device = await api.registerDevice(
        token: token,
        platform: await NotificationService.currentPlatform(),
        provider: context.provider,
        bundleId: context.bundleId,
        sandbox: context.sandbox,
        appVersion: await NotificationService.currentAppVersion(),
      );
      _deviceId = device.id == 0 ? null : device.id;
    } on ApiException catch (error) {
      debugPrint('notifications: token registration failed: ${error.message}');
    }
  }

  Future<void> _unregisterThisDevice() async {
    final id = _deviceId;
    if (id == null) return;
    try {
      await api.deleteDevice(id);
    } on ApiException catch (error) {
      debugPrint('notifications: device removal failed: ${error.message}');
    } finally {
      _deviceId = null;
    }
  }

  /// Detaches every push token owned by the signing-out account. Unlike the
  /// toggle, sign-out must clear every device: the person using this phone may
  /// not be the person who owns the account.
  Future<void> _unregisterAllDevices() async {
    if (api.token == null) return;
    try {
      await api.deleteDevices();
    } on ApiException catch (error) {
      debugPrint('notifications: device removal failed: ${error.message}');
    }
  }

  /// Routes a notification tap. The intent is buffered rather than acted on
  /// directly because a cold-start tap arrives before the router exists, and
  /// while logged out the auth redirect would discard the destination.
  void handleNotificationTap(NotificationPayload payload) {
    final chatId = payload.chatId;
    if (chatId == null) return;
    pendingNotificationChatId = chatId;
    notifyListeners();
  }

  int? takePendingNotificationChatId() {
    final value = pendingNotificationChatId;
    if (value == null) return null;
    pendingNotificationChatId = null;
    notifyListeners();
    return value;
  }

  /// Called by the app's lifecycle observer.
  void setForeground(bool value) {
    if (isForeground == value) return;
    isForeground = value;
    unawaited(_syncBackgroundSocket());
  }

  /// Runs the background socket only while the app is not in the foreground.
  ///
  /// Both sockets would otherwise be connected at the same time, and the server
  /// delivers to every connection for the user -- so each message would arrive
  /// twice and be applied to the chat twice. Whichever socket is live depends on
  /// whether anyone is looking at the app.
  Future<void> _syncBackgroundSocket() async {
    if (NotificationService.instance.selectedTransport !=
        PushTransport.websocket) {
      return;
    }
    if (isForeground || !isLoggedIn) {
      await BackgroundSocketController.stop();
    } else {
      await BackgroundSocketController.start();
    }
  }

  /// Called by the chat screen so a message for the open chat does not raise a
  /// notification.
  void setActiveChat(int? chatId) {
    if (activeChatId == chatId) return;
    activeChatId = chatId;
  }

  /// Decides whether an incoming message should raise a local notification.
  ///
  /// A message that arrives over the websocket while the app is open still
  /// needs a notification unless the user is already reading that conversation.
  bool shouldNotifyForChatId(int chatId) {
    if (!notificationsEnabled) return false;
    debugPrint('shouldNotifyForChatId: isForeground=$isForeground, activeChatId=$activeChatId, chatId=$chatId');
    var notify = NotificationService.instance.shouldNotify(
      isForeground: isForeground,
      activeChatId: activeChatId,
      chatId: chatId,
    );
    debugPrint('shouldNotifyForChatId: notify=$notify');
    return notify;
  }

  Future<void> setThemePreference(ThemePreference value) async {
    themePreference = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, value.name);
    notifyListeners();
  }

  /// Persists the language choice. Null means "follow the device", which is
  /// stored as an absent key rather than a sentinel so a fresh install and a
  /// reset to default are the same state.
  Future<void> setLocale(Locale? value) async {
    _locale = _supportedLocale(value);
    final preferences = await SharedPreferences.getInstance();
    if (_locale == null) {
      await preferences.remove(_localeKey);
    } else {
      await preferences.setString(_localeKey, _locale!.toLanguageTag());
    }
    notifyListeners();
  }

  /// Drops the chosen font and returns the app to the platform's own.
  Future<void> useSystemFont() async {
    _fontFamily = null;
    _fontId = null;
    _fontLabel = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_fontIdKey);
    await preferences.remove(_fontLabelKey);
    await preferences.remove(_fontBytesKey);
    notifyListeners();
  }

  /// Downloads a catalog font without applying it.
  ///
  /// Downloading and applying are separate on purpose. Doing both at once makes
  /// the download button indistinguishable from picking the font, and a user who
  /// downloads a font to look at it has no way back without picking it.
  Future<void> downloadFont(DownloadableFont font) async {
    final name = fontCacheName(font.id);
    if (await readCachedFont(name) != null) return;
    final bytes = await downloadGoogleFont(font);
    await writeCachedFont(name, bytes);
    _downloadedFonts = {..._downloadedFonts, font.id};
    notifyListeners();
  }

  /// Discards a downloaded font, so it stops being offered.
  ///
  /// Deleting the font in use falls back to the platform font: the preference
  /// would otherwise point at a file that is no longer there, and the choice
  /// would quietly come back after a restart.
  Future<void> deleteDownloadedFont(DownloadableFont font) async {
    await deleteCachedFont(fontCacheName(font.id));
    _downloadedFonts = {..._downloadedFonts}..remove(font.id);
    if (_fontId == font.id) {
      await useSystemFont();
      return;
    }
    notifyListeners();
  }

  /// Discards the sideloaded font, so the app falls back to the platform font.
  ///
  /// The user still has the original file; only the copy in the app's cache is
  /// discarded, which is what makes this safe to do without a backup prompt.
  Future<void> deleteSideloadedFont() async {
    await deleteCachedFont(_sideloadFontId);
    if (_fontId == _sideloadFontId) {
      await useSystemFont();
      return;
    }
    notifyListeners();
  }

  /// Applies a catalog font.
  ///
  /// A font that is not downloaded is fetched first, so a caller outside the
  /// picker is never left stuck. The picker gates selection separately and will
  /// not reach that path.
  Future<void> useDownloadableFont(DownloadableFont font) async {
    final name = fontCacheName(font.id);
    var bytes = await readCachedFont(name);
    if (bytes == null) {
      final downloaded = await downloadGoogleFont(font);
      await writeCachedFont(name, downloaded);
      bytes = downloaded;
      _downloadedFonts = {..._downloadedFonts, font.id};
    }
    await _applyFont(bytes, id: font.id, label: font.label);
  }

  /// Applies a font file the user picked off their device.
  ///
  /// The file is copied into the cache under a fixed name. Its original location
  /// cannot be relied on: iOS puts picks in a temporary directory that is wiped
  /// after the app restarts, which would silently drop the font later.
  ///
  /// [name] is the file's own name without the extension, which is what the
  /// settings tile shows. It is a filename rather than a label, so it stays
  /// untranslated.
  Future<void> useSideloadedFont(
    Uint8List bytes, {
    required String name,
  }) async {
    await writeCachedFont(_sideloadFontId, bytes);
    await _applyFont(bytes, id: _sideloadFontId, label: name);
  }

  Future<void> _applyFont(
    Uint8List bytes, {
    required String id,
    required String label,
  }) async {
    final family = await registerFont(bytes);
    _fontFamily = family;
    _fontId = id;
    _fontLabel = label;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_fontIdKey, id);
    await preferences.setString(_fontLabelKey, label);
    notifyListeners();
  }

  /// Re-registers the persisted font at startup.
  ///
  /// A registered family does not survive a restart, so this has to happen
  /// before the first frame for the app not to flash the default font. If the
  /// cached file is gone or unusable the preference is dropped rather than
  /// leaving a selection that renders as nothing.
  Future<void> _restoreFont(SharedPreferences preferences) async {
    final id = preferences.getString(_fontIdKey);
    if (id == null || id.isEmpty) {
      // Restore establishes the state rather than merging into it, so a second
      // call with nothing persisted goes back to the platform font instead of
      // keeping whatever was set before.
      _fontFamily = null;
      _fontId = null;
      _fontLabel = null;
      return;
    }
    final label = preferences.getString(_fontLabelKey) ?? '';
    final bytes = await readCachedFont(fontCacheName(id));
    if (bytes == null) {
      await preferences.remove(_fontIdKey);
      await preferences.remove(_fontLabelKey);
      _fontFamily = null;
      _fontId = null;
      _fontLabel = null;
      return;
    }
    try {
      _fontFamily = await registerFont(bytes);
      _fontId = id;
      _fontLabel = label;
    } on FontException {
      await preferences.remove(_fontIdKey);
      await preferences.remove(_fontLabelKey);
    }
  }

  Future<void> setAccentPreference(AccentPreference value) async {
    accentPreference = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accentPreferenceKey, value.name);
    notifyListeners();
  }

  Future<void> setCustomAccentColor(int value) async {
    customAccentColor = value;
    accentPreference = AccentPreference.custom;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_customAccentColorKey, value);
    await preferences.setString(_accentPreferenceKey, accentPreference.name);
    notifyListeners();
  }

  Future<void> updateProfile(
    String displayName,
    String bio,
    String handle,
  ) async {
    profile = await api.updateProfile(displayName, bio, handle);
    notifyListeners();
  }

  Future<void> updateAvatar(PlatformFile file) async {
    profile = await api.updateAvatar(file);
    notifyListeners();
  }

  Future<void> removeAvatar() async {
    profile = await api.removeAvatar();
    notifyListeners();
  }

  Future<void> logout() async {
    await disconnectSocket();
    // Stop the background socket while the session is still valid. Left running
    // it would hold a connection authenticated as the account that is being
    // signed out of, and keep delivering its messages.
    await BackgroundSocketController.stop();
    // Detach the push token while the session is still valid, otherwise a
    // signed-out device keeps receiving this account's messages.
    await _unregisterAllDevices();
    await api.logout();
    await SessionStore.deleteToken();
    _chatsRefreshDebounce?.cancel();
    _chatsRefreshDebounce = null;
    _deviceId = null;
    profile = null;
    chats = const [];
    for (var c in _messageStreams.values) {
      c.close();
    }
    _messageStreams.clear();
    for (var c in _messageChangeStreams.values) {
      c.close();
    }
    _messageChangeStreams.clear();
    _lastMessage.clear();
    _unread.clear();
    _readCursors.clear();
    _readCursorsLoaded.clear();
    clearUgcItems();
    final preferences = await SharedPreferences.getInstance();
    accounts = accounts
        .where((account) => account.id != activeAccountId)
        .toList();
    final loggedOutAccountId = activeAccountId;
    if (loggedOutAccountId != null) {
      await SessionStore.deleteAccountToken(loggedOutAccountId);
    }
    activeAccountId = accounts.firstOrNull?.id;
    if (activeAccountId != null) {
      await _activateAccount(activeAccountId!, connect: false);
    } else {
      api.token = null;
      profile = null;
      chats = const [];
    }
    await _persistAccounts(preferences);
    notifyListeners();
  }

  Future<void> prepareAddAccount() async {
    await disconnectSocket();
    api.token = null;
    profile = null;
    chats = const [];
    _readCursors.clear();
    _readCursorsLoaded.clear();
    clearUgcItems();
    notifyListeners();
  }

  Future<void> switchAccount(String accountId) async {
    if (accountId == activeAccountId) return;
    await _activateAccount(accountId);
    notifyListeners();
  }

  Future<void> removeAccount(String accountId) async {
    if (accountId == activeAccountId) {
      await logout();
      return;
    }
    accounts = accounts.where((account) => account.id != accountId).toList();
    await SessionStore.deleteAccountToken(accountId);
    await _persistAccounts();
    notifyListeners();
  }

  Future<void> connectWebSocket() async {
    if (api.token == null) return;
    await disconnectSocket();
    final ws = WebSocketService(baseUrl: api.baseUrl, token: api.token!);
    socket = ws;
    _socketStatusSub = ws.statusStream.listen((value) {
      connectionStatus = value;
      // Reads that happened while this client was offline were broadcast to a
      // disconnected session, so re-pull the open chat's cursors on reconnect.
      if (value == ConnectionStatus.connected) {
        final chatId = activeChatId;
        if (chatId != null) unawaited(refreshReadCursors(chatId));
      }
      notifyListeners();
    });
    _socketSub = ws.events.listen(_handleSocketEvent);
    await ws.connect();
    notifyListeners();
  }

  Future<void> disconnectSocket() async {
    await _socketSub?.cancel();
    await _socketStatusSub?.cancel();
    _socketSub = null;
    _socketStatusSub = null;
    if (socket != null) {
      await socket!.dispose();
      socket = null;
    }
    connectionStatus = ConnectionStatus.disconnected;
  }

  void _handleSocketEvent(WsEvent event) {
    switch (event.opcode) {
      case 2:
        // Hello: server confirmed connection.
        break;
      case 3:
        // Send response: payload includes the persisted message.
        try {
          final message = MessageInfo.fromJson(event.payload);
          onIncomingMessage(message);
        } catch (_) {}
        break;
      case 7:
        try {
          onVoiceCallEvent(VoiceCallEvent.fromJson(event.payload));
        } catch (_) {}
        break;
      case 8:
        // Read receipt: the acknowledgement of our own read report, or a
        // broadcast that another member has caught up.
        try {
          onReadReceipt(ReadReceipt.fromJson(event.payload));
        } catch (_) {}
        break;
      case 9:
        // Another member edited a message.
        try {
          onMessageEdited(MessageInfo.fromJson(event.payload));
        } catch (_) {}
        break;
      case 10:
        // Another member deleted a message.
        try {
          final change = MessageChange.fromDeletedJson(event.payload);
          onMessageDeleted(change.chatId, change.messageId);
        } catch (_) {}
        break;
      default:
        break;
    }
  }

  void onVoiceCallEvent(VoiceCallEvent event) {
    if (event.type == 'ended') {
      _activeVoiceCalls.remove(event.chatId);
      _dismissedVoiceCalls.remove(event.chatId);
      _acceptedNativeVoiceCalls.remove(event.chatId);
      endNativeVoiceCall(event.chatId);
      // A room ending while this client is in it (the owner hung up, or every
      // other participant left) tears the session down here rather than through
      // the call page, so the bar and route disappear together.
      if (_activeCall?.chatId == event.chatId) {
        unawaited(_teardownActiveCall(notifyServer: false));
      }
      // If other calls are still ringing, clear dismissals so they can surface
      if (_activeVoiceCalls.isNotEmpty) {
        _dismissedVoiceCalls.clear();
      }
    } else if (event.type == 'started') {
      // Already on a call, or already being rung by one: ignore the new call
      // entirely, exactly like a phone that only rings one line at a time.
      // Nothing is recorded, so the call page never opens and no extra
      // ringtone or native UI is raised.
      if (inActiveCall || incomingVoiceCall != null) {
        return;
      }
      _activeVoiceCalls[event.chatId] = event;
      _dismissedVoiceCalls.remove(event.chatId);
      if (event.userId != profile?.id && shouldNotifyForChatId(event.chatId)) {
        unawaited(_notifyIncomingCall(event));
      }
      // Group and channel calls do not raise the native incoming UI; the
      // notification raised above still tells the user a call is waiting.
      if (event.userId != profile?.id && !isGroupChat(event.chatId)) {
        unawaited(
          NativeCallService.instance.showIncoming(
            chatId: event.chatId,
            userId: event.userId,
            displayName: event.displayName,
          ),
        );
      }
    } else {
      return;
    }
    _syncVoiceRingtone();
    if (!_voiceCallEvents.isClosed) _voiceCallEvents.add(event);
    notifyListeners();
  }

  void _syncVoiceRingtone() {
    if (incomingVoiceCall == null ||
        !enableCallRingtone ||
        NativeCallService.instance.isSupported) {
      if (!_voiceRingtoneActive) return;
      _voiceRingtoneActive = false;
      _voiceRingtoneGeneration++;
      _voiceRingtoneFallback?.cancel();
      _voiceRingtoneFallback = null;
      final player = _voiceRingtonePlayer;
      if (player != null) unawaited(player.stop().catchError((_) {}));
      return;
    }
    if (_voiceRingtoneActive) return;
    _voiceRingtoneActive = true;
    final generation = ++_voiceRingtoneGeneration;
    unawaited(_playIncomingRingtone(generation));
  }

  Future<void> _playIncomingRingtone(int generation) async {
    try {
      final player = _voiceRingtonePlayer ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      if (!_voiceRingtoneActive || generation != _voiceRingtoneGeneration) {
        return;
      }
      await player.play(
        BytesSource(_incomingRingtoneWave(), mimeType: 'audio/wav'),
      );
    } catch (_) {
      if (!_voiceRingtoneActive || generation != _voiceRingtoneGeneration) {
        return;
      }
      unawaited(_playVoiceAlert());
      _voiceRingtoneFallback = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_playVoiceAlert()),
      );
    }
  }

  Future<void> _playVoiceAlert() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  static Uint8List _incomingRingtoneWave() {
    const sampleRate = 16000;
    const durationSeconds = 4;
    const sampleCount = sampleRate * durationSeconds;
    const dataLength = sampleCount * 2;
    final wave = Uint8List(44 + dataLength);
    final header = ByteData.sublistView(wave);
    void writeTag(int offset, String tag) {
      for (var index = 0; index < tag.length; index++) {
        wave[offset + index] = tag.codeUnitAt(index);
      }
    }

    writeTag(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeTag(8, 'WAVE');
    writeTag(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeTag(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    const pulses = [(0.0, 0.38), (0.52, 0.90), (1.04, 1.42)];
    for (var sample = 0; sample < sampleCount; sample++) {
      final time = sample / sampleRate;
      final pulse = pulses
          .where((range) => time >= range.$1 && time < range.$2)
          .firstOrNull;
      if (pulse == null) continue;
      final pulseTime = time - pulse.$1;
      final pulseLength = pulse.$2 - pulse.$1;
      final envelope = math.min(
        1.0,
        math.min(pulseTime / 0.012, (pulseLength - pulseTime) / 0.012),
      );
      final tone =
          math.sin(2 * math.pi * 440 * time) +
          math.sin(2 * math.pi * 480 * time);
      final value = (tone * envelope * 8500).round().clamp(-32768, 32767);
      header.setInt16(44 + sample * 2, value, Endian.little);
    }
    return wave;
  }

  Future<void> _notifyIncomingCall(VoiceCallEvent event) async {
    final chat = chats.where((item) => item.id == event.chatId).firstOrNull;
    await NotificationService.instance.show(
      NotificationPayload(
        title: chat?.displayName ?? L10n.current.appName,
        body: L10n.current.chatIncomingCall(event.displayName),
        chatId: event.chatId,
      ),
    );
  }

  /// Sends [text] to [chatId], optionally with an [attachment], and, when
  /// [replyTo] is set, pointing at the message this one answers.
  Future<MessageInfo> sendMessage(
    int chatId,
    String text, {
    FileInfo? attachment,
    int? replyTo,
  }) async {
    var msg = await api.sendMessage(
      chatId,
      text,
      attachment: attachment,
      replyTo: replyTo,
    );
    refreshChats();
    return msg;
  }

  /// Forwards [message] into [targetChatId] as a copy.
  ///
  /// The content is cloned server-side from the message the actor can reach, so
  /// only the ids travel and the copy appears in the target chat as a brand new
  /// message authored by the caller. [ForwardManifest.forMessage] keeps a
  /// re-forward attributed to the original instead of the intermediate copy.
  Future<MessageInfo> forwardMessage(
    MessageInfo message,
    int targetChatId,
  ) async {
    final copy = await api.sendMessage(
      targetChatId,
      '',
      forward: ForwardManifest.forMessage(message),
    );
    refreshChats();
    return copy;
  }

  void onIncomingMessage(MessageInfo message) {
    _lastMessage[message.chatId] = message;
    final controller = _messageStreams[message.chatId];
    if (controller != null && !controller.isClosed) {
      controller.add(message);
    }
    _scheduleChatsRefresh();
    if (shouldNotifyForChatId(message.chatId)) {
      unawaited(_notifyIncoming(message));
    }
    notifyListeners();
  }

  /// Raises a local notification for a message that arrived over the websocket.
  ///
  /// This is the foreground counterpart to a push: the socket can stay alive in
  /// the background, and a notification must appear whether the frame came from
  /// FCM or from the socket.
  Future<void> _notifyIncoming(MessageInfo message) async {
    final chat = chats.where((item) => item.id == message.chatId).firstOrNull;
    final l10n = L10n.current;
    // A sticker-only body is a reference, not text; show a word instead of the
    // raw `<ugc:id>` markup, matching what the chat list preview does.
    final text = ugcPreviewText(
      message.text.trim(),
      l10n.ugcStickerPreview,
    );
    final preview = text.isNotEmpty
        ? text
        : message.attachmentName.isNotEmpty
        ? l10n.notificationSentAttachment
        : l10n.notificationNewMessage;
    await NotificationService.instance.show(
      NotificationPayload(
        title: chat?.displayName ?? l10n.appName,
        body: preview,
        chatId: message.chatId,
        // The same message may also arrive over a push transport; the id
        // collapses the pair into a single alert. It has to match the
        // message_id the backend puts in the push payload exactly, or the two
        // arrive as distinct keys and the user sees a duplicate.
        messageId: '${message.id}',
      ),
    );
  }

  Stream<MessageInfo> subscribeMessages(int chatId) {
    final existing = _messageStreams[chatId];
    if (existing != null && !existing.isClosed) return existing.stream;
    final controller = StreamController<MessageInfo>.broadcast();
    _messageStreams[chatId] = controller;
    return controller.stream;
  }

  /// Messages that were edited or deleted in [chatId], whether by this client
  /// or by another member over the websocket. Subscribers replace or drop the
  /// message with the change's id.
  Stream<MessageChange> subscribeMessageChanges(int chatId) {
    final existing = _messageChangeStreams[chatId];
    if (existing != null && !existing.isClosed) return existing.stream;
    final controller = StreamController<MessageChange>.broadcast();
    _messageChangeStreams[chatId] = controller;
    return controller.stream;
  }

  void _emitMessageChange(MessageChange change) {
    if (change.chatId == 0 || change.messageId == 0) return;
    final controller = _messageChangeStreams[change.chatId];
    if (controller != null && !controller.isClosed) controller.add(change);
    // The cached preview must not keep showing a message that is gone, but an
    // edit leaves the preview's text stale only until the next chat refresh.
    if (change.isDeleted &&
        _lastMessage[change.chatId]?.id == change.messageId) {
      _lastMessage[change.chatId] = null;
    }
    notifyListeners();
  }

  /// Applies an edited message everywhere the manager tracks it.
  void onMessageEdited(MessageInfo message) {
    if (message.id == 0) return;
    if (_lastMessage[message.chatId]?.id == message.id) {
      _lastMessage[message.chatId] = message;
    }
    _emitMessageChange(MessageChange.edited(message));
  }

  /// Records that [messageId] no longer exists in [chatId].
  void onMessageDeleted(int chatId, int messageId) {
    _emitMessageChange(MessageChange.deleted(chatId, messageId));
  }

  /// Edits one of this member's messages and echoes the change to subscribers.
  Future<MessageInfo> editMessage(
    int chatId,
    int messageId,
    String text,
  ) async {
    final updated = await api.editMessage(chatId, messageId, text);
    onMessageEdited(updated);
    return updated;
  }

  /// Deletes a message and echoes the removal to subscribers.
  Future<void> deleteMessage(int chatId, int messageId) async {
    await api.deleteMessage(chatId, messageId);
    onMessageDeleted(chatId, messageId);
  }

  /// Loads every member's read cursor for [chatId].
  ///
  /// A message carries a reader count, but that snapshot only moves when the
  /// message is fetched again. Seeding the full cursor map here lets
  /// [readCountForMessage] recompute any message's count locally and lets live
  /// receipts advance it, so a DM tick can flip the moment the peer reads.
  Future<void> refreshReadCursors(int chatId) async {
    try {
      final members = await api.members(chatId);
      if (profile == null) return;
      final cursors = _readCursors.putIfAbsent(chatId, () => {});
      for (final member in members) {
        final current = cursors[member.userId] ?? 0;
        if (member.lastReadMessageId > current) {
          cursors[member.userId] = member.lastReadMessageId;
        }
      }
      _readCursorsLoaded.add(chatId);
      notifyListeners();
    } catch (_) {
      // Members may be hidden from this account, or the response malformed; the
      // per-message snapshot counts keep working and receipts still move them
      // one cursor at a time, so a failed seed is not worth surfacing.
    }
  }

  /// Number of members known to have read [message], or null when this chat's
  /// cursors have not been loaded and the message's snapshot count should be
  /// used instead.
  int? readCountForMessage(MessageInfo message) {
    if (!_readCursorsLoaded.contains(message.chatId)) return null;
    final cursors = _readCursors[message.chatId];
    if (cursors == null) return null;
    var count = 0;
    for (final cursor in cursors.values) {
      if (cursor >= message.id) count++;
    }
    // The live cursors and the message's own snapshot are both lower bounds
    // that only grow, so whichever saw more readers is the better answer. This
    // keeps a freshly fetched count from being hidden by cursors that a live
    // receipt has not reached yet, and vice versa.
    return count > message.readCount ? count : message.readCount;
  }

  /// The UGC item with [id], or null when it has not been resolved yet.
  ///
  /// A message that mentions an item asks the renderer for it; the renderer
  /// then calls [ensureUgcItems] so the next rebuild has it.
  UgcItem? ugcItem(int id) => _ugcItems[id];

  /// Resolves the UGC items [ids] that are not in the cache yet.
  ///
  /// Items are fetched one request each and announced with a single
  /// [notifyListeners] once they have all settled, so a page of stickers costs
  /// one rebuild rather than one per image. A missing or forbidden item is
  /// remembered and never retried, which keeps a deleted sticker from firing a
  /// request on every rebuild of its message.
  Future<void> ensureUgcItems(Iterable<int> ids) async {
    final missing = <int>{
      for (final id in ids)
        if (id > 0 &&
            !_ugcItems.containsKey(id) &&
            !_ugcItemsLoading.contains(id) &&
            !_ugcItemsMissing.contains(id))
          id,
    };
    if (missing.isEmpty) return;
    _ugcItemsLoading.addAll(missing);
    try {
      await Future.wait(
        missing.map((id) async {
          try {
            final item = await api.ugcItem(id);
            _ugcItems[id] = item;
          } catch (_) {
            _ugcItemsMissing.add(id);
          } finally {
            _ugcItemsLoading.remove(id);
          }
        }),
      );
    } finally {
      if (missing.any(_ugcItems.containsKey)) notifyListeners();
    }
  }

  /// Forgets every resolved UGC item.
  ///
  /// The ids belong to one server and one account, so the cache is dropped when
  /// either changes rather than letting a stale sticker bleed across.
  void clearUgcItems() {
    _ugcItems.clear();
    _ugcItemsLoading.clear();
    _ugcItemsMissing.clear();
  }

  /// Applies a read receipt: the reader's cursor moves forward, never back, and
  /// the UI rebuilds so any message now covered by the cursor updates.
  void onReadReceipt(ReadReceipt receipt) {
    if (receipt.chatId == 0 || receipt.userId == 0) return;
    _advanceReadCursor(
      receipt.chatId,
      receipt.userId,
      receipt.lastReadMessageId,
    );
    // A single receipt is not enough to compute a whole count, and if the
    // member seed never ran (a failed or not-yet-finished fetch) the live
    // cursor would otherwise be ignored. Pull the member list so the counts
    // become exact.
    if (!_readCursorsLoaded.contains(receipt.chatId)) {
      unawaited(refreshReadCursors(receipt.chatId));
    }
    notifyListeners();
  }

  void _advanceReadCursor(int chatId, int userId, int messageId) {
    if (messageId <= 0) return;
    final cursors = _readCursors.putIfAbsent(chatId, () => {});
    if (messageId > (cursors[userId] ?? 0)) {
      cursors[userId] = messageId;
    }
  }

  Future<void> markRead(int chatId, {int? messageId}) async {
    _unread[chatId] = 0;
    final me = profile?.id;
    // The reader is always counted for what they just read, so the tick can
    // flip locally without waiting for the receipt to round-trip.
    if (me != null && messageId != null) {
      _advanceReadCursor(chatId, me, messageId);
    }
    notifyListeners();
    // Prefer the socket so the receipt fans out to the other members over the
    // same transport the message arrived on; fall back to HTTP when offline.
    final live = socket;
    if (live != null && connectionStatus == ConnectionStatus.connected) {
      live.send(8, {'chat_id': chatId, 'message_id': messageId ?? 0});
      return;
    }
    try {
      await api.markRead(chatId, messageId: messageId);
    } on ApiException catch (_) {
      // Non-fatal: we'll retry on the next message view.
    }
  }

  void incrementUnread(int chatId) {
    _unread[chatId] = (_unread[chatId] ?? 0) + 1;
    notifyListeners();
  }

  Future<void> persist() async {
    final preferences = await SharedPreferences.getInstance();
    await _persistAccounts(preferences);
  }

  String _accountId(String baseUrl, String identity) =>
      AccountRecord.idFor(baseUrl, identity);

  Profile? _profileFromPreferences(SharedPreferences preferences) {
    final raw = preferences.getString(_activeProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  ThemePreference _themePreferenceFromString(String? value) =>
      ThemePreference.values.where((item) => item.name == value).firstOrNull ??
      ThemePreference.system;

  AccentPreference _accentPreferenceFromString(String? value) {
    if (value == 'system' || value == 'materialYou') {
      return AccentPreference.system;
    }
    if (value == 'custom') return AccentPreference.custom;
    return AccentPreference.quttyBlue;
  }

  /// Resolves a stored language tag against the locales the app actually ships.
  ///
  /// A tag is dropped rather than trusted because the supported set shrinks
  /// between releases: a persisted "nl" left over from a build that had Dutch
  /// must fall back to the device language instead of pinning a locale nothing
  /// can translate.
  Locale? _localeFromString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.toLanguageTag() == value) return supported;
    }
    return null;
  }

  Locale? _supportedLocale(Locale? value) {
    if (value == null) return null;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == value.languageCode) return supported;
    }
    return null;
  }

  Future<void> _saveActiveAccount() async {
    if (api.token == null) return;
    final account = AccountRecord(
      id: _accountId(api.baseUrl, profile?.id.toString() ?? 'unknown'),
      label: profile?.handles.firstOrNull ?? profile?.displayName ?? 'Account',
      baseUrl: api.baseUrl,
      token: api.token!,
    );
    accounts = [...accounts.where((item) => item.id != account.id), account];
    activeAccountId = account.id;
    await persist();
  }

  Future<void> _activateAccount(String accountId, {bool connect = true}) async {
    final account = accounts.where((item) => item.id == accountId).firstOrNull;
    if (account == null) return;
    // The call belongs to the account being left, so hang up while its token is
    // still in place both locally and on the server.
    await _teardownActiveCall(notifyServer: true);
    // A device token is registered per server. Detach it from the outgoing
    // account before switching, or that server keeps pushing to this device.
    await _unregisterAllDevices();
    _deviceId = null;
    await disconnectSocket();
    api.baseUrl = account.baseUrl;
    api.token = account.token;
    await SessionStore.saveToken(account.token);
    activeAccountId = account.id;
    // Read cursors belong to the account being left; the incoming account's
    // chats share ids but not readers, so start clean before loading them.
    _readCursors.clear();
    _readCursorsLoaded.clear();
    clearUgcItems();
    profile = await api.me();
    await refreshChats();
    if (connect) await connectWebSocket();
    await persist();
    unawaited(syncPushRegistration());
  }

  Future<void> _persistAccounts([SharedPreferences? preferences]) async {
    final store = preferences ?? await SharedPreferences.getInstance();
    for (final account in accounts) {
      await SessionStore.saveAccountToken(account.id, account.token);
    }
    await store.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
    if (activeAccountId == null) {
      await store.remove(_activeAccountKey);
    } else {
      await store.setString(_activeAccountKey, activeAccountId!);
    }
    final cachedProfile = profile?.toJson();
    if (cachedProfile == null) {
      await store.remove(_activeProfileKey);
    } else {
      await store.setString(_activeProfileKey, jsonEncode(cachedProfile));
    }
  }

  Future<void> startDeepLinks() async {
    _appLinks = AppLinks();
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) receiveDeepLink(initial.toString());
    _appLinks!.uriLinkStream.listen((uri) => receiveDeepLink(uri.toString()));
  }

  /// Holds a link the app was opened with, if it is one the app can route.
  ///
  /// Both kinds the app takes -- a chat invite and a shared sticker pack --
  /// arrive through the same OS hook, so both are stored here and told apart
  /// when the router is ready.
  void receiveDeepLink(String value) {
    if (parseJoinLink(value) == null && parseUgcShareLink(value) == null) return;
    pendingDeepLink = value;
    notifyListeners();
  }

  String? takePendingDeepLink() {
    final value = pendingDeepLink;
    pendingDeepLink = null;
    notifyListeners();
    return value;
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socketStatusSub?.cancel();
    _notificationTapSub?.cancel();
    _chatsRefreshDebounce?.cancel();
    socket?.dispose();
    for (final c in _messageStreams.values) {
      c.close();
    }
    for (final c in _messageChangeStreams.values) {
      c.close();
    }
    super.dispose();
  }
}
