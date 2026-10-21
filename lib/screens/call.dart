import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:livekit_client/livekit_client.dart'
    show
        AudioManager,
        PlatformType,
        VideoTrack,
        lkPlatform,
        lkPlatformIsWebMobile;

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/services/native_call_service.dart';
import 'package:qutty/services/screen_picker.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/call_video_layout.dart';
import 'package:qutty/widgets/screen_share_picker.dart';
import 'package:qutty/widgets/debug_overlay.dart';

@Preview(name: 'Incoming Call')
Widget incomingCallPreview() {
  // Seed the singleton the page listens to. The ringtone, notifications and
  // native call UI are all disabled so a preview never plays audio or reaches
  // for a platform channel.
  final manager = AppManager.instance;
  // ignore: invalid_use_of_visible_for_testing_member
  manager.enableCallRingtone = false;
  manager.notificationsEnabled = false;
  // ignore: invalid_use_of_visible_for_testing_member
  NativeCallService.instance.enableNativeCalls = false;
  manager.onVoiceCallEvent(
    const VoiceCallEvent(
      type: 'started',
      chatId: 123,
      userId: 1,
      displayName: 'John Doe',
    ),
  );

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const CallScreen(chatId: 123),
  );
}

/// Full-page call surface, reached at `/call/:id`.
///
/// The same route serves both halves of a call: while a call is ringing it
/// offers answer/dismiss, and once joined it becomes the in-call page with the
/// microphone, minimise and hang-up controls. Minimising swaps this page for the
/// small bar rendered above every chat.
class CallScreen extends StatelessWidget {
  const CallScreen({super.key, required this.chatId});

  final int chatId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppManager.instance,
    builder: (context, _) {
      final manager = AppManager.instance;
      final active = manager.activeCall;
      if (active != null && active.chatId == chatId) {
        return _ActiveCallView(call: active);
      }
      final call = manager.incomingVoiceCallForChat(chatId);
      if (call == null) return const Scaffold();
      return _RingingCallView(chatId: chatId, call: call);
    },
  );
}

class _RingingCallView extends StatelessWidget {
  const _RingingCallView({required this.chatId, required this.call});

  final int chatId;
  final VoiceCallEvent call;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Avatar(
                    baseUrl: manager.api.baseUrl,
                    imageUrl: manager.avatarUrlForChat(chatId),
                    displayName: call.displayName,
                    radius: 48,
                    fallbackIcon: Icons.call_received,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    call.displayName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chatIncomingCall(call.displayName),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      Tooltip(
                        message: l10n.chatDismissCall,
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              manager.dismissIncomingVoiceCall(chatId),
                          icon: const Icon(Icons.call_end),
                          label: Text(l10n.chatDismissCall),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.errorContainer,
                            foregroundColor: colors.onErrorContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            manager.acceptIncomingVoiceCall(chatId),
                        icon: const Icon(Icons.call),
                        label: Text(l10n.chatJoinCall),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveCallView extends StatelessWidget {
  const _ActiveCallView({required this.call});

  final ActiveCall call;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final room = call.room;
    final participantCount = room == null
        ? 0
        : 1 + room.remoteParticipants.length;
    final isGroup =
        !call.isDirect || manager.forceGroupCall || participantCount > 2;
    final feeds = room == null || isGroup
        ? const <CallVideoFeed>[]
        : buildCallVideoFeeds(room);
    final slots = room == null || !isGroup
        ? const <CallSlot>[]
        : buildCallSlots(room);
    final tracks = room == null
        ? const <String, VideoTrack>{}
        : callVideoTracks(room);
    final showVideoUi = isGroup ? slots.isNotEmpty : feeds.isNotEmpty;
    return PopScope(
      // Back (or a swipe-down) collapses the call instead of popping the page,
      // so the session is never left running behind a page the user dismissed.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        manager.minimizeActiveCall();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.chatMinimizeCall,
            onPressed: manager.minimizeActiveCall,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ),
        body: DebugLongPressOverlay(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: showVideoUi ? 720 : 480,
                      ),
                      child: isGroup
                          ? (slots.isEmpty
                                ? _CallPortrait(call: call)
                                : CallGroupLayout(
                                    slots: slots,
                                    tracks: tracks,
                                    avatarBaseUrl: manager.api.baseUrl,
                                    selfLabel: l10n.membersYou,
                                  ))
                          : (feeds.isEmpty
                                ? _CallPortrait(call: call)
                                : CallVideoStage(
                                    feeds: feeds,
                                    tracks: tracks,
                                    avatarBaseUrl: manager.api.baseUrl,
                                    selfLabel: l10n.membersYou,
                                  )),
                    ),
                  ),
                ),
                if (showVideoUi)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: Column(
                      children: [
                        Text(
                          call.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _callStatusText(call, l10n),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      _CallToggle(
                        tooltip: call.microphoneEnabled
                            ? l10n.chatMuteMicrophone
                            : l10n.chatUnmuteMicrophone,
                        active: call.microphoneEnabled,
                        onPressed: call.connecting
                            ? null
                            : manager.toggleCallMicrophone,
                        icon: call.microphoneEnabled ? Icons.mic : Icons.mic_off,
                      ),
                      _CallToggle(
                        tooltip: call.cameraEnabled
                            ? l10n.chatDisableWebcam
                            : l10n.chatEnableWebcam,
                        active: call.cameraEnabled,
                        onPressed: call.connected
                            ? manager.toggleCallWebcam
                            : null,
                        icon: call.cameraEnabled
                            ? Icons.videocam
                            : Icons.videocam_off,
                      ),
                      if (manager.callScreenShareAllowed &&
                          !lkPlatformIsWebMobile())
                        _CallToggle(
                          tooltip: call.screenShareEnabled
                              ? l10n.chatDisableScreenShare
                              : l10n.chatEnableScreenShare,
                          active: call.screenShareEnabled,
                          onPressed: call.connected
                              ? () => _handleScreenShare(context, manager, call)
                              : null,
                          icon: call.screenShareEnabled
                              ? Icons.stop_screen_share
                              : Icons.screen_share_outlined,
                        ),
                      if (AudioManager.instance.canSwitchSpeakerphone)
                        _CallToggle(
                          tooltip: call.speakerEnabled
                              ? l10n.chatDisableSpeaker
                              : l10n.chatEnableSpeaker,
                          active: call.speakerEnabled,
                          onPressed: call.connected
                              ? manager.toggleCallSpeaker
                              : null,
                          icon: call.speakerEnabled
                              ? Icons.volume_up
                              : Icons.volume_off,
                        ),
                      IconButton.filled(
                        tooltip: call.ownsCall
                            ? l10n.chatEndCall
                            : l10n.chatLeaveCall,
                        onPressed: () => manager.leaveCall(),
                        icon: const Icon(Icons.call_end),
                        iconSize: 28,
                        padding: const EdgeInsets.all(16),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.errorContainer,
                          foregroundColor: colors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ringing/idle portrait shown before any video is on screen.
class _CallPortrait extends StatelessWidget {
  const _CallPortrait({required this.call});

  final ActiveCall call;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(
            baseUrl: manager.api.baseUrl,
            imageUrl: call.avatarUrl,
            displayName: call.displayName,
            radius: 48,
          ),
          const SizedBox(height: 24),
          Text(
            call.displayName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _callStatusText(call, l10n),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _callStatusText(ActiveCall call, AppLocalizations l10n) {
  if (call.active) return formatCallDuration(call.duration);
  if (call.connecting) return l10n.chatConnectingCall;
  return l10n.chatCalling;
}

/// Starts or stops the screen share.
///
/// The picker is chosen by platform: macOS drives its own
/// `SCContentSharingPicker`, web/Android/iOS show the OS or browser dialog, and
/// the remaining desktops (Windows, Linux) plus any unsupported macOS use the
/// in-app source list. The debug `FallBackSelectorCast` switch forces the
/// in-app list everywhere.
Future<void> _handleScreenShare(
  BuildContext context,
  AppManager manager,
  ActiveCall call,
) async {
  if (call.screenShareEnabled) {
    await manager.stopCallScreenShare();
    return;
  }

  if (manager.fallbackSelectorCast) {
    await _pickInAppSource(context, manager);
    return;
  }

  if (lkPlatform() == PlatformType.macOS) {
    final native = await NativeScreenPicker.instance.pick();
    if (native != null) {
      if (native.status == NativeScreenPickStatus.cancelled) return;
      final sourceId = await _resolveNativeSource(manager, native);
      if (sourceId != null) {
        await manager.startCallScreenShare(sourceId);
        return;
      }
    }
    if (!context.mounted) return;
    // macOS before 14, or a window we cannot match: fall back to the list.
    await _pickInAppSource(context, manager);
    return;
  }

  if (manager.platformOwnsScreenSharePicker) {
    await manager.toggleCallScreenShare();
    return;
  }

  await _pickInAppSource(context, manager);
}

Future<void> _pickInAppSource(BuildContext context, AppManager manager) async {
  final source = await showScreenShareSourcePicker(context);
  if (source == null) return;
  await manager.startCallScreenShare(source.id);
}

/// Turns a native macOS pick into a source id the in-app capturer understands.
///
/// A chosen display is already an id; a chosen window is matched to the source
/// list by title, since the window id the OS reports is not the one the plugin
/// expects.
Future<String?> _resolveNativeSource(
  AppManager manager,
  NativeScreenPick pick,
) async {
  if (pick.isScreen && pick.sourceId != null) return pick.sourceId;
  final label = pick.label;
  if (label == null || label.isEmpty) return null;
  final List<ScreenShareSource> sources;
  try {
    sources = await manager.listScreenShareSources();
  } on Exception {
    return null;
  }
  for (final source in sources) {
    if (!source.isScreen && source.name == label) return source.id;
  }
  return null;
}

/// Round in-call control that lights up while its feature is on.
class _CallToggle extends StatelessWidget {
  const _CallToggle({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      padding: const EdgeInsets.all(16),
      style: active
          ? IconButton.styleFrom(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
            )
          : null,
    );
  }
}
