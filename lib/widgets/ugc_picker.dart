import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/ugc.dart';
import 'package:qutty/widgets/ugc_popup.dart';
import 'package:qutty/widgets/ugc_share.dart';

/// The Sticker tab of the composer's media panel: the account's saved UGC
/// packs, plus its own shortlist of items.
///
/// It does not build UGCs -- that happens in the developer portal -- it only
/// picks one. Only packs the account has saved (favorited) appear here, so the
/// row of chips is the saved collection itself rather than every pack owned;
/// the chip after All is the item shortlist, which cuts across packs. Tapping a
/// sticker opens a popup that names the pack and offers what a picker row can
/// ask for: insert the sticker into the composer, save or unsave the pack it
/// belongs to, or copy the pack's share link. A long press puts the item on the
/// shortlist, since a tap already means insert. A small gear in the corner
/// opens the portal for anyone who wants to make more.
class UgcPicker extends StatefulWidget {
  final ApiService api;

  /// Called with the item the user chose. The picker does not insert or send
  /// anything itself: the composer owns the text it is edited into.
  final ValueChanged<UgcItem> onSelected;

  /// Opens the developer portal, where packs and items are created.
  final VoidCallback onManage;

  const UgcPicker({
    super.key,
    required this.api,
    required this.onSelected,
    required this.onManage,
  });

  @override
  State<UgcPicker> createState() => _UgcPickerState();
}

class _UgcPickerState extends State<UgcPicker> {
  /// The account's saved packs, in the order the server returned them.
  ///
  /// Never mutated after a load: whether a pack is still saved is decided by
  /// [_favoritePackIds], so unsaving and re-saving puts a pack back exactly
  /// where it was.
  List<UgcPack> _packs = const [];
  Map<int, List<UgcItem>> _itemsByPack = {};

  /// Ids of the packs the account has saved.
  ///
  /// The source of truth for the grid: a pack disappears from the chips and
  /// the moment its id leaves this set, and reappears if it comes back.
  Set<int> _favoritePackIds = {};

  /// The account's item shortlist, in the order the server returned it.
  ///
  /// Items rather than ids because the shortlist chip has to draw them even
  /// when the pack they belong to is not saved, or was never fetched.
  List<UgcItem> _favoriteItems = const [];

  /// The pack the grid is scoped to, or null for every saved pack.
  int? _packId;

  /// Whether the grid is scoped to the item shortlist instead of a pack.
  bool _favoritesOnly = false;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packs = await widget.api.ugcFavoritePacks();
      // Items are fetched per pack, so one broken pack cannot blank the tab.
      final itemsByPack = <int, List<UgcItem>>{};
      await Future.wait(
        packs.map((pack) async {
          try {
            itemsByPack[pack.id] = await widget.api.ugcItems(packId: pack.id);
          } catch (_) {
            itemsByPack[pack.id] = const [];
          }
        }),
      );
      // The shortlist is a nice-to-have: when it cannot be read the chip is
      // simply empty, rather than the whole tab failing over it.
      var favorites = const <UgcItem>[];
      try {
        favorites = await widget.api.ugcFavoriteItems();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _itemsByPack = itemsByPack;
        _favoriteItems = favorites;
        _favoritePackIds = {for (final pack in packs) pack.id};
        // A pack that vanished (unsaved elsewhere) leaves the filter pointing
        // at nothing, so drop back to "all".
        if (_packId != null && !packs.any((pack) => pack.id == _packId)) {
          _packId = null;
        }
        _loading = false;
      });
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _error = exception.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = L10n.current.ugcPickerLoadFailed;
          _loading = false;
        });
      }
    }
  }

  /// The saved packs, in load order.
  List<UgcPack> get _savedPacks => [
    for (final pack in _packs)
      if (_favoritePackIds.contains(pack.id)) pack,
  ];

  /// Ids of the items on the shortlist, for the badge the grid draws.
  Set<int> get _favoriteItemIds => {for (final item in _favoriteItems) item.id};

  List<UgcItem> get _visible {
    if (_favoritesOnly) return _favoriteItems;
    if (_packId != null) return _itemsByPack[_packId] ?? const <UgcItem>[];
    return [
      for (final pack in _savedPacks) ...(_itemsByPack[pack.id] ?? const []),
    ];
  }

  /// Flips whether [pack] is saved.
  ///
  /// The heart in the popup is direct manipulation, so the change lands before
  /// the round trip and is rolled back if the server refuses.
  Future<bool> _toggleFavoritePack(UgcPack pack, bool saved) async {
    setState(() {
      saved
          ? _favoritePackIds.add(pack.id)
          : _favoritePackIds.remove(pack.id);
      // The grid is scoped to the pack that just left the collection.
      if (!saved && _packId == pack.id) _packId = null;
    });
    try {
      saved
          ? await widget.api.addUgcFavoritePack(pack.id)
          : await widget.api.removeUgcFavoritePack(pack.id);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? context.l10n.ugcPickerSaved
                : context.l10n.ugcPickerRemoved,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          saved
              ? _favoritePackIds.remove(pack.id)
              : _favoritePackIds.add(pack.id);
        });
      }
      return false;
    }
  }

  /// Adds or removes one item from the account's shortlist.
  ///
  /// The shortlist is direct manipulation like the pack heart, so the change
  /// lands before the round trip and is rolled back if the server refuses.
  Future<void> _toggleFavoriteItem(UgcItem item) async {
    final wasSaved = _favoriteItemIds.contains(item.id);
    void apply(bool saved) => setState(() {
      _favoriteItems = saved
          ? [item, ..._favoriteItems.where((it) => it.id != item.id)]
          : _favoriteItems.where((it) => it.id != item.id).toList();
    });
    apply(!wasSaved);
    try {
      wasSaved
          ? await widget.api.removeUgcFavoriteItem(item.id)
          : await widget.api.addUgcFavoriteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved
                ? context.l10n.ugcPickerRemoved
                : context.l10n.ugcPickerSaved,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (mounted) apply(wasSaved);
    }
  }

  /// Opens the popup for one sticker: a large preview, the pack it belongs to,
  /// and the choice to insert it, save/unsave the pack, or share it.
  Future<void> _openSticker(UgcItem item) async {
    final pack = _packs.where((pack) => pack.id == item.packId).firstOrNull;
    await showUgcPopup(
      context,
      item: item,
      packName: pack?.displayName,
      saved: _favoritePackIds.contains(item.packId),
      onToggleSave: pack == null
          ? null
          : (saved) => _toggleFavoritePack(pack, saved),
      onInsert: () => widget.onSelected(item),
      onShare: pack == null ? null : () => copyUgcPackLink(context, pack.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final packs = _savedPacks;
    return Column(
      children: [
        if (_error == null)
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    children: [
                      _chip(
                        label: l10n.ugcPickerAll,
                        selected: _packId == null && !_favoritesOnly,
                        onTap: () => setState(() {
                          _packId = null;
                          _favoritesOnly = false;
                        }),
                      ),
                      _chip(
                        label: l10n.ugcPickerFavorites,
                        selected: _favoritesOnly,
                        onTap: () => setState(() {
                          _packId = null;
                          _favoritesOnly = true;
                        }),
                      ),
                      for (final pack in packs)
                        _chip(
                          label: pack.displayName,
                          selected: _packId == pack.id,
                          onTap: () => setState(() {
                            _packId = pack.id;
                            _favoritesOnly = false;
                          }),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.ugcPickerManage,
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  onPressed: widget.onManage,
                ),
              ],
            ),
          ),
        Divider(height: 1, color: colors.outlineVariant),
        Expanded(child: _body(l10n)),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        labelStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _placeholder(
        icon: Icons.error_outline,
        message: _error!,
        action: TextButton(
          onPressed: _load,
          child: Text(l10n.commonTryAgain),
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      // The shortlist is a view of its own; everything else points at the
      // portal, where packs are made and saved.
      if (_favoritesOnly) {
        return _placeholder(
          icon: Icons.favorite_border,
          message: l10n.ugcNoFavorites,
        );
      }
      // Nothing saved yet points at the portal, where packs are made and
      // saved; a saved pack that happens to be empty keeps the old message.
      final noPacks = _savedPacks.isEmpty;
      return _placeholder(
        icon: Icons.emoji_emotions_outlined,
        message: noPacks ? l10n.ugcPickerNoPacks : l10n.ugcPickerEmpty,
        action: TextButton.icon(
          onPressed: widget.onManage,
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: Text(l10n.ugcPickerManage),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cells reflow with the panel's own width, so the grid stays square on
        // a phone and on a wide desktop window alike.
        final favoriteItemIds = {for (final item in _favoriteItems) item.id};
        final cell = 56.0;
        final columns = (constraints.maxWidth / cell)
            .floor()
            .clamp(3, 16)
            .toInt();
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Tooltip(
              message: item.name,
              child: InkWell(
                onTap: () => _openSticker(item),
                onLongPress: () => unawaited(_toggleFavoriteItem(item)),
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: UgcThumb(item: item, size: 48),
                    ),
                    if (favoriteItemIds.contains(item.id))
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
