import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/data/emoji_data.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/gif_picker.dart';
import 'package:qutty/widgets/ugc_picker.dart';

/// The three things a user can pick from the composer's media panel.
///
/// Emoji appends text to the composer, while the other two are meant to send a
/// media message once the server can accept one. They are one enum so the shell
/// of the panel -- tabs, sizing, dismissal -- is written once.
enum MediaPickerTab { sticker, emoji, gif }

/// Translated labels for the nine Unicode emoji groups.
///
/// The category strip is icons, so these are tooltips and screen reader names
/// rather than visible text. The groups are Unicode's own, not a scheme invented
/// here, so there are exactly nine of them and no more.
extension EmojiGroupLabel on EmojiGroup {
  String label(AppLocalizations l10n) => switch (id) {
    'smileys-emotion' => l10n.mediaPickerGroupSmileysEmotion,
    'people-body' => l10n.mediaPickerGroupPeopleBody,
    'animals-nature' => l10n.mediaPickerGroupAnimalsNature,
    'food-drink' => l10n.mediaPickerGroupFoodDrink,
    'travel-places' => l10n.mediaPickerGroupTravelPlaces,
    'activities' => l10n.mediaPickerGroupActivities,
    'objects' => l10n.mediaPickerGroupObjects,
    'symbols' => l10n.mediaPickerGroupSymbols,
    'flags' => l10n.mediaPickerGroupFlags,
    // A group added by a future Unicode release should still be reachable
    // rather than showing an unlabelled button.
    _ => name,
  };

  IconData get icon => switch (id) {
    'smileys-emotion' => Icons.sentiment_satisfied_alt,
    'people-body' => Icons.accessibility_new,
    'animals-nature' => Icons.pets,
    'food-drink' => Icons.restaurant,
    'travel-places' => Icons.travel_explore,
    'activities' => Icons.sports_soccer,
    'objects' => Icons.lightbulb_outline,
    'symbols' => Icons.emoji_symbols,
    'flags' => Icons.flag_outlined,
    _ => Icons.category_outlined,
  };
}

/// Edge of a grid cell, in logical pixels.
///
/// Cells are square at this edge, and the tone strip positions itself from a row
/// index, so the two have to agree on the number.
const double _cell = 40;

/// The panel body for a given tab, without its outer frame.
class MediaPickerPanel extends StatefulWidget {
  final MediaPickerTab tab;
  final ValueChanged<MediaPickerTab> onTabChanged;
  final ValueChanged<String> onEmojiSelected;

  /// Called with the GIF the user tapped.
  ///
  /// The panel stops there: resolving a GIF means downloading it into storage,
  /// which is the caller's job, so a failure is reported next to the composer
  /// instead of inside the panel.
  final ValueChanged<GifInfo> onGifSelected;

  /// Called with the UGC item the user tapped.
  ///
  /// Like a GIF, the panel does not send anything: the composer turns the item
  /// into a `<ugc:id>` reference in its own text.
  final ValueChanged<UgcItem> onUgcSelected;

  /// Opens the developer portal, where UGC packs and items are created.
  final VoidCallback onOpenUgcPortal;

  final ApiService api;
  final VoidCallback onClose;

  const MediaPickerPanel({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.onEmojiSelected,
    required this.onGifSelected,
    required this.onUgcSelected,
    required this.onOpenUgcPortal,
    required this.api,
    required this.onClose,
  });

  @override
  State<MediaPickerPanel> createState() => _MediaPickerPanelState();
}

class _MediaPickerPanelState extends State<MediaPickerPanel> {
  /// Null until the asset has parsed. The panel renders a spinner meanwhile
  /// rather than an empty grid, so a slow read does not look like a broken
  /// picker.
  Future<EmojiData>? _data;

  int _groupIndex = 0;

  /// The emoji whose tone strip is open, and the cell it was opened from.
  ///
  /// Held as a position rather than a glyph so the strip survives the grid
  /// scrolling underneath it, and dismissed if that cell scrolls out of view.
  String? _toneBase;
  int? _toneRow;

  @override
  void initState() {
    super.initState();
    _data = EmojiData.load();
  }

  void _selectGroup(int index) {
    setState(() {
      _groupIndex = index;
      _toneBase = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<MediaPickerTab>(
                  segments: [
                    ButtonSegment(
                      value: MediaPickerTab.sticker,
                      label: Text(l10n.mediaPickerStickerTab),
                    ),
                    ButtonSegment(
                      value: MediaPickerTab.emoji,
                      label: Text(l10n.mediaPickerEmojiTab),
                    ),
                    ButtonSegment(
                      value: MediaPickerTab.gif,
                      label: Text(l10n.mediaPickerGifTab),
                    ),
                  ],
                  selected: {widget.tab},
                  onSelectionChanged: (selection) =>
                      widget.onTabChanged(selection.first),
                  showSelectedIcon: false,
                ),
              ),
              IconButton(
                tooltip: l10n.commonClose,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Expanded(
          child: switch (widget.tab) {
            MediaPickerTab.emoji => _emojiBody(l10n),
            MediaPickerTab.sticker => UgcPicker(
              // Re-keyed on the token so switching accounts cannot leave one
              // user's stickers on screen for the next.
              key: ValueKey(widget.api.token),
              api: widget.api,
              onSelected: widget.onUgcSelected,
              onManage: widget.onOpenUgcPortal,
            ),
            MediaPickerTab.gif => GifPicker(
              // Re-keyed on the token so switching accounts cannot leave one
              // user's GIFs on screen for the next.
              key: ValueKey(widget.api.token),
              api: widget.api,
              onSelected: widget.onGifSelected,
            ),
          },
        ),
      ],
    );
  }

  Widget _emojiBody(AppLocalizations l10n) {
    // Parsed already on every open after the first, so the grid is built on the
    // first frame rather than flashing a spinner each time.
    final cached = EmojiData.cached;
    if (cached != null) return _browse(cached, l10n);

    return FutureBuilder<EmojiData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return snapshot.hasError
              ? _placeholderBody(
                  icon: Icons.error_outline,
                  message: l10n.mediaPickerEmojiLoadFailed,
                )
              : const Center(child: CircularProgressIndicator());
        }
        return _browse(data, l10n);
      },
    );
  }

  /// The category strip and the grid, with the tone strip overlaid on the grid
  /// while one is open.
  ///
  /// There is no second level: a category shows all of its emoji at once. The
  /// 98 subgroups were a browsing aid for a grid you had to page through, and
  /// they cost a row of the panel's little height to no benefit once the whole
  /// category is one scroll away.
  Widget _browse(EmojiData data, AppLocalizations l10n) {
    // The asset is fixed, so this cannot normally be out of range; clamping
    // keeps a bad index from throwing inside a build.
    final group = data.groups[_groupIndex.clamp(0, data.groups.length - 1)];

    return Column(
      children: [
        _groupStrip(data, l10n),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _emojiGrid(data, group)),
              if (_toneBase != null)
                Positioned.fill(
                  child: _ToneStripOverlay(
                    data: data,
                    base: _toneBase!,
                    row: _toneRow,
                    l10n: l10n,
                    onSelected: (glyph) {
                      setState(() => _toneBase = null);
                      widget.onEmojiSelected(glyph);
                    },
                    onDismissed: () => setState(() => _toneBase = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The nine categories, as a horizontal strip along the top.
  Widget _groupStrip(EmojiData data, AppLocalizations l10n) {
    return Container(
      height: 44,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        itemCount: data.groups.length,
        itemBuilder: (context, index) {
          final group = data.groups[index];
          final selected = index == _groupIndex;
          return IconButton(
            tooltip: group.label(l10n),
            isSelected: selected,
            icon: Icon(group.icon),
            onPressed: () => _selectGroup(index),
          );
        },
      ),
    );
  }

  Widget _emojiGrid(EmojiData data, EmojiGroup group) {
    final glyphs = group.allEmoji;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derived from the grid's own width, not the window's, so the grid
        // reflows with the panel instead of the window.
        final columns = (constraints.maxWidth / _cell)
            .floor()
            .clamp(3, 14)
            .toInt();
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
          // Keyed on the group so switching category starts at the top instead
          // of inheriting the previous scroll offset.
          key: ValueKey(group.id),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: glyphs.length,
          itemBuilder: (context, index) {
            final glyph = glyphs[index];
            final toneable = data.tonesFor(glyph).isNotEmpty;
            return InkWell(
              // The picker stays open on purpose: people send runs of emoji, and the
              // panel also closes on the next tap of the text field.
              onTap: () => widget.onEmojiSelected(glyph),
              onLongPress: toneable
                  ? () => setState(() {
                      _toneBase = glyph;
                      _toneRow = index ~/ columns;
                    })
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(glyph, style: const TextStyle(fontSize: 22)),
                  ),
                  // Marks the cells that open a tone strip on a long press.
                  if (toneable)
                    const Positioned(
                      right: 2,
                      bottom: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x61000000),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 5, height: 5),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Shown for the tabs that have nothing to show yet, and if the asset fails to
  /// load. Says so plainly instead of rendering an empty grid, so a missing
  /// backend or a broken bundle does not read as a broken picker.
  Widget _placeholderBody({required IconData icon, required String message}) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// The skin tone chooser that opens over the grid on a long press.
///
/// Anchored just above the pressed cell, the way a context menu is, rather than
/// dumped in a corner. A barrier behind it swallows taps on the grid so picking a
/// tone does not also insert the emoji underneath.
class _ToneStripOverlay extends StatelessWidget {
  const _ToneStripOverlay({
    required this.data,
    required this.base,
    required this.row,
    required this.l10n,
    required this.onSelected,
    required this.onDismissed,
  });

  final EmojiData data;
  final String base;
  final int? row;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelected;
  final VoidCallback onDismissed;

  List<String> _names() => [
    l10n.mediaPickerSkinToneDefault,
    l10n.mediaPickerSkinToneLight,
    l10n.mediaPickerSkinToneMediumLight,
    l10n.mediaPickerSkinToneMedium,
    l10n.mediaPickerSkinToneMediumDark,
    l10n.mediaPickerSkinToneDark,
  ];

  @override
  Widget build(BuildContext context) {
    final options = data.tonesFor(base);
    if (options.isEmpty) return const SizedBox.shrink();
    final names = _names();
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = options.length * _cell;
        // Keep the strip on screen when the cell is near either edge.
        final left = (constraints.maxWidth - width) / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismissed,
              ),
            ),
            Positioned(
              left: left.clamp(
                0.0,
                (constraints.maxWidth - width).clamp(0.0, double.infinity),
              ),
              // Sit above the pressed row when there is room, otherwise below.
              bottom: row == null
                  ? 0
                  : (row! * _cell + _cell + 8).clamp(
                      0.0,
                      constraints.maxHeight - _cell - 16,
                    ),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: colors.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < options.length; i++)
                        Tooltip(
                          message: names[i],
                          child: InkWell(
                            onTap: () => onSelected(options[i]),
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: _cell,
                              height: _cell,
                              child: Center(
                                child: Text(
                                  options[i],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
