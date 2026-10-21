/// The link that carries a UGC pack between accounts.
///
/// A pack is shared, not sent: the link holds the pack's id and nothing else,
/// so the recipient resolves it against the same endpoints the owner's
/// developer portal uses. It rides the same rails as a chat invite -- the
/// `qutty` scheme inside the app and `qutty.app` on the web, where the route is
/// served -- which keeps one parser for one kind of link.
library;

/// The share link for the pack with [packId].
String ugcShareLink(int packId) => 'https://qutty.app/sticker/$packId';

/// The pack id in a sticker link, or null when [input] is not one.
///
/// Accepts the two shapes a link can arrive in: `qutty.app/sticker/<id>` with
/// or without a scheme, and `qutty://sticker/<id>` for a link that only ever
/// had the app in mind.
int? parseUgcShareLink(String input) {
  var value = input.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
  if (uri == null) return null;
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);

  if (uri.scheme.toLowerCase() == 'qutty' && uri.host == 'sticker') {
    if (segments.isEmpty) return null;
    value = segments.first;
  } else {
    final host = uri.host.toLowerCase();
    if (host != 'qutty.app' && host != 'www.qutty.app') return null;
    final parts = segments.toList();
    if (parts.length < 2 || parts.first != 'sticker') return null;
    value = parts[1];
  }
  return int.tryParse(value);
}
