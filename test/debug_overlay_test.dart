import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/widgets/debug_overlay.dart';

void main() {
  testWidgets('holding the background reveals debug info in the corner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DebugLongPressOverlay(
          child: Scaffold(
            body: Container(color: const Color(0xffffffff)),
          ),
        ),
      ),
    );

    expect(find.text('call debug'), findsNothing);

    await tester.longPress(find.byType(Scaffold));
    await tester.pump();
    expect(find.text('call debug'), findsOneWidget);

    // A second hold hides it again.
    await tester.longPress(find.byType(Scaffold));
    await tester.pump();
    expect(find.text('call debug'), findsNothing);
  });
}
