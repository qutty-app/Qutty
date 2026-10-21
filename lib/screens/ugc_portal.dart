import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/settings_ui.dart';
import 'package:qutty/widgets/ugc.dart';
import 'package:qutty/widgets/ugc_share.dart';

/// The Developer portal's UGC page: where a user's stickers and emoji are made.
///
/// Picking happens in the composer; making happens here, on purpose. A pack is
/// created with a name, then items are uploaded into it one file at a time.
/// The heart on a pack tile saves it: only saved packs are offered by the
/// composer's sticker picker, so that heart is what puts a pack's stickers on
/// offer in a chat. The share button copies the pack's `qutty.app/sticker/<id>`
/// link, which is how a pack reaches another account. The shortlist of
/// individual items lives in the picker, not here.
class UgcPortalScreen extends StatefulWidget {
  const UgcPortalScreen({super.key});

  @override
  State<UgcPortalScreen> createState() => _UgcPortalScreenState();
}

class _UgcPortalScreenState extends State<UgcPortalScreen> {
  final _manager = AppManager.instance;

  List<UgcPack> _packs = const [];
  Map<int, List<UgcItem>> _itemsByPack = {};

  /// Ids of the packs the account has saved, so a heart can start filled.
  Set<int> _favoritePackIds = {};

  int? _selectedPackId;
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
      final packs = await _manager.api.ugcPacks();
      // Items are fetched per pack so one broken pack cannot blank the page.
      final itemsByPack = <int, List<UgcItem>>{};
      await Future.wait(
        packs.map((pack) async {
          try {
            itemsByPack[pack.id] = await _manager.api.ugcItems(
              packId: pack.id,
            );
          } catch (_) {
            itemsByPack[pack.id] = const [];
          }
        }),
      );
      final favoritePacks = await _manager.api.ugcFavoritePacks();
      if (!mounted) return;
      setState(() {
        _packs = packs;
        _itemsByPack = itemsByPack;
        _favoritePackIds = {for (final pack in favoritePacks) pack.id};
        if (_selectedPackId != null &&
            !packs.any((pack) => pack.id == _selectedPackId)) {
          _selectedPackId = null;
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

  /// Runs [action] with the page locked and reports any API failure as a
  /// snackbar, so a create or delete never leaves the UI half-updated silently.
  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (exception) {
      _snack(exception.message);
    } catch (_) {
      if (mounted) _snack(context.l10n.ugcCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createPack() async {
    final pack = await Navigator.of(context).push<UgcPack>(
      MaterialPageRoute(builder: (_) => const UgcPackFormScreen()),
    );
    if (pack == null || !mounted) return;
    setState(() {
      _packs = [pack, ..._packs];
      _itemsByPack[pack.id] = const [];
      _selectedPackId = pack.id;
    });
    _snack(context.l10n.ugcCreated);
  }

  Future<void> _deletePack(UgcPack pack) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.ugcDeletePackTitle,
      body: l10n.ugcDeletePackBody(pack.displayName),
    );
    if (!confirmed) return;
    await _guard(() async {
      await _manager.api.deleteUgcPack(pack.id);
      if (!mounted) return;
      setState(() {
        _packs = _packs.where((item) => item.id != pack.id).toList();
        _favoritePackIds.remove(pack.id);
        _itemsByPack.remove(pack.id);
        if (_selectedPackId == pack.id) _selectedPackId = null;
      });
      _snack(l10n.ugcDeleted);
    });
  }

  Future<void> _addItem(UgcPack pack) async {
    final item = await Navigator.of(context).push<UgcItem>(
      MaterialPageRoute(builder: (_) => UgcItemFormScreen(pack: pack)),
    );
    if (item == null || !mounted) return;
    setState(() {
      _itemsByPack[pack.id] = [item, ...?_itemsByPack[pack.id]];
    });
    _snack(context.l10n.ugcCreated);
  }

  Future<void> _deleteItem(UgcItem item) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.ugcDeleteItemTitle,
      body: l10n.ugcDeleteItemBody(item.name),
    );
    if (!confirmed) return;
    await _guard(() async {
      await _manager.api.deleteUgcItem(item.id);
      if (!mounted) return;
      setState(() {
        _itemsByPack[item.packId] = [
          ...?_itemsByPack[item.packId]?.where((it) => it.id != item.id),
        ];
      });
      _snack(l10n.ugcDeleted);
    });
  }

  /// Copies the pack's share link, which is how it reaches another account.
  Future<void> _sharePack(UgcPack pack) => copyUgcPackLink(context, pack.id);

  /// Saves or unsaves a whole pack: the picker only shows saved packs, so
  /// this heart is what puts a pack's stickers on offer in the chat.
  Future<void> _toggleFavoritePack(UgcPack pack) async {
    final l10n = context.l10n;
    final saved = !_favoritePackIds.contains(pack.id);
    await _guard(() async {
      saved
          ? await _manager.api.addUgcFavoritePack(pack.id)
          : await _manager.api.removeUgcFavoritePack(pack.id);
      if (!mounted) return;
      setState(() {
        saved
            ? _favoritePackIds.add(pack.id)
            : _favoritePackIds.remove(pack.id);
      });
      _snack(saved ? l10n.ugcPickerSaved : l10n.ugcPickerRemoved);
    });
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ugcPortalTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorBody(l10n)
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                SettingsSection(
                  title: l10n.ugcTitle,
                  subtitle: l10n.ugcSubtitle,
                  children: [
                    SettingsTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: l10n.ugcCreatePack,
                      onTap: _busy ? null : _createPack,
                    ),
                    if (_packs.isEmpty)
                      _EmptyTile(text: l10n.ugcNoPacks)
                    else
                      for (final pack in _packs)
                        _packTile(pack, l10n),
                  ],
                ),
                _selectedPackSection(l10n),
              ],
            ),
    );
  }

  Widget _errorBody(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? ''),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: Text(l10n.commonTryAgain),
          ),
        ],
      ),
    );
  }

  Widget _packTile(UgcPack pack, AppLocalizations l10n) {
    final selected = pack.id == _selectedPackId;
    final saved = _favoritePackIds.contains(pack.id);
    return InkWell(
      onTap: () => setState(() => _selectedPackId = pack.id),
      child: ListTile(
        leading: const Icon(Icons.emoji_emotions),
        title: Text(pack.displayName),
        subtitle: Text(
          '${l10n.ugcItemsTitle} · ${_itemsByPack[pack.id]?.length ?? 0}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(Icons.check_circle_outline, size: 20),
            IconButton(
              tooltip: l10n.ugcSharePack,
              icon: const Icon(Icons.share_outlined),
              onPressed: _busy ? null : () => _sharePack(pack),
            ),
            IconButton(
              tooltip: saved ? l10n.ugcUnsavePack : l10n.ugcSavePack,
              icon: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                color: saved ? Colors.redAccent : null,
              ),
              onPressed: _busy ? null : () => _toggleFavoritePack(pack),
            ),
            IconButton(
              tooltip: l10n.commonDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : () => _deletePack(pack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedPackSection(AppLocalizations l10n) {
    final pack = _packs.where((item) => item.id == _selectedPackId).firstOrNull;
    if (pack == null) return const SizedBox.shrink();
    final items = _itemsByPack[pack.id] ?? const <UgcItem>[];
    return SettingsSection(
      title: '${l10n.ugcItemsTitle} · ${pack.displayName}',
      children: [
        SettingsTile(
          leading: const Icon(Icons.add_photo_alternate_outlined),
          title: l10n.ugcAddItem,
          onTap: _busy ? null : () => _addItem(pack),
        ),
        if (items.isEmpty)
          _EmptyTile(text: l10n.ugcNoItems)
        else
          _itemGrid(items),
      ],
    );
  }

  /// The pack's items, as the owner sees them while building the pack.
  ///
  /// There is nothing to tap: the portal makes items, and picking one is the
  /// composer's job. A long press is the only gesture here, and it deletes.
  Widget _itemGrid(List<UgcItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Tooltip(
              message: item.name,
              child: InkWell(
                onLongPress: _busy ? null : () => _deleteItem(item),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: UgcThumb(item: item, size: 56),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The full-screen form for making a new pack, laid out like the create-chat
/// screen: a preview up top, a "Details" block of fields, and one action button
/// pinned to the bottom. Dialogs squeezed this form into an alert box, which
/// overflowed on small screens and hid fields behind the keyboard.
class UgcPackFormScreen extends StatefulWidget {
  const UgcPackFormScreen({super.key});

  @override
  State<UgcPackFormScreen> createState() => _UgcPackFormScreenState();
}

class _UgcPackFormScreenState extends State<UgcPackFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.ugcPackNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pack = await AppManager.instance.api.createUgcPack(
        displayName: name,
        description: _description.text.trim(),
      );
      if (mounted) Navigator.pop(context, pack);
    } on ApiException catch (exception) {
      if (mounted) setState(() => _error = exception.message);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.ugcCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ugcCreatePack),
        leading: IconButton(
          tooltip: l10n.createChatClose,
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.ugcCreatePackAction),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Center(
            child: CircleAvatar(
              radius: 52,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.emoji_emotions,
                size: 52,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.commonDetails,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            enabled: !_busy,
            autofocus: true,
            maxLength: 32,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.ugcPackName,
              prefixIcon: const Icon(Icons.emoji_symbols_outlined),
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            enabled: !_busy,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.commonDescription,
              prefixIcon: const Icon(Icons.short_text_outlined),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
    );
  }
}

/// The full-screen form for adding one item to a pack, in the same shape as
/// the create-chat screen: an image preview with a camera button, a "Details"
/// block, and one action button pinned to the bottom. The uploaded image is
/// the item, so the form will not submit without one.
class UgcItemFormScreen extends StatefulWidget {
  final UgcPack pack;

  const UgcItemFormScreen({super.key, required this.pack});

  @override
  State<UgcItemFormScreen> createState() => _UgcItemFormScreenState();
}

class _UgcItemFormScreenState extends State<UgcItemFormScreen> {
  final _name = TextEditingController();
  PlatformFile? _file;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    setState(() {
      _file = file;
      // A name is required, and the file name is the least surprising default.
      _name.text = _baseName(file.name);
    });
  }

  /// The file name without its extension, trimmed to the server's 32-char limit.
  String _baseName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    return base.length <= 32 ? base : base.substring(0, 32);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final file = _file;
    if (file == null || file.bytes == null) {
      setState(() => _error = l10n.ugcItemImageRequired);
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.ugcNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uploaded = await AppManager.instance.api.uploadFile(file);
      final item = await AppManager.instance.api.createUgcItem(
        packId: widget.pack.id,
        name: name,
        url: uploaded.url,
        key: uploaded.key,
        fileSize: uploaded.size,
        contentType: uploaded.contentType,
      );
      if (mounted) Navigator.pop(context, item);
    } on ApiException catch (exception) {
      if (mounted) setState(() => _error = exception.message);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.ugcCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ugcAddItem),
        leading: IconButton(
          tooltip: l10n.createChatClose,
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.ugcAddItem),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Center(
            child: Stack(
              children: [
                _file == null
                    ? CircleAvatar(
                        radius: 52,
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.emoji_emotions,
                          size: 52,
                          color: scheme.onPrimaryContainer,
                        ),
                      )
                    : CircleAvatar(
                        radius: 52,
                        backgroundImage: MemoryImage(_file!.bytes!),
                      ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: l10n.ugcChooseImage,
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '${l10n.commonDetails} · ${widget.pack.displayName}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            enabled: !_busy,
            autofocus: true,
            maxLength: 32,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.commonName,
              prefixIcon: const Icon(Icons.label_outlined),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
    );
  }
}

/// A section row that says "nothing here yet" without pretending to be a tile.
class _EmptyTile extends StatelessWidget {
  final String text;

  const _EmptyTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
