import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';

/// Reveals a small debug panel over the top-left corner when the background is
/// held for a moment.
///
/// The long-press handler lives on an ancestor of the whole app, so it only
/// wins the gesture where nothing deeper claims a long press: empty space,
/// backgrounds and list padding. Long-pressing a message, an input or a control
/// keeps its own behaviour.
class DebugLongPressOverlay extends StatefulWidget {
  const DebugLongPressOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<DebugLongPressOverlay> createState() => _DebugLongPressOverlayState();
}

class _DebugLongPressOverlayState extends State<DebugLongPressOverlay> {
  bool _visible = false;

  void _toggle() => setState(() => _visible = !_visible);

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onLongPress: _toggle,
    child: Stack(
      children: [
        widget.child,
        if (_visible)
          const Positioned(
            top: 0,
            left: 0,
            // Taps fall through to the app; only the long-press above toggles
            // the panel back off.
            child: IgnorePointer(
              child: SafeArea(child: Padding(
                padding: EdgeInsets.all(8),
                child: DebugInfoPanel(),
              )),
            ),
          ),
      ],
    ),
  );
}

/// The panel itself: a compact, live snapshot of the app's technical state.
class DebugInfoPanel extends StatelessWidget {
  const DebugInfoPanel({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppManager.instance,
    builder: (context, _) {
      final manager = AppManager.instance;
      final call = manager.activeCall;
      final room = call?.room;
      final lines = <String>['call debug'];
      if (call != null) {
        lines.add(
          'call: ${call.chatId} ${call.connecting ? "connecting" : call.active ? formatCallDuration(call.duration) : "calling"}',
        );
        lines.add('mic:${call.microphoneEnabled} cam:${call.cameraEnabled} screen:${call.screenShareEnabled} spk:${call.speakerEnabled}');
      }
      if (room != null) {
        final locals = room.localParticipant != null ? 1 : 0;
        final remotes = room.remoteParticipants.length;
        lines.add('p: l:$locals r:$remotes');
        final local = room.localParticipant;
        if (local != null) {
          lines.add('lq:${local.connectionQuality.name}');
        }
        if (remotes > 0) {
          final rp = room.remoteParticipants.values.first;
          lines.add('rq:${rp.connectionQuality.name}');
        }
      }
      if (manager.incomingVoiceCall != null) {
        lines.add('ringing: ${manager.incomingVoiceCall!.chatId}');
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 11,
            height: 1.3,
            fontFamily: 'monospace',
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final line in lines) Text(line)],
          ),
        ),
      );
    },
  );
}
