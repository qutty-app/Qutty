import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/data/emoji_data.dart';
import 'package:qutty/l10n/app_localizations.dart';
import 'package:qutty/screens/chat.dart';
import 'package:qutty/widgets/media_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/composer.dart';
import 'support/fake_api.dart';

const profileJson = {
  'id': 5,
  'display_name': 'Alice',
  'bio': 'hello',
  'avatar_url': '',
  'handles': ['alice'],
  'email': null,
  'account_type': 'user',
  'last_online': '2026-01-01T00:00:00Z',
};

const memberJson = {
  'user_id': 5,
  'display_name': 'Alice',
  'username': 'alice',
  'role': 'member',
  'avatar_url': '',
  'permissions': ['write_messages', 'read_messages'],
};

const chatJson = {
  'id': 7,
  'chat_type': 'group',
  'display_name': 'Group',
  'bio': 'desc',
  'avatar_url': '',
  'handles': ['group'],
  'created_at': '2026-01-01T00:00:00Z',
};

/// The panel is the same inline widget on a phone and on a desktop, so these
/// tests assert that single contract at both sizes.
void main() {
  final overrides = FakeApiHttpOverrides(
    routes: {
      '/v1/account/me': jsonEncode(profileJson),
      '/v1/chats/7': jsonEncode(chatJson),
      '/v1/chats/7/me': jsonEncode(memberJson),
      '/v1/chats/7/messages': jsonEncode([]),
      // The GIF send path: the picker resolves a slug into a stored file, then
      // the screen posts it as an ordinary attachment.
      // Same path as the GET above, different body: the POST returns the
      // message that was created, not the collection.
      'POST /v1/chats/7/messages': jsonEncode({
        'id': 99,
        'chat_id': 7,
        'sender_id': 5,
        'text': '',
        'attachment_key': 'gifs/4f1c0a9b8e7d6c5b.webp',
        'attachment_name': 'funny-cat-1.webp',
        'attachment_url': '/v1/file/gifs/4f1c0a9b8e7d6c5b.webp',
        'attachment_type': 'image/webp',
        'attachment_size': 40960,
        'is_edited': false,
        'created_at': '2026-01-01T00:00:00Z',
      }),
      '/v1/gifs/resolve': jsonEncode({
        'key': 'gifs/4f1c0a9b8e7d6c5b.webp',
        'url': '/v1/file/gifs/4f1c0a9b8e7d6c5b.webp',
        'name': 'funny-cat-1.webp',
        'content_type': 'image/webp',
        'size': 40960,
        'slug': 'funny-cat-1',
      }),
    },
  );

  const accountId = 'https://qutty.app\u0000token-abc';

  Finder emojiButton() => find.byTooltip('Choose emojis, gifs and stickers');
  Rect rectOf(WidgetTester tester, Finder finder) =>
      tester.getRect(finder.first);

  /// The composer keeps a blinking text cursor alive, so `pumpAndSettle` would
  /// spin forever. Advance a fixed couple of frames instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openChat(WidgetTester tester, {required Size size}) async {
    // Every call the screen makes has to be faked, so the whole mount-and-load
    // runs inside the override zone rather than just AppManager.restore.
    await HttpOverrides.runZoned(() async {
      // Order matters: pin the ratio first, then the size, so `size` is read as
      // logical pixels rather than being scaled by the default ratio of 3.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      // Sign in first so the screen's requests carry the saved token and the
      // header shows the restored profile. `runAsync` is required: restore does
      // real async I/O, which never completes inside the fake-async zone that
      // `testWidgets` runs its body in.
      await tester.runAsync(() => AppManager.instance.restore());

      // Warm the emoji asset before the tree exists: the panel reads it through
      // rootBundle, which is real async I/O the fake-async test zone cannot
      // complete, and `runAsync` deadlocks once the loading spinner is animating.
      await tester.runAsync(EmojiData.load);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatScreen(chatId: 7),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }, createHttpClient: (_) => overrides.createHttpClient(null));
  }

  tearDown(() => HttpOverrides.global = null);

  setUp(() {
    // The zone inside openChat only covers the mount-and-load. Anything the
    // screen requests later -- the GIF tab's own calls, for one -- would
    // otherwise fall through to the default test HttpClient, which answers 400
    // and makes the screen look broken rather than unfaked.
    HttpOverrides.global = overrides;

    SharedPreferences.setMockInitialValues({
      'qutty.accounts': jsonEncode([
        {
          'id': accountId,
          'label': 'alice',
          'baseUrl': 'https://qutty.app',
          'token': 'token-abc',
        },
      ]),
      'qutty.active_account': accountId,
    });
  });

  group('the media picker behaves the same on a phone and a desktop', () {
    for (final size in const [
      Size(400, 800), // phone
      Size(1200, 900), // desktop
    ]) {
      final label = size.width < 720 ? 'phone' : 'desktop';

      testWidgets('opens below the text field on a $label', (tester) async {
        await openChat(tester, size: size);

        expect(find.byType(MediaPickerPanel), findsNothing);
        expect(emojiButton(), findsOneWidget);

        await tester.tap(emojiButton());
        await settle(tester);

        expect(find.byType(MediaPickerPanel), findsOneWidget);
        final panel = rectOf(tester, find.byType(MediaPickerPanel));
        final field = rectOf(tester, composerField());
        expect(
          panel.top,
          greaterThanOrEqualTo(field.bottom),
          reason: 'the panel must sit under the composer, not over it',
        );
        expect(panel.bottom, lessThanOrEqualTo(size.height));
      });

      testWidgets('taking the composer back closes it on a $label', (
        tester,
      ) async {
        await openChat(tester, size: size);

        await tester.tap(emojiButton());
        await settle(tester);
        expect(find.byType(MediaPickerPanel), findsOneWidget);

        await tester.tap(composerField());
        await settle(tester);

        expect(find.byType(MediaPickerPanel), findsNothing);
      });

      testWidgets('tapping the button twice closes it on a $label', (
        tester,
      ) async {
        await openChat(tester, size: size);

        await tester.tap(emojiButton());
        await settle(tester);
        await tester.tap(emojiButton());
        await settle(tester);

        expect(find.byType(MediaPickerPanel), findsNothing);
      });
    }
  });

  testWidgets('selecting an emoji inserts it after the existing text', (
    tester,
  ) async {
    await openChat(tester, size: const Size(400, 800));

    await enterComposerText(tester, 'hi ');
    await settle(tester);

    await tester.tap(emojiButton());
    await settle(tester);
    // Scoped to the grid: the first emoji of the default subgroup is also that
    // subgroup's chip in the strip above, so a plain text finder matches twice.
    await tester.tap(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('\u{1F600}'),
      ),
    );
    await settle(tester);

    final text = composerText(tester);
    expect(text.startsWith('hi '), isTrue, reason: 'existing text is kept');
    expect(text.length, greaterThan(3), reason: 'an emoji was inserted');
  });

  testWidgets('picking a gif resolves it and sends it as an attachment', (
    tester,
  ) async {
    await openChat(tester, size: const Size(400, 800));

    // Open the picker and switch to the GIF tab.
    await tester.tap(emojiButton());
    await settle(tester);
    await tester.tap(find.text('GIF'));
    await settle(tester);

    final cell = find
        .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
        .first;
    await tester.tap(cell);
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 300));

    // The slug was resolved into a stored file first, so the message that goes
    // out is an ordinary attachment rather than a third-party URL.
    expect(
      overrides.requests.any(
        (r) => r.method == 'POST' && r.path == '/v1/gifs/resolve',
      ),
      isTrue,
      reason: 'the gif should be downloaded into our storage before sending',
    );
    expect(
      overrides.requests.any(
        (r) => r.method == 'POST' && r.path == '/v1/chats/7/messages',
      ),
      isTrue,
      reason: 'the resolved gif should be sent as a message attachment',
    );
  });
}
