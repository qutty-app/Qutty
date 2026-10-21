import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/ugc.dart';

/// Shows the popup for one UGC item.
///
/// The popup is the same wherever a sticker or emoji is pressed -- in the
/// composer's picker and on a message that already carries one -- so it lives
/// here rather than in either caller. It draws the item large, names the pack
/// it belongs to, and offers what a pressed item can ask for: save or unsave
/// that pack, copy the pack's share link, and put the item's reference where
/// the caller wants it.
///
/// [saved] is the pack's state at the moment the popup opens. [onToggleSave]
/// receives the state the user asked for and answers whether it stuck, so the
/// heart can fall back when the server refuses. [onInsert] is omitted where
/// inserting makes no sense; the heart and the share action are likewise left
/// out when no pack is known, since both act on a pack.
/// 
Future<void> showUgcPopup(
  BuildContext context, {
  required UgcItem item,
  String? packName,
  bool saved = false,
  Future<bool> Function(bool saved)? onToggleSave,
  VoidCallback? onInsert,
  VoidCallback? onShare,
}) {
  var isSaved = saved;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(packName ?? item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UgcThumb(item: item, size: 128),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            if (onShare != null)
              IconButton(
                tooltip: l10n.ugcSharePack,
                icon: const Icon(Icons.share_outlined),
                onPressed: onShare,
              ),
            if (onToggleSave != null)
              IconButton(
                tooltip: isSaved ? l10n.ugcUnsavePack : l10n.ugcSavePack,
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? Colors.redAccent : null,
                ),
                onPressed: () async {
                  final wanted = !isSaved;
                  setDialogState(() => isSaved = wanted);
                  final ok = await onToggleSave(wanted);
                  // The server refused: put the heart back where it was.
                  if (!ok && dialogContext.mounted) {
                    setDialogState(() => isSaved = !wanted);
                  }
                },
              ),
            if (onInsert != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onInsert();
                },
                child: Text(l10n.ugcStickerInsert),
              ),
          ],
        );
      },
    ),
  );
}
