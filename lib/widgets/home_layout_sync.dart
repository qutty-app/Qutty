import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/widgets/adaptive.dart';

/// Keeps the wide two-pane shell down to a single page.
///
/// On a narrow layout a chat is a page pushed on top of the chat list, so the
/// stack can hold both `/` and `/chat/:id`. Widening the window then asks the
/// wide page builder for a shell page per match, even though the wide layout
/// only ever wants one. Collapsing the stack to the location the user is
/// actually looking at leaves the two-pane shell single again.
class HomeLayoutSync extends StatefulWidget {
  const HomeLayoutSync({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  State<HomeLayoutSync> createState() => _HomeLayoutSyncState();
}

class _HomeLayoutSyncState extends State<HomeLayoutSync> {
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_schedule);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_schedule);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reading MediaQuery is what subscribes this widget to size changes.
    MediaQuery.sizeOf(context);
    _schedule();
  }

  void _schedule() {
    // Routing runs after the current notification burst so it can never race a
    // build (a resize rebuilds the pages in the very frame that noticed it).
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      _collapse();
    });
  }

  void _collapse() {
    if (!isWideScreen(context)) return;
    final configuration = widget.router.routerDelegate.currentConfiguration;
    final alternates = configuration.matches
        .where((match) => isHomeLocation(match.matchedLocation))
        .length;
    if (alternates < 2) return;
    // Only rewrite the whole stack when the shell is on top; anything else
    // (a call, settings) must keep its place, and gets collapsed once it pops.
    final top = configuration.matches.last;
    if (!isHomeLocation(top.matchedLocation)) return;
    // A pushed page carries its own location (query included); a declared one
    // is the configuration's own.
    final location = top is ImperativeRouteMatch
        ? top.matches.uri.toString()
        : configuration.uri.toString();
    widget.router.go(location);
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return widget.child;
  }
}
