import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One Unicode emoji subgroup, e.g. `hand-fingers-open`.
///
/// [name] is the subgroup's own English name straight from the Unicode source
/// file. It is not translated: there are 98 of them, and translating all of them
/// into six languages for a label the user only reads while scrolling past is a
/// poor trade. The primary navigation -- the [EmojiGroup] rail -- is localized.
class EmojiSubgroup {
  const EmojiSubgroup({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final String id;
  final String name;
  final List<String> emoji;
}

/// A top-level Unicode emoji group, e.g. `People & Body`.
///
/// These nine are the picker's primary navigation, so unlike [EmojiSubgroup]
/// they carry a translated label -- see `EmojiGroup.label`.
class EmojiGroup {
  const EmojiGroup({
    required this.id,
    required this.name,
    required this.subgroups,
  });

  final String id;
  final String name;
  final List<EmojiSubgroup> subgroups;

  int get length =>
      subgroups.fold(0, (total, subgroup) => total + subgroup.emoji.length);

  /// Every emoji in this group, in subgroup order, with any repeat removed.
  ///
  /// The picker shows a whole category as one flat list, so a glyph listed under
  /// two subgroups would render as two identical cells. The generated asset
  /// keeps subgroups disjoint, so this currently drops nothing; it is here so a
  /// future regeneration cannot quietly start repeating cells.
  List<String> get allEmoji {
    final seen = <String>{};
    final glyphs = <String>[];
    for (final subgroup in subgroups) {
      for (final glyph in subgroup.emoji) {
        if (seen.add(glyph)) glyphs.add(glyph);
      }
    }
    return glyphs;
  }
}

/// The full RGI emoji set, loaded from the generated asset.
///
/// Covers every fully-qualified emoji in Unicode Emoji 18.0 -- 3,963 of them --
/// rather than a curated subset, so nothing a person might send is missing.
/// Skin toned variants are not stored individually: [tonesFor] derives them,
/// which is exact because `base + modifier` reproduces the Unicode glyph.
class EmojiData {
  EmojiData._({
    required this.version,
    required this.tones,
    required this.toneable,
    required this.groups,
  });

  /// The Unicode Emoji version the asset was generated from, e.g. `18`.
  final String version;

  /// The five Fitzpatrick modifiers, light to dark.
  final List<String> tones;

  /// Bases that accept a tone, keyed by the untoned glyph.
  final Set<String> toneable;

  final List<EmojiGroup> groups;

  /// Total fully-qualified emoji this data set reaches.
  ///
  /// Counts the stored emoji plus the toned variants derived from them, so this
  /// matches the count in the Unicode source file.
  int get length =>
      groups.fold(0, (total, group) => total + group.length) +
      toneable.length * tones.length;

  /// The tone options for [glyph], or an empty list if it takes no tone.
  ///
  /// The untoned glyph comes first when it is a real emoji, followed by the tones
  /// light to dark. Bases that exist only in toned form still return their five
  /// tones, so every toned emoji stays reachable.
  List<String> tonesFor(String glyph) {
    if (!toneable.contains(glyph)) return const [];
    return [glyph, for (final tone in tones) '$glyph$tone'];
  }

  static EmojiData? _cache;

  /// Memoized so the asset is parsed once per process. A failed load clears the
  /// future so a later attempt can retry rather than replaying the error.
  static Future<EmojiData>? _loading;

  /// The already-parsed data set, or null if it has not finished loading.
  ///
  /// Lets a widget skip straight to the grid instead of flashing a spinner every
  /// time the picker is opened after the first.
  static EmojiData? get cached => _cache;

  /// Loads the data set once and shares it.
  ///
  /// Returns an already-completed future when [cached] is set, so callers that
  /// only need the data can use it synchronously via [cached].
  static Future<EmojiData> load() {
    final parsed = _cache;
    if (parsed != null) return Future.value(parsed);
    return _loading ??= _load().onError((error, stack) {
      _loading = null;
      throw error!;
    });
  }

  static Future<EmojiData> _load() async {
    final data = parse(await rootBundle.loadString('assets/emoji.json'));
    _cache = data;
    return data;
  }

  /// Test seam: parse the asset without going through the asset bundle.
  @visibleForTesting
  static EmojiData fromJsonString(String raw) => parse(raw);

  static EmojiData parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return EmojiData._(
      version: (json['version'] as String?) ?? '',
      tones: (json['tones'] as List<dynamic>).cast<String>(),
      toneable: (json['toneable'] as List<dynamic>).cast<String>().toSet(),
      groups: [
        for (final group in json['groups'] as List<dynamic>)
          EmojiGroup(
            id: group['id'] as String,
            name: group['name'] as String,
            subgroups: [
              for (final subgroup in group['subgroups'] as List<dynamic>)
                EmojiSubgroup(
                  id: subgroup['id'] as String,
                  name: subgroup['name'] as String,
                  emoji: (subgroup['emoji'] as List<dynamic>).cast<String>(),
                ),
            ],
          ),
      ],
    );
  }
}
