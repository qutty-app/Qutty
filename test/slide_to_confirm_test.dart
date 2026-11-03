import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/debug.dart';
import 'package:qutty/widgets/chat_exit_actions.dart';

void main() {
  testWidgets('a slider confirms only once its thumb reaches the end', (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'Slide to confirm',
                onConfirmed: () => confirmations++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Slide to confirm'), findsOneWidget);
    final rect = tester.getRect(find.byType(SlideToConfirm));

    // Halfway is not enough: releasing there returns the thumb to the start.
    await tester.dragFrom(
      Offset(rect.left + 28, rect.center.dy),
      Offset(rect.width / 2, 0),
    );
    await tester.pumpAndSettle();
    expect(confirmations, 0);

    // Almost at the end is still not the end.
    await tester.dragFrom(
      Offset(rect.left + 28, rect.center.dy),
      Offset(rect.width - 70, 0),
    );
    await tester.pumpAndSettle();
    expect(confirmations, 0);

    // Only the full distance confirms.
    await tester.dragFrom(
      Offset(rect.left + 28, rect.center.dy),
      Offset(rect.width - 40, 0),
    );
    await tester.pumpAndSettle();
    expect(confirmations, 1);
  });

  testWidgets('pressing the end of the track does not confirm', (tester) async {
    var confirmations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SlideToConfirm(
                label: 'Slide to confirm',
                onConfirmed: () => confirmations++,
              ),
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(SlideToConfirm));
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    await tester.pumpAndSettle();
    expect(confirmations, 0);

    // Even dragging from the end is not a slide: the thumb is still at the
    // start, so the press lands on the track, not on the thumb.
    await tester.dragFrom(
      Offset(rect.right - 10, rect.center.dy),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    expect(confirmations, 0);
  });

  testWidgets('dialog actions stay on one row despite full-width button theme', (
    tester,
  ) async {
    final chat = ChatInfo(
      id: 7,
      chatType: 'chat',
      displayName: 'Coding Club',
      bio: '',
      handles: ['coding'],
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Mirrors the app theme: filled buttons otherwise request an infinite
        // minimum width, which is what used to stack dialog actions.
        theme: ThemeData(
          useMaterial3: true,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ChatExitActions.deleteChat(context, chat),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final cancel = tester.getRect(find.text('Cancel'));
    final delete = tester.getRect(find.text('Delete'));
    expect(
      cancel.center.dy,
      closeTo(delete.center.dy, 1),
      reason: 'Cancel and Delete must be on the same row',
    );
    expect(cancel.right, lessThan(delete.left));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Quttycaka offers the test slider', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DebugSettings(),
      ),
    );
    await tester.pump();

    final tile = find.text('Test slider');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Drag the slider to the end to confirm.'), findsOneWidget);
    expect(find.byType(SlideToConfirm), findsOneWidget);
  });
}
