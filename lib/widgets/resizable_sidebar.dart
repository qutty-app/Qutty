import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:qutty/widgets/adaptive.dart';

/// A two-pane layout whose first pane can be dragged wider or narrower.
///
/// The pane never shrinks below [minWidth] and the second pane keeps at least
/// [minContentWidth], so a wide window always leaves a usable chat area. The
/// split can be reset to [initialWidth] by double-tapping the handle.
class ResizableSidebar extends StatefulWidget {
  const ResizableSidebar({
    super.key,
    required this.sidebar,
    required this.child,
    this.initialWidth = kChatListDefaultWidth,
    this.minWidth = kChatListMinWidth,
    this.minContentWidth = 320,
    this.handleKey,
  });

  final Widget sidebar;
  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double minContentWidth;

  /// Key applied to the drag handle, for tests and for keyboard tooling.
  final Key? handleKey;

  @override
  State<ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<ResizableSidebar> {
  late double _width = widget.initialWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The chat pane gets the rest of the window, but never less than its
        // minimum; on a window that is too small for both minimums the list
        // wins so the shell still renders.
        final maxWidth = math.max(
          widget.minWidth,
          constraints.maxWidth - widget.minContentWidth,
        );
        final width = _width.clamp(widget.minWidth, maxWidth);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: width, child: widget.sidebar),
            _ResizeHandle(
              key: widget.handleKey,
              onDragUpdate: (delta) {
                final current = _width.clamp(widget.minWidth, maxWidth);
                final next = (current + delta).clamp(widget.minWidth, maxWidth);
                if (next == current) return;
                setState(() => _width = next);
              },
              onReset: () {
                final next = widget.initialWidth.clamp(
                  widget.minWidth,
                  maxWidth,
                );
                if (next == _width) return;
                setState(() => _width = next);
              },
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}

/// The thin, full-height grip between the two panes.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    super.key,
    required this.onDragUpdate,
    required this.onReset,
  });

  final ValueChanged<double> onDragUpdate;
  final VoidCallback onReset;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) =>
            widget.onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        onDoubleTap: widget.onReset,
        child: Container(
          width: 9,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: active ? 3 : 1,
            height: double.infinity,
            decoration: BoxDecoration(
              color: active ? colors.primary : colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
