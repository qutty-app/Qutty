import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/widgets/settings_ui.dart';

void main() {
  test('writes a size the way a person would say it', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(-1), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1024), '1 KB');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(64 * 1024 * 1024), '64 MB');
    expect(formatBytes(256 * 1024 * 1024), '256 MB');
    expect(formatBytes(1024 * 1024 * 1024), '1 GB');
  });
}
