import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/data/emoji_data.dart';

/// The picker's data set is generated, so these tests pin the properties the UI
/// relies on. A silent regression here would show up as missing emoji rather
/// than as a failing test, which is the worst way to find out.
void main() {
  late EmojiData data;

  setUpAll(() async {
    // Read the file directly rather than through the asset bundle, so this test
    // does not need a widget binding and can assert on the raw JSON too.
    data = EmojiData.fromJsonString(
      File('assets/emoji.json').readAsStringSync(),
    );
  });

  test('covers the whole Unicode emoji set', () {
    // 3,963 fully-qualified emoji in Unicode Emoji 18.0. Stored plus generated
    // must equal the count in the source file, or something is unreachable.
    expect(data.length, 3963);
  });

  test('a flattened category has no duplicate emoji', () {
    // The picker shows a whole category as one list, so a glyph listed under two
    // subgroups would render as two identical cells with nothing to tell them
    // apart.
    for (final group in data.groups) {
      final glyphs = group.allEmoji;
      expect(
        glyphs.toSet().length,
        glyphs.length,
        reason: '${group.id} repeats an emoji when its subgroups are flattened',
      );
    }
  });

  test('a flattened category keeps every emoji its subgroups hold', () {
    // The other half of the no-duplicates guarantee: deduping must not quietly
    // drop a distinct emoji on the way to the flat list.
    for (final group in data.groups) {
      final fromSubgroups = <String>{
        for (final subgroup in group.subgroups) ...subgroup.emoji,
      };
      expect(
        group.allEmoji.toSet(),
        fromSubgroups,
        reason: '${group.id} lost or gained an emoji when flattened',
      );
    }
  });

  test('a flattened category is in subgroup order', () {
    // The order is Unicode's, so the grid reads predictably rather than in
    // whatever order a Set happened to produce.
    final group = data.groups.firstWhere((g) => g.id == 'smileys-emotion');
    final expected = <String>[];
    final seen = <String>{};
    for (final subgroup in group.subgroups) {
      for (final glyph in subgroup.emoji) {
        if (seen.add(glyph)) expected.add(glyph);
      }
    }
    expect(group.allEmoji, expected);
  });

  test('exposes the nine browsable Unicode groups', () {
    expect(data.groups.map((group) => group.id), [
      'smileys-emotion',
      'people-body',
      'animals-nature',
      'food-drink',
      'travel-places',
      'activities',
      'objects',
      'symbols',
      'flags',
    ]);
    expect(data.groups, hasLength(9));
  });

  test('every subgroup has emoji and every group has subgroups', () {
    for (final group in data.groups) {
      expect(group.subgroups, isNotEmpty, reason: group.id);
      for (final subgroup in group.subgroups) {
        expect(
          subgroup.emoji,
          isNotEmpty,
          reason: '${group.id}/${subgroup.id}',
        );
      }
    }
  });

  test('no emoji is listed twice', () {
    final seen = <String>[];
    for (final group in data.groups) {
      for (final subgroup in group.subgroups) {
        seen.addAll(subgroup.emoji);
      }
    }
    expect(seen.toSet(), hasLength(seen.length));
  });

  test('has the five Fitzpatrick tones, light to dark', () {
    expect(data.tones, ['🏻', '🏼', '🏽', '🏾', '🏿']);
  });

  test('a toneable base offers itself plus all five tones', () {
    final options = data.tonesFor('👍');
    expect(options, ['👍', '👍🏻', '👍🏼', '👍🏽', '👍🏾', '👍🏿']);
  });

  test('an emoji that takes no tone offers no options', () {
    expect(data.tonesFor('😀'), isEmpty);
    expect(data.tonesFor('🍕'), isEmpty);
  });

  test('every toneable base really is in the grid', () {
    final stored = {
      for (final group in data.groups)
        for (final subgroup in group.subgroups) ...subgroup.emoji,
    };
    for (final base in data.toneable) {
      expect(
        stored,
        contains(base),
        reason: 'tone strip would be unreachable for $base',
      );
    }
  });

  test('bases that exist only in toned form are still reachable', () {
    // Nine bases have no untoned form of their own, so their toned rows stay in
    // the grid. If they were dropped along with the generated ones, these 45
    // emoji would have no way in.
    final stored = {
      for (final group in data.groups)
        for (final subgroup in group.subgroups) ...subgroup.emoji,
    };
    // Counted in runes, not `String.length`: a Dart string is UTF-16, so
    // "\u{1F590}\u{1F3FB}".length is 4, not the 2 code points it renders as.
    bool isToned(String glyph) {
      final runes = glyph.runes.toList();
      if (runes.length != 2) return false;
      return data.tones.contains(String.fromCharCode(runes[1]));
    }

    String baseOf(String glyph) =>
        String.fromCharCode(glyph.runes.toList().first);

    // The toned rows that *are* reachable by long press are generated at
    // runtime, not stored, so every match here is a tone-only base.
    final toneOnly = [
      for (final glyph in stored)
        if (isToned(glyph)) glyph,
    ];
    expect(toneOnly, hasLength(45));
    for (final glyph in toneOnly) {
      expect(
        stored,
        isNot(contains(baseOf(glyph))),
        reason: '$glyph should have no untoned form in the grid',
      );
    }
  });

  test('records the source so a stale asset is detectable', () {
    expect(data.version, isNotEmpty);
  });
}
