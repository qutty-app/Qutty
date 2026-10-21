import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/join_link.dart';

void main() {
  test('parses supported handle and invite formats', () {
    expect(parseJoinLink('@public')?.value, 'public');
    expect(parseJoinLink('qutty://join/@public')?.type, JoinLinkType.handle);
    expect(parseJoinLink('qutty://join/abc123')?.value, 'abc123');
    expect(parseJoinLink('https://qutty.app/invite/abc123')?.value, 'abc123');
    expect(
      parseJoinLink('qutty.app/invite/@public')?.type,
      JoinLinkType.handle,
    );
    expect(parseJoinLink('invite.qutty/abc123')?.value, 'abc123');
  });
}
