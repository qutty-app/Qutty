enum JoinLinkType { handle, invite }

class JoinLink {
  final JoinLinkType type;
  final String value;

  const JoinLink(this.type, this.value);

  String get display => 'qutty.app/join/$value';
}

JoinLink? parseJoinLink(String input) {
  var value = input.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();

  if (uri.scheme.toLowerCase() == 'qutty' &&
      host == 'join' &&
      segments.isNotEmpty) {
    value = segments.first;
  } else if ((host == 'qutty.app' &&
          segments.length >= 2 &&
          segments.first == 'invite') ||
      (host == 'invite.qutty' && segments.isNotEmpty)) {
    value = segments.last;
  } else if (value.startsWith('@')) {
    value = value.substring(1);
    return value.isEmpty ? null : JoinLink(JoinLinkType.handle, value);
  } else {
    return null;
  }

  if (value.startsWith('@')) {
    value = value.substring(1);
    return value.isEmpty ? null : JoinLink(JoinLinkType.handle, value);
  }
  return value.isEmpty ? null : JoinLink(JoinLinkType.invite, value);
}
