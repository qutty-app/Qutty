import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';

/// Which side of a DM a delete applies to.
enum DmDeleteScope { both, me }

/// The confirmations and requests behind leaving or deleting a chat.
///
/// The same flows are reachable from the chat profile (where a normal member
/// gets the action in place of the settings button) and from chat settings
/// (where an admin or the creator finds it), so they live in one place.
class ChatExitActions {
  ChatExitActions._();

  /// Leaves a chat or channel, or runs the DM delete-for scope flow.
  ///
  /// The creator cannot leave without transferring ownership first; that is
  /// explained rather than sent to the server to fail.
  static Future<void> leaveOrDelete(
    BuildContext context, {
    required ChatInfo chat,
    required String role,
  }) async {
    if (role == 'creator') {
      await _showOwnershipRequired(context);
      return;
    }
    if (chat.chatType == 'dm') {
      final scope = await _chooseDmScope(context);
      if (scope == null || !context.mounted) return;
      final confirmed = await _confirmDmDelete(context, scope);
      if (!confirmed || !context.mounted) return;
      await _run(
        context,
        () => scope == DmDeleteScope.both
            ? AppManager.instance.api.deleteChat(chat.id)
            : AppManager.instance.api.leaveChat(chat.id),
      );
      return;
    }
    final confirmed = await _confirmLeave(
      context,
      isChannel: chat.chatType == 'channel',
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, () => AppManager.instance.api.leaveChat(chat.id));
  }

  /// Deletes a chat or channel for everyone. Only the creator can do this.
  static Future<void> deleteChat(BuildContext context, ChatInfo chat) async {
    final confirmed = await _confirmDelete(context, chat);
    if (!confirmed || !context.mounted) return;
    final slid = await _confirmSlideDelete(context);
    if (!slid || !context.mounted) return;
    await _run(context, () => AppManager.instance.api.deleteChat(chat.id));
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() request,
  ) async {
    try {
      await request();
      await AppManager.instance.refreshChats();
      if (context.mounted) context.go('/');
    } on ApiException catch (exception) {
      if (!context.mounted) return;
      if (exception.code == 'creator_must_delete') {
        await _showOwnershipRequired(context);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  /// Keeps dialog actions on one line. The app's filled/outlined buttons default
  /// to an infinite minimum width (they are full-width settings buttons), which
  /// makes an [AlertDialog] stack them unless the width is constrained here.
  static Widget _actionRow(List<Widget> children) {
    // Wrap rather than Row: if a locale's labels are too wide for the dialog,
    // the extra action moves to a second line instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 6,
      children: children,
    );
  }

  static ButtonStyle _filledAction(
    BuildContext context, {
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: destructive ? scheme.error : null,
      foregroundColor: destructive ? scheme.onError : null,
    );
  }

  static ButtonStyle _outlinedAction(BuildContext context) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      );

  static ButtonStyle _textAction(BuildContext context) => TextButton.styleFrom(
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 10),
  );

  static Future<bool> _confirmLeave(
    BuildContext context, {
    required bool isChannel,
  }) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          isChannel ? l10n.chatLeaveConfirmChannel : l10n.chatLeaveConfirmChat,
        ),
        actions: [
          _actionRow([
            TextButton(
              style: _textAction(context),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonStay),
            ),
            FilledButton(
              style: _filledAction(context, destructive: true),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.chatSettingsLeave),
            ),
          ]),
        ],
      ),
    );
    return result == true;
  }

  static Future<void> _showOwnershipRequired(BuildContext context) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.chatLeaveOwnerWarning),
        actions: [
          FilledButton(
            style: _filledAction(context),
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  static Future<DmDeleteScope?> _chooseDmScope(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<DmDeleteScope>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.chatDmDeleteForTitle),
        actions: [
          _actionRow([
            TextButton(
              style: _textAction(context),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            OutlinedButton(
              style: _outlinedAction(context),
              onPressed: () => Navigator.pop(context, DmDeleteScope.both),
              child: Text(l10n.chatDmDeleteForBoth),
            ),
            FilledButton(
              style: _filledAction(context),
              onPressed: () => Navigator.pop(context, DmDeleteScope.me),
              child: Text(l10n.chatDmDeleteForMe),
            ),
          ]),
        ],
      ),
    );
  }

  static Future<bool> _confirmDmDelete(
    BuildContext context,
    DmDeleteScope scope,
  ) {
    final l10n = context.l10n;
    return _showSlideConfirm(
      context,
      question: scope == DmDeleteScope.both
          ? l10n.chatDmDeleteBothConfirm
          : l10n.chatDmDeleteSelfConfirm,
      label: l10n.chatSlideToConfirm,
    );
  }

  static Future<bool> _confirmDelete(
    BuildContext context,
    ChatInfo chat,
  ) async {
    final l10n = context.l10n;
    final question = chat.handles.isEmpty
        ? l10n.chatDeleteConfirmNoHandle(chat.displayName)
        : l10n.chatDeleteConfirmWithHandle(
            chat.displayName,
            chat.handles.first,
          );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(question),
        actions: [
          _actionRow([
            TextButton(
              style: _textAction(context),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: _filledAction(context, destructive: true),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ]),
        ],
      ),
    );
    return result == true;
  }

  static Future<bool> _confirmSlideDelete(BuildContext context) {
    final l10n = context.l10n;
    return _showSlideConfirm(
      context,
      question: l10n.chatSettingsDeleteBody,
      label: l10n.chatSlideToDelete,
    );
  }

  static Future<bool> _showSlideConfirm(
    BuildContext context, {
    required String question,
    required String label,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(question),
            const SizedBox(height: 20),
            SlideToConfirm(
              label: label,
              onConfirmed: () => Navigator.pop(context, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: _textAction(context),
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
        ],
      ),
    );
    return result == true;
  }
}

/// A destructive action that only fires once its thumb is dragged to the end.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  static const double _height = 56;
  static const double _thumbWidth = 56;

  /// Which part of the bar the drag started on. A press anywhere else (notably
  /// the end of the track) must not count as a slide.
  final GlobalKey _trackKey = GlobalKey();
  double _progress = 0;
  bool _dragging = false;
  bool _grabbedThumb = false;
  double _dragStartX = 0;
  double _dragStartProgress = 0;

  RenderBox? get _trackBox =>
      _trackKey.currentContext?.findRenderObject() as RenderBox?;

  void _handleDragDown(DragDownDetails details) {
    final box = _trackBox;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final travel = box.size.width - _thumbWidth;
    final thumbLeft = _progress * travel;
    // A little tolerance makes the thumb easier to grab without turning the
    // rest of the track into a tap target.
    _grabbedThumb =
        local.dx >= thumbLeft - 8 && local.dx <= thumbLeft + _thumbWidth + 8;
    _dragStartX = details.globalPosition.dx;
    _dragStartProgress = _progress;
  }

  void _handleDragStart(DragStartDetails details) {
    if (!_grabbedThumb) return;
    setState(() => _dragging = true);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final box = _trackBox;
    if (box == null) return;
    final travel = box.size.width - _thumbWidth;
    if (travel <= 0) return;
    final delta = (details.globalPosition.dx - _dragStartX) / travel;
    setState(() {
      _progress = (_dragStartProgress + delta).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    setState(() => _dragging = false);
    if (_progress >= 0.999) {
      widget.onConfirmed();
    } else {
      setState(() => _progress = 0);
    }
  }

  void _handleDragCancel() {
    if (!_dragging) return;
    setState(() {
      _dragging = false;
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resetDuration = _dragging
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      label: widget.label,
      value: '${(_progress * 100).round()}%',
      child: SizedBox(
        key: _trackKey,
        height: _height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_height / 2),
                child: CustomPaint(
                  painter: _SlideProgressPainter(
                    progress: _progress,
                    thumbWidth: _thumbWidth,
                    color: scheme.error.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedAlign(
                alignment: Alignment(-1 + _progress * 2, 0),
                duration: resetDuration,
                curve: Curves.easeOutCubic,
                child: IgnorePointer(
                  child: Container(
                    width: _thumbWidth,
                    height: _height,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.error.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: scheme.onError,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragDown: _handleDragDown,
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                onHorizontalDragCancel: _handleDragCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills the bar up to the middle of the thumb.
///
/// The thumb travels over `width - thumbWidth`, so the fill follows that travel
/// plus half the thumb, reaching only the ball's midpoint instead of running
/// past it or stopping at its leading edge.
class _SlideProgressPainter extends CustomPainter {
  final double progress;
  final double thumbWidth;
  final Color color;

  const _SlideProgressPainter({
    required this.progress,
    required this.thumbWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = progress * (size.width - thumbWidth) + thumbWidth / 2;
    if (width <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SlideProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      thumbWidth != oldDelegate.thumbWidth ||
      color != oldDelegate.color;
}
