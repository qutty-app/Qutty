import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/app_manager.dart';

/// Keeps the call route in sync with [AppManager].
///
/// The call surface is a real page (`/call/:id`) rather than an overlay, so this
/// wrapper opens it when a call starts ringing and keeps it open while a call is
/// active and expanded. Minimising an active call pops the page, which is what
/// reveals the small bar shown above every chat; tapping that bar sets the call
/// back to expanded and this pushes the page again. It preserves whatever page
/// the user was on, because the call page is pushed on top of it.
class CallRouteSync extends StatefulWidget {
  const CallRouteSync({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  State<CallRouteSync> createState() => _CallRouteSyncState();
}

class _CallRouteSyncState extends State<CallRouteSync> {
  final manager = AppManager.instance;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    manager.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    manager.removeListener(_sync);
    super.dispose();
  }

  String get _location {
    final matches = widget.router.routerDelegate.currentConfiguration.matches;
    return matches.isEmpty ? '/' : matches.last.matchedLocation;
  }

  void _sync() {
    // Navigation runs after the current notification burst so a concurrent
    // router refresh (the router's own manager listener) cannot race the push
    // or pop below.
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _applyRoute();
    });
  }

  void _applyRoute() {
    if (!manager.isLoggedIn) return;
    final location = _location;
    final onCallRoute = location.startsWith('/call/');

    // A ringing call always wins the page; an active call keeps it only until
    // the user minimises it, after which the bar stands in for it.
    final active = manager.activeCall;
    final targetChatId =
        manager.incomingVoiceCall?.chatId ??
        (active != null && !active.minimized ? active.chatId : null);

    if (targetChatId == null) {
      if (onCallRoute) widget.router.pop();
      return;
    }

    final target = '/call/$targetChatId';
    if (location == target) return;
    // A second call while one is already on screen reuses the same page rather
    // than stacking another.
    if (onCallRoute) {
      widget.router.replace(target);
    } else {
      widget.router.push(target);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
