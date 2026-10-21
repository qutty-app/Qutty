import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/screen_share_picker.dart';

Widget _host({
  required Future<List<ScreenShareSource>> Function() loadSources,
  required ValueChanged<ScreenShareSource?> onResult,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await showScreenShareSourcePicker(
                context,
                loadSources: loadSources,
              );
              onResult(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

const _screen = ScreenShareSource(
  id: 'screen:1',
  name: 'Entire Screen',
  isScreen: true,
);
const _window = ScreenShareSource(
  id: 'window:2',
  name: 'Editor',
  isScreen: false,
);

void main() {
  testWidgets('lists screens and windows and returns the tapped source', (
    tester,
  ) async {
    ScreenShareSource? result;
    await tester.pumpWidget(
      _host(
        loadSources: () async => [_screen, _window],
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose what to share'), findsOneWidget);
    expect(find.text('Screens'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('Entire Screen'), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);

    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();

    expect(result?.id, 'window:2');
  });

  testWidgets('shows an empty state with a retry action', (tester) async {
    await tester.pumpWidget(
      _host(loadSources: () async => const [], onResult: (_) {}),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No screens or windows found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows an error state when listing fails', (tester) async {
    await tester.pumpWidget(
      _host(
        loadSources: () async => throw Exception('nope'),
        onResult: (_) {},
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load screens and windows"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
