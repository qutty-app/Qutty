import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qutty/api/ugc_link.dart';
import 'package:qutty/l10n/l10n.dart';

/// Puts a pack's share link on the clipboard and says so.
///
/// Copying is the whole of sharing: there is no server round trip and no
/// third-party sheet, so the snackbar is the only feedback there is. The link
/// itself is what a recipient opens to reach the pack.
Future<void> copyUgcPackLink(BuildContext context, int packId) async {
  await Clipboard.setData(ClipboardData(text: ugcShareLink(packId)));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.ugcLinkCopied),
      duration: const Duration(seconds: 1),
    ),
  );
}
