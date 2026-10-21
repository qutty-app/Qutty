import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';

/// Shows the current call as a small bar above [child].
///
/// It sits at the top of the home surface (the chat list and every chat), so a
/// call started in one conversation stays reachable after switching to another.
/// While the full `/call/:id` page is open this bar is covered by it; the bar is
/// what the minimised state looks like, and tapping it re-opens the page.
class ActiveCallShell extends StatelessWidget {
  const ActiveCallShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppManager.instance,
    builder: (context, _) {
      final call = AppManager.instance.activeCall;
      if (call == null) return child;
      final colors = Theme.of(context).colorScheme;
      return Column(
        children: [
          Material(
            color: colors.secondaryContainer,
            child: SafeArea(bottom: false, child: _ActiveCallBar(call: call)),
          ),
          // The bar has already consumed the top inset. Strip it from the child
          // so its own AppBar does not pad for the status bar a second time.
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _ActiveCallBar extends StatelessWidget {
  const _ActiveCallBar({required this.call});

  final ActiveCall call;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return InkWell(
      onTap: manager.expandActiveCall,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        child: Row(
          children: [
            Avatar(
              baseUrl: manager.api.baseUrl,
              imageUrl: call.avatarUrl,
              displayName: call.displayName,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    call.active
                        ? formatCallDuration(call.duration)
                        : call.connecting
                        ? l10n.chatConnectingCall
                        : l10n.chatCalling,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: call.microphoneEnabled
                  ? l10n.chatMuteMicrophone
                  : l10n.chatUnmuteMicrophone,
              onPressed: call.connecting
                  ? null
                  : () => manager.toggleCallMicrophone(),
              icon: Icon(
                call.microphoneEnabled ? Icons.mic : Icons.mic_off,
                color: colors.onSecondaryContainer,
              ),
            ),
            IconButton(
              tooltip: call.ownsCall ? l10n.chatEndCall : l10n.chatLeaveCall,
              onPressed: () => manager.leaveCall(),
              icon: Icon(Icons.call_end, color: colors.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
