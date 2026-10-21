import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the app put on the clipboard, filled in as it happens.
///
/// The real clipboard is a platform channel, so the test has to stand in for
/// it; [text] is the last thing copied, or null if nothing was.
class ClipboardProbe {
  String? text;
}

/// Stands in for the platform clipboard for the rest of the test.
///
/// Only `Clipboard.setData` is read; every other platform call is answered
/// with null, which is what the app expects from the ones it makes anyway.
ClipboardProbe captureClipboard(WidgetTester tester) {
  final probe = ClipboardProbe();
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      probe.text = (call.arguments as Map)['text'] as String?;
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return probe;
}
