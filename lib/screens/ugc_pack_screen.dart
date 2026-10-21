import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/ugc.dart';
import 'package:qutty/widgets/ugc_popup.dart';
import 'package:qutty/widgets/ugc_share.dart';

/// One pack seen through a `qutty.app/sticker/<id>` link.
///
/// The link is how a pack travels between accounts, so the account that opens
/// this screen need not know the pack's owner at all. There is exactly one
/// thing to do with someone else's pack -- save it, which is what puts its
/// stickers in the composer's picker -- and one thing to pass it on, which is
/// copying the same link again. Nothing here writes to the pack itself; only
/// the owner's developer portal does that.
class UgcPackScreen extends StatefulWidget {
  final int packId;

  const UgcPackScreen({super.key, required this.packId});

  @override
  State<UgcPackScreen> createState() => _UgcPackScreenState();
}

class _UgcPackScreenState extends State<UgcPackScreen> {
  final _manager = AppManager.instance;

  UgcPack? _pack;
  List<UgcItem> _items = const [];

  /// Whether the account has already saved this pack.
  bool _saved = false;

  bool _loading = true;
  bool _busy = false;
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
      final pack = await _manager.api.ugcPack(widget.packId);
      final items = await _manager.api.ugcItems(packId: pack.id);
      var saved = false;
      try {
        saved = (await _manager.api.ugcFavoritePacks()).any(
          (favorite) => favorite.id == pack.id,
        );
      } catch (_) {
        // The pack is still worth showing if the saved list cannot be read;
        // the button simply starts as an offer to save.
      }
      if (!mounted) return;
      setState(() {
        _pack = pack;
        _items = items;
        _saved = saved;
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
          _error = context.l10n.ugcPackUnavailable;
          _loading = false;
        });
      }
    }
  }

  /// Flips whether the pack is saved, reporting what the server did.
  ///
  /// The popup shares this state through one round trip at a time, so a save
  /// made from the popup also moves the button, and a refusal rolls both back.
  Future<bool> _toggleSave(bool wanted) async {
    final l10n = context.l10n;
    final before = _saved;
    setState(() => _saved = wanted);
    try {
      wanted
          ? await _manager.api.addUgcFavoritePack(widget.packId)
          : await _manager.api.removeUgcFavoritePack(widget.packId);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wanted ? l10n.ugcPickerSaved : l10n.ugcPickerRemoved),
          duration: const Duration(seconds: 1),
        ),
      );
      return true;
    } catch (_) {
      if (mounted) setState(() => _saved = before);
      return false;
    }
  }

  Future<void> _saveButton() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _toggleSave(!_saved);
    if (mounted) setState(() => _busy = false);
  }

  /// Opens one sticker in the shared popup: the same preview, the same pack
  /// heart and the same share action the picker and a message offer, minus the
  /// Insert button, which has no composer to insert into here.
  void _openSticker(UgcItem item) {
    unawaited(
      showUgcPopup(
        context,
        item: item,
        packName: _pack?.displayName,
        saved: _saved,
        onToggleSave: _toggleSave,
        onShare: () => copyUgcPackLink(context, widget.packId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pack = _pack;
    return Scaffold(
      appBar: AppBar(
        title: Text(pack?.displayName ?? l10n.ugcPackTitle),
        actions: [
          if (pack != null)
            IconButton(
              tooltip: l10n.ugcSharePack,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => copyUgcPackLink(context, pack.id),
            ),
        ],
      ),
      bottomNavigationBar: pack == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: FilledButton.icon(
                  onPressed: _busy ? null : _saveButton,
                  icon: Icon(
                    _saved ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(_saved ? l10n.ugcUnsavePack : l10n.ugcSavePack),
                ),
              ),
            ),
      body: _body(l10n),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: Text(l10n.commonTryAgain),
            ),
          ],
        ),
      );
    }
    final pack = _pack!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pack.description.isNotEmpty) ...[
                Text(
                  pack.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                '${l10n.ugcItemsTitle} · ${_items.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Text(
                    l10n.ugcNoItems,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 72,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Tooltip(
                      message: item.name,
                      child: InkWell(
                        onTap: () => _openSticker(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: UgcThumb(item: item, size: 56),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
