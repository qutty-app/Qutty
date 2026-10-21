import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/ugc_link.dart';

void main() {
  test('the share link carries the pack id', () {
    expect(ugcShareLink(12), 'https://qutty.app/sticker/12');
  });

  group('parseUgcShareLink', () {
    test('reads the in-app form', () {
      expect(parseUgcShareLink('qutty://sticker/12'), 12);
    });

    test('reads the web form with or without a scheme', () {
      expect(parseUgcShareLink('https://qutty.app/sticker/12'), 12);
      expect(parseUgcShareLink('qutty.app/sticker/12'), 12);
    });

    test('round-trips its own link', () {
      expect(parseUgcShareLink(ugcShareLink(12)), 12);
    });

    test('ignores a trailing slash or query string', () {
      expect(parseUgcShareLink('https://qutty.app/sticker/12/'), 12);
      expect(parseUgcShareLink('https://qutty.app/sticker/12?from=chat'), 12);
    });

    test('is null for anything else', () {
      expect(parseUgcShareLink('https://qutty.app/invite/abc123'), isNull);
      expect(parseUgcShareLink('https://example.com/sticker/12'), isNull);
      expect(parseUgcShareLink('qutty.app/sticker/abc'), isNull);
      expect(parseUgcShareLink(''), isNull);
    });
  });
}
