import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/data/emoji_data.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/media_picker.dart';

import 'support/fake_api.dart';

/// Advances a few frames.
///
/// Not `pumpAndSettle`: the panel shows a spinner while it loads, and a spinner
/// never stops animating, so settling would never finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The panel is pure UI over its inputs, so it can be pumped on its own. The
/// placement rules that depend on the composer live in `ChatScreen` and are
/// covered in `media_picker_placement_test.dart`.
Future<void> pumpPanel(
  WidgetTester tester, {
  required MediaPickerTab tab,
  required ValueChanged<MediaPickerTab> onTabChanged,
  required ValueChanged<String> onEmojiSelected,
  VoidCallback? onClose,
  ValueChanged<GifInfo>? onGifSelected,
  ValueChanged<UgcItem>? onUgcSelected,
  VoidCallback? onOpenUgcPortal,
  ApiService? api,
}) async {
  // Warm the asset cache before the widget tree exists. The panel reads its data
  // through `rootBundle`, which is real async I/O, and `testWidgets` runs the
  // body in a fake-async zone that never completes it. `runAsync` is the escape
  // hatch, but it deadlocks if an animation is on screen, so it has to happen
  // before the loading spinner is built.
  await tester.runAsync(EmojiData.load);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 320,
          child: MediaPickerPanel(
            tab: tab,
            onTabChanged: onTabChanged,
            onEmojiSelected: onEmojiSelected,
            onGifSelected: onGifSelected ?? (_) {},
            onUgcSelected: onUgcSelected ?? (_) {},
            onOpenUgcPortal: onOpenUgcPortal ?? () {},
            api: api ?? ApiService(),
            onClose: onClose ?? () {},
          ),
        ),
      ),
    ),
  );
  await settle(tester);
}

/// Finds an emoji in the grid specifically.
///
/// Scoped because the tone strip shows glyphs of its own outside the grid, and
/// the untoned option there repeats the base glyph.
Finder gridEmoji(String glyph) =>
    find.descendant(of: find.byType(GridView), matching: find.text(glyph));

/// Opens a category by its accessible name.
///
/// One level only: a category shows all of its emoji, so there is no subgroup
/// to drill into first.
Future<void> open(WidgetTester tester, String group) async {
  await tester.tap(find.byTooltip(group));
  await settle(tester);
}

void main() {
  testWidgets('offers sticker, emoji and gif tabs', (tester) async {
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: (_) {},
    );

    expect(find.text('Sticker'), findsOneWidget);
    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
  });

  testWidgets('puts the categories on top and shows a whole category at once', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: (_) {},
    );

    // Every category is reachable, and the strip runs across the top rather
    // than down the side.
    for (final name in [
      'Smileys & Emotion',
      'People & Body',
      'Animals & Nature',
      'Food & Drink',
      'Travel & Places',
      'Activities',
      'Objects',
      'Symbols',
      'Flags',
    ]) {
      expect(find.byTooltip(name), findsOneWidget, reason: name);
    }
    final strip = find.ancestor(
      of: find.byTooltip('Flags'),
      matching: find.byType(Scrollable),
    );
    final box = tester.getRect(strip.first);
    expect(
      box.width,
      greaterThan(box.height),
      reason: 'the strip is horizontal',
    );
    final panel = tester.getRect(find.byType(MediaPickerPanel));
    expect(
      box.top,
      lessThan(panel.center.dy),
      reason: 'the strip sits above the grid, not beside it',
    );

    // No second level: a category is one grid, with no subgroup chips.
    await open(tester, 'Animals & Nature');
    expect(find.byType(GridView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching category swaps the emoji on show', (tester) async {
    final picked = <String>[];
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: picked.add,
    );

    // A toneable emoji that only exists in People & Body.
    expect(gridEmoji('\u{1F44B}'), findsNothing);
    await open(tester, 'People & Body');
    expect(gridEmoji('\u{1F44B}'), findsWidgets);
    await open(tester, 'Flags');
    expect(gridEmoji('\u{1F44B}'), findsNothing);
  });

  testWidgets('selecting a tab reports the new tab', (tester) async {
    MediaPickerTab? seen;
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (tab) => seen = tab,
      onEmojiSelected: (_) {},
    );

    await tester.tap(find.text('GIF'));
    expect(seen, MediaPickerTab.gif);
  });

  testWidgets('the emoji tab renders a tappable grid', (tester) async {
    final picked = <String>[];
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: picked.add,
    );

    // First cell of the default group (Smileys & Emotion) and its first
    // subgroup (face-smiling).
    expect(gridEmoji('😀'), findsOneWidget);
    await tester.tap(gridEmoji('😀'));
    expect(picked, ['😀']);
  });

  testWidgets('the group rail switches to another group', (tester) async {
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: (_) {},
    );

    expect(gridEmoji('😀'), findsOneWidget);
    await tester.tap(find.byTooltip('Animals & Nature'));
    await settle(tester);
    expect(gridEmoji('🐵'), findsOneWidget);
    expect(gridEmoji('😀'), findsNothing);
  });

  testWidgets('every group rail button is labelled for screen readers', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: (_) {},
    );

    // The rail is icon-only, so the tooltips are the accessible names. These are
    // Unicode's own groups, not a scheme invented for the picker.
    //
    // The rail scrolls: nine buttons at a 48pt touch target do not fit the panel
    // height, so each is scrolled into view rather than assumed to be built.
    // The rail is the first ListView in the tree; scrollUntilVisible needs the
    // Scrollable inside it, not the buttons.
    final rail = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    );
    for (final name in [
      'Smileys & Emotion',
      'People & Body',
      'Animals & Nature',
      'Food & Drink',
      'Travel & Places',
      'Activities',
      'Objects',
      'Symbols',
      'Flags',
    ]) {
      final button = find.byTooltip(name);
      await tester.scrollUntilVisible(button, 60, scrollable: rail);
      expect(button, findsOneWidget, reason: name);
    }
  });

  group('skin tone strip', () {
    testWidgets('long press offers the untoned emoji and all five tones', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        tab: MediaPickerTab.emoji,
        onTabChanged: (_) {},
        onEmojiSelected: (_) {},
      );
      await open(tester, 'People & Body');

      await tester.longPress(gridEmoji('👋'));
      await settle(tester);

      // The strip offers the untoned emoji plus one option per Fitzpatrick tone.
      // Each is a single glyph that appears nowhere else, so the tone options are
      // matched directly; the untoned one shares its glyph with the grid cell
      // behind the strip, so it is matched by its tooltip instead.
      expect(gridEmoji('👋'), findsOneWidget, reason: 'grid cell still there');
      expect(find.byTooltip('Default'), findsOneWidget);
      for (final tone in ['🏻', '🏼', '🏽', '🏾', '🏿']) {
        expect(find.text('👋$tone'), findsOneWidget, reason: tone);
      }
      // Light to dark, matching the Unicode modifier order.
      expect(find.byTooltip('Default'), findsOneWidget);
      for (final name in [
        'Light',
        'Medium-light',
        'Medium',
        'Medium-dark',
        'Dark',
      ]) {
        expect(find.byTooltip(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('picking a tone inserts it', (tester) async {
      final picked = <String>[];
      await pumpPanel(
        tester,
        tab: MediaPickerTab.emoji,
        onTabChanged: (_) {},
        onEmojiSelected: picked.add,
      );
      await open(tester, 'People & Body');

      await tester.longPress(gridEmoji('👋'));
      await settle(tester);
      await tester.tap(find.byTooltip('Dark'));
      await settle(tester);

      expect(picked, ['👋🏿']);
    });

    testWidgets('picking the untoned option inserts the plain emoji', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpPanel(
        tester,
        tab: MediaPickerTab.emoji,
        onTabChanged: (_) {},
        onEmojiSelected: picked.add,
      );
      await open(tester, 'People & Body');

      await tester.longPress(gridEmoji('👋'));
      await settle(tester);
      // The strip's first option is the untoned emoji, matched by its tooltip
      // because the same glyph is still in the grid behind the strip.
      await tester.tap(find.byTooltip('Default'));
      await settle(tester);

      expect(picked, ['👋']);
    });

    testWidgets('an emoji with no tone opens no strip', (tester) async {
      final picked = <String>[];
      await pumpPanel(
        tester,
        tab: MediaPickerTab.emoji,
        onTabChanged: (_) {},
        onEmojiSelected: picked.add,
      );

      // A plain face takes no tone, so a long press falls back to inserting it.
      await tester.longPress(gridEmoji('😀'));
      await settle(tester);

      expect(picked, ['😀']);
      expect(find.text('😀🏻'), findsNothing);
      expect(find.byTooltip('Default'), findsNothing);
    });

    testWidgets('tapping the barrier dismisses the strip without inserting', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpPanel(
        tester,
        tab: MediaPickerTab.emoji,
        onTabChanged: (_) {},
        onEmojiSelected: picked.add,
      );
      await open(tester, 'People & Body');

      await tester.longPress(gridEmoji('👋'));
      await settle(tester);
      expect(find.text('👋🏿'), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.byType(MediaPickerPanel)));
      await settle(tester);

      expect(find.text('👋🏿'), findsNothing);
      expect(picked, isEmpty);
    });
  });

  group('sticker tab', () {
    /// A picker whose UGC requests land on [overrides].
    ///
    /// The endpoints are behind auth, so the token is set for the same reason
    /// the GIF tests set it: the fake can then tell a real call from one the
    /// server would reject.
    Future<ApiService> pumpStickerTab(
      WidgetTester tester, {
      required FakeApiHttpOverrides overrides,
      ValueChanged<UgcItem>? onSelected,
      VoidCallback? onManage,
    }) async {
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      final api = ApiService(baseUrl: 'https://qutty.test')
        ..token = 'token-abc';
      await pumpPanel(
        tester,
        tab: MediaPickerTab.sticker,
        onTabChanged: (_) {},
        onEmojiSelected: (_) {},
        onUgcSelected: onSelected ?? (_) {},
        onOpenUgcPortal: onManage ?? () {},
        api: api,
      );
      return api;
    }

    /// An empty account: nothing saved yet, so the picker has two routes to
    /// read and nothing in either.
    FakeApiHttpOverrides emptyAccount() => FakeApiHttpOverrides(
      routes: {
        '/v1/ugc/favorites/packs': '[]',
        '/v1/ugc/favorites/items': '[]',
      },
    );

    /// One saved pack, shaped like the backend's favorite-packs listing.
    Map<String, dynamic> pack(int id, String name) => {
      'id': id,
      'owner_id': 5,
      'display_name': name,
      'description': '',
      'flags': '',
      'item_count': 1,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    /// One sticker, so a grid cell exists to tap.
    Map<String, dynamic> sticker(int id, {int packId = 1}) => {
      'id': id,
      'owner_id': 5,
      'pack_id': packId,
      'name': 'Wave $id',
      'url': '/v1/file/ugc/$id.png',
      'key': 'ugc/$id.png',
      'width': 128,
      'height': 128,
      'file_size': 1024,
      'content_type': 'image/png',
    };

    testWidgets('an account with nothing saved is told to visit the portal', (
      tester,
    ) async {
      await pumpStickerTab(tester, overrides: emptyAccount());

      // Only saved packs are on offer now, so the empty state says so rather
      // than pointing at pack creation alone.
      expect(find.textContaining('No saved packs yet'), findsOneWidget);
      expect(find.byTooltip('Manage in Developer portal'), findsWidgets);
      // No errors surfaced from the empty read.
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('the gear opens the developer portal', (tester) async {
      var opened = 0;
      await pumpStickerTab(
        tester,
        overrides: emptyAccount(),
        onManage: () => opened++,
      );

      await tester.tap(find.byTooltip('Manage in Developer portal').first);
      expect(opened, 1);
    });

    testWidgets('only the saved packs offer their stickers', (tester) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/favorites/packs': jsonEncode([pack(1, 'Cats')]),
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
        },
      );
      await pumpStickerTab(tester, overrides: overrides);

      // The saved pack is a chip, its sticker is in the grid, and nothing
      // else was ever fetched: the picker does not ask for owned packs at all.
      expect(find.text('Cats'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(
        tester
            .widgetList(
              find.descendant(
                of: find.byType(GridView),
                matching: find.byType(InkWell),
              ),
            )
            .length,
        1,
      );
      expect(
        overrides.requests
            .where((r) => r.path == '/v1/ugc/packs' || r.path == '/v1/ugc/items')
            .length,
        0,
      );
    });

    testWidgets('tapping a sticker opens the popup, which inserts it', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/favorites/packs': jsonEncode([pack(1, 'Cats')]),
          '/v1/ugc/favorites/items': '[]',
          '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
        },
      );
      UgcItem? picked;
      await pumpStickerTab(
        tester,
        overrides: overrides,
        onSelected: (item) => picked = item,
      );

      await tester.tap(
        find
            .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
            .first,
      );
      await settle(tester);

      // The popup names the pack and offers the sticker's two outcomes.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cats'),
        ),
        findsOneWidget,
      );
      expect(find.text('Wave 7'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Insert'));
      await settle(tester);

      expect(picked?.id, 7);
      expect(picked?.packId, 1);
      // Inserting does not touch the saved state of the pack.
      expect(
        overrides.requests.any(
          (r) => r.method != 'GET' && r.path.contains('/favorites/packs'),
        ),
        isFalse,
      );
    });

    testWidgets('the popup can unsave the sticker pack', (tester) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/favorites/packs': jsonEncode([pack(1, 'Cats')]),
          '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
          'DELETE /v1/ugc/favorites/packs/1': '{}',
        },
      );
      await pumpStickerTab(tester, overrides: overrides);

      await tester.tap(
        find
            .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
            .first,
      );
      await settle(tester);

      // The pack is saved, so the heart starts filled and offers removal.
      final heart = find.byTooltip('Remove saved pack');
      expect(heart, findsOneWidget);
      await tester.tap(heart);
      await settle(tester);

      expect(
        overrides.requests.any(
          (r) => r.method == 'DELETE' && r.path == '/v1/ugc/favorites/packs/1',
        ),
        isTrue,
      );
      expect(find.text('Removed from favorites'), findsOneWidget);
      // The pack left the collection, so its stickers leave with it.
      expect(find.textContaining('No saved packs yet'), findsOneWidget);
    });

    testWidgets('the Favorites chip shows the item shortlist', (tester) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/favorites/packs': jsonEncode([pack(1, 'Cats')]),
          '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
          // The shortlist holds an item from a pack the account never saved,
          // which is exactly what the chip is for.
          '/v1/ugc/favorites/items': jsonEncode([sticker(9, packId: 2)]),
        },
      );
      await pumpStickerTab(tester, overrides: overrides);

      // All shows the saved pack's sticker, not the shortlisted one.
      expect(find.byTooltip('Wave 7'), findsOneWidget);
      expect(find.byTooltip('Wave 9'), findsNothing);

      await tester.tap(find.text('Favorites'));
      await settle(tester);

      expect(find.byTooltip('Wave 9'), findsOneWidget);
      expect(find.byTooltip('Wave 7'), findsNothing);
    });

    testWidgets('a long press puts a sticker on the shortlist', (tester) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/ugc/favorites/packs': jsonEncode([pack(1, 'Cats')]),
          '/v1/ugc/packs/1/items': jsonEncode([sticker(7)]),
          '/v1/ugc/favorites/items': '[]',
          'POST /v1/ugc/favorites/items': '{}',
        },
      );
      await pumpStickerTab(tester, overrides: overrides);

      await tester.longPress(find.byTooltip('Wave 7'));
      await settle(tester);

      final post = overrides.requests.firstWhere(
        (r) => r.method == 'POST' && r.path == '/v1/ugc/favorites/items',
      );
      expect(jsonDecode(post.body)['item_id'], 7);
      expect(find.text('Saved to favorites'), findsOneWidget);
    });

    testWidgets('a failed load explains itself and offers a retry', (
      tester,
    ) async {
      await pumpStickerTab(
        tester,
        overrides: FakeApiHttpOverrides(failAll: true),
      );

      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    });
  });

  /// A GIF with no animating rendition anywhere, so the picker has to fall back
  /// to the still JPEG.
  Map<String, dynamic> stillOnlyGif() => {
    'id': 3,
    'slug': 'still-only',
    'title': 'Still Only',
    'preview': 'https://static.klipy.com/still-only.jpg',
    'width': 220,
    'height': 220,
    'tags': <String>[],
    'files': <String, dynamic>{},
  };

  group('gif tab', () {
    /// A GIF picker whose requests land on [overrides].
    ///
    /// The token is set because the GIF endpoints are behind auth like every
    /// other route, so the fake can tell a real call from an unauthenticated
    /// one that the server would reject.
    Future<ApiService> pumpGifTab(
      WidgetTester tester, {
      required FakeApiHttpOverrides overrides,
      ValueChanged<GifInfo>? onSelected,
    }) async {
      // Installing the transport is synchronous, so it needs no runAsync here.
      // Wrapping the call in one would be reentrant with the runAsync that
      // pumpPanel already does to warm the emoji asset.
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = null);

      final api = ApiService(baseUrl: 'https://qutty.test')
        ..token = 'token-abc';
      await pumpPanel(
        tester,
        tab: MediaPickerTab.gif,
        onTabChanged: (_) {},
        onEmojiSelected: (_) {},
        onGifSelected: onSelected ?? (_) {},
        api: api,
      );
      return api;
    }

    testWidgets('opens on the saved GIFs with only a search field', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);

      expect(find.byType(TextField), findsOneWidget);
      // No category chips: favourites is simply the empty search, and KLIPY's
      // own categories are reachable by typing the term.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(
        overrides.requests.map((r) => r.path),
        isNot(contains('/v1/gifs/categories')),
      );
      // The default view is the saved list, not a search for "".
      expect(
        overrides.requests.where((r) => r.path == '/v1/gifs/favorites'),
        isNotEmpty,
      );
      expect(
        overrides.requests.map((r) => r.path),
        isNot(contains('/v1/gifs/search')),
      );
    });

    testWidgets('shows an animating thumbnail, not the still preview', (
      tester,
    ) async {
      // The grid used to render `preview`, which is a JPEG, so every result
      // looked like a frozen GIF. The smallest animating rendition is the
      // right one for a grid.
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);

      final image = tester.widget<Image>(
        find
            .descendant(of: find.byType(GridView), matching: find.byType(Image))
            .first,
      );
      final url = (image.image as NetworkImage).url;
      expect(url, 'https://static.klipy.com/funny-cat-1-xs.webp');
      expect(url, isNot(contains('.jpg')));
    });

    testWidgets('animates a favourited gif served without any files', (
      tester,
    ) async {
      // The favourites list is built from the server's own table, so it carries
      // no `files` to choose from. When it only had the still JPEG preview,
      // every saved GIF looked frozen while searched ones animated.
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);

      final image = tester.widget<Image>(
        find
            .descendant(of: find.byType(GridView), matching: find.byType(Image))
            .first,
      );
      final url = (image.image as NetworkImage).url;
      expect(url, 'https://static.klipy.com/funny-cat-1-xs.webp');
      expect(url, isNot(contains('.jpg')));
    });

    testWidgets('falls back to the still preview when nothing animates', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/gifs/favorites': jsonEncode({
            'items': [stillOnlyGif()],
            'page': 1,
            'has_next': false,
          }),
        },
      );
      await pumpGifTab(tester, overrides: overrides);

      final image = tester.widget<Image>(
        find
            .descendant(of: find.byType(GridView), matching: find.byType(Image))
            .first,
      );
      expect(
        (image.image as NetworkImage).url,
        'https://static.klipy.com/still-only.jpg',
      );
    });

    testWidgets('hands the tapped gif back from the default view', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides();
      GifInfo? picked;
      await pumpGifTab(
        tester,
        overrides: overrides,
        onSelected: (gif) => picked = gif,
      );

      // Scoped to the grid, since the search field is built from other widgets
      // that would not resolve to a cell anyway.
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await settle(tester);
      expect(picked?.slug, isNotEmpty);
    });

    testWidgets('typing searches and clearing the box returns to favourites', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);

      await tester.enterText(find.byType(TextField), 'cat');
      // settle alone advances 150ms, which is short of the 350ms debounce.
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      final searches = overrides.requests
          .where((r) => r.path == '/v1/gifs/search')
          .toList();
      expect(searches.last.query['q'], 'cat');

      // The clear button is the only way back now that the chip is gone.
      await tester.tap(find.byTooltip('Clear search'));
      await settle(tester);
      final paths = overrides.requests.map((r) => r.path).toList();
      expect(paths.last, '/v1/gifs/favorites');
    });

    testWidgets('marks only the results the user has already saved', (
      tester,
    ) async {
      // The saved marker has to come from the server, not from "this is a
      // search result", or every result would claim to be saved.
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/gifs/favorites': jsonEncode({
            'items': [
              {
                'id': 0,
                'slug': 'funny-cat-1',
                'title': 'Chatty Cat',
                'preview': 'https://static.klipy.com/funny-cat-1.jpg',
                'width': 220,
                'height': 220,
                'tags': <String>[],
                'files': <String, dynamic>{},
              },
            ],
            'page': 1,
            'has_next': false,
          }),
        },
      );
      await pumpGifTab(tester, overrides: overrides);

      // Two GIFs come back; only one of them is saved.
      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows an outlined heart until the gif is liked', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/gifs/favorites': jsonEncode({
            'items': <dynamic>[],
            'page': 1,
            'has_next': false,
          }),
        },
      );
      await pumpGifTab(tester, overrides: overrides);

      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);

      // Two unliked results: both offer an outlined heart, and neither is drawn
      // as already saved.
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byTooltip('Save to favorites'), findsNWidgets(2));
      expect(find.byTooltip('Remove from favorites'), findsNothing);

      // And tapping the outlined heart saves it.
      await tester.tap(find.byTooltip('Save to favorites').first);
      await settle(tester);
      expect(
        overrides.requests.any(
          (r) => r.method == 'POST' && r.path == '/v1/gifs/favorites',
        ),
        isTrue,
      );
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('long press saves a favourite on the server', (tester) async {
      // The default fixture already has a saved GIF, and the search returns it,
      // so the unsaved precondition is stated here rather than inherited.
      final overrides = FakeApiHttpOverrides(
        routes: {
          '/v1/gifs/favorites': jsonEncode({
            'items': <dynamic>[],
            'page': 1,
            'has_next': false,
          }),
        },
      );
      await pumpGifTab(tester, overrides: overrides);

      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.longPress(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await settle(tester);

      final post = overrides.requests.firstWhere(
        (r) => r.method == 'POST' && r.path == '/v1/gifs/favorites',
      );
      expect(post, isNotNull);
      // And the marker appears without reloading the tab.
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('searching is debounced rather than per keystroke', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);
      final before = overrides.requests
          .where((r) => r.path == '/v1/gifs/search')
          .length;

      await tester.enterText(find.byType(TextField), 'cat');
      // settle only advances 150ms, which is short of the 350ms debounce, so
      // the timer has to be pushed past it explicitly.
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);

      final after = overrides.requests
          .where((r) => r.path == '/v1/gifs/search')
          .length;
      // One extra request for three characters, not three.
      expect(after - before, 1);
    });

    testWidgets('a failed load explains itself and offers a retry', (
      tester,
    ) async {
      final overrides = FakeApiHttpOverrides(failAll: true);
      await pumpGifTab(tester, overrides: overrides);

      expect(find.textContaining("Couldn't load GIFs"), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    });

    testWidgets('the heart does not cover the middle of a cell', (
      tester,
    ) async {
      // IconButton's Material 3 box is 40x40 even when its InkWell is 20x20. On
      // a ~75pt cell a 40x40 corner box covers the centre, so tapping a GIF to
      // send it would instead like it. This pins the geometry that stops that,
      // and would catch shrinkWrap being dropped.
      // Searched rather than the default view, because everything in the saved
      // list is liked and so has no outlined heart to measure.
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);
      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);

      final cell = find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .first;
      final centre = tester.getCenter(cell);
      final heart = find.byTooltip('Save to favorites').first;
      expect(
        tester.getRect(heart).contains(centre),
        isFalse,
        reason: 'the like heart must not swallow the send tap',
      );
    });

    testWidgets('carries the required klipy attribution', (tester) async {
      // KLIPY's developer terms make displaying their branding a condition of
      // using the API, so this string is a requirement, not decoration.
      final overrides = FakeApiHttpOverrides();
      await pumpGifTab(tester, overrides: overrides);
      expect(find.text('GIFs by Klipy'), findsOneWidget);
    });
  });

  testWidgets('close is wired to a real callback', (tester) async {
    var closed = 0;
    await pumpPanel(
      tester,
      tab: MediaPickerTab.emoji,
      onTabChanged: (_) {},
      onEmojiSelected: (_) {},
      onClose: () => closed++,
    );

    await tester.tap(find.byTooltip('Close'));
    expect(closed, 1);
  });
}
