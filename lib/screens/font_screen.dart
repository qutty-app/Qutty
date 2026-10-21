import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/services/custom_fonts.dart';
import 'package:qutty/widgets/settings_ui.dart';

/// Picks the font the app renders in.
///
/// Offers the platform font, the catalog, and a file from the device, as one
/// mutually exclusive choice. They share a single [RadioGroup] so exactly one
/// can be selected: with a group per row each row would compare its own value
/// against its own `groupValue` and every row would look selected at once.
class FontScreen extends StatefulWidget {
  const FontScreen({super.key});

  @override
  State<FontScreen> createState() => _FontScreenState();
}

class _FontScreenState extends State<FontScreen> {
  /// The catalog entry being downloaded, so only that row shows progress.
  String? _downloading;

  bool get _busy => _downloading != null;

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsFont)),
      body: ListenableBuilder(
        listenable: manager,
        // Scrollable because the rows carry two lines of text each, which
        // overflows a short screen at a large accessibility text size.
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SettingsSection(
              // A distinct label from the app bar, matching how the language
              // screen titles its own section.
              title: l10n.fontSubtitle,
              children: [
                RadioGroup<String>(
                  // The one value the group is selected on. `fontId` is null on
                  // the platform font, so the system row uses the sentinel.
                  groupValue: manager.fontId ?? _systemValue,
                  onChanged: (value) => _onSelected(manager, value),
                  child: Column(
                    children: [
                      _systemRow(manager),
                      for (final font in downloadableFonts)
                        _catalogRow(manager, font),
                      _sideloadRow(manager),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSelected(AppManager manager, String? value) {
    if (_busy || value == null) return;
    if (value == _systemValue) {
      manager.useSystemFont();
      return;
    }
    if (value == _sideloadId) {
      _sideload(manager);
      return;
    }
    for (final font in downloadableFonts) {
      if (font.id == value) {
        // Belt and braces: the row is already unselectable, but this is the one
        // place a choice turns into an action, so it does not take the tile's
        // word for what is on disk.
        if (manager.downloadedFonts.contains(font.id)) _select(manager, font);
        return;
      }
    }
  }

  Widget _systemRow(AppManager manager) => RadioListTile<String>(
    value: _systemValue,
    // Always available, so a user who has downloaded a font is never stranded
    // with no way back to the platform's own.
    enabled: true,
    title: Text(context.l10n.fontSystemDefault),
    subtitle: _preview(manager, _systemValue),
  );

  Widget _catalogRow(AppManager manager, DownloadableFont font) {
    final l10n = context.l10n;
    final downloaded = manager.downloadedFonts.contains(font.id);
    return RadioListTile<String>(
      value: font.id,
      // A font that is not on disk cannot be picked. Disabled here rather than
      // only refused on tap, so the row looks unavailable instead of ignoring
      // the user. `secondary` is rendered untouched by a disabled tile, so the
      // download button stays lit and remains the way in.
      enabled: downloaded,
      title: Text(font.label),
      subtitle: _downloading == font.id
          ? Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(l10n.fontDownloadingLabel(font.label)),
              ],
            )
          : _preview(manager, font.id),
      // Not downloaded: one action, which asks first. Downloaded: the file is
      // already here, so the row is about keeping or removing it.
      secondary: !downloaded
          ? TextButton(
              onPressed: _busy ? null : () => _confirmDownload(manager, font),
              child: Text(l10n.fontDownload),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.fontDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy
                      ? null
                      : () => _confirmDelete(manager, font),
                ),
                IconButton(
                  tooltip: l10n.fontSource,
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openSource(font),
                ),
              ],
            ),
    );
  }

  /// Asks before fetching, because a download is a network round trip and a
  /// change to the device's storage that the user did not obviously ask for.
  Future<void> _confirmDownload(
    AppManager manager,
    DownloadableFont font,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fontDownloadTitle(font.label)),
        content: Text(l10n.fontDownloadBody(font.sourceUrl)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.fontDownload),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _downloading = font.id);
    try {
      await manager.downloadFont(font);
    } on FontException {
      if (mounted) _report(l10n.fontDownloadFailed);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  /// Asks before deleting: this removes the font from the device, and deletes
  /// the app's current font if it happens to be this one.
  Future<void> _confirmDelete(
    AppManager manager,
    DownloadableFont font,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fontDeleteTitle(font.label)),
        content: Text(l10n.fontDeleteBody(font.sourceUrl)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.fontDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await manager.deleteDownloadedFont(font);
    } on FontException {
      if (mounted) _report(l10n.fontDeleteFailed);
    }
  }

  /// Opens where the font is published, so the user can see it before trusting
  /// a file the app fetched for them.
  Future<void> _openSource(DownloadableFont font) async {
    final l10n = context.l10n;
    final uri = Uri.tryParse(font.sourceUrl);
    if (uri == null) return;
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) _report(l10n.fontSourceFailed);
  }

  Widget _sideloadRow(AppManager manager) {
    final l10n = context.l10n;
    // A sideloaded font has no name the app can ask the engine for, so the
    // filename it was picked under stands in for the label.
    return RadioListTile<String>(
      value: _sideloadId,
      // Never gated either: tapping this row is what picks the file, so there is
      // nothing to gate it behind until the pick is made.
      enabled: true,
      title: Text(l10n.fontChooseFromFile),
      subtitle: manager.fontId == _sideloadId
          ? Text(
              manager.fontLabel ?? l10n.fontChooseFromFile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: manager.fontFamily),
            )
          : _preview(manager, _sideloadId),
    );
  }

  /// The sample text for a row, or a note that its font is not loaded.
  ///
  /// Only the font that is actually registered with the engine can be shown. A
  /// sample drawn in any other font is worse than no sample: it looks like a
  /// preview of the font on that row while actually rendering the default.
  /// There is no pre-download preview, so a row that has not been applied yet
  /// says so instead.
  Widget _preview(AppManager manager, String id) {
    final l10n = context.l10n;
    final active = manager.fontId ?? _systemValue;
    if (active != id) {
      return Text(
        l10n.fontNotLoaded,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Text(
      l10n.fontSample,
      style: TextStyle(fontFamily: manager.fontFamily),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _select(AppManager manager, DownloadableFont font) async {
    // Only a font that is not already cached goes through a download, so only
    // that one shows progress. Otherwise applying a cached font would flash
    // "Downloading" for a fetch that never happens.
    final needsDownload = !manager.downloadedFonts.contains(font.id);
    if (needsDownload) setState(() => _downloading = font.id);
    try {
      // The manager records the new font as downloaded, and the notify behind
      // that rebuilds this row into a selectable one.
      await manager.useDownloadableFont(font);
    } on FontException {
      if (mounted) _report(context.l10n.fontDownloadFailed);
    } finally {
      if (mounted && needsDownload) setState(() => _downloading = null);
    }
  }

  Future<void> _sideload(AppManager manager) async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf'],
      // Read in memory so the file is available immediately on every platform,
      // including the ones where `path` points somewhere the app cannot reopen.
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      if (mounted) _report(l10n.fontFileUnreadable);
      return;
    }
    setState(() => _downloading = _sideloadId);
    try {
      await manager.useSideloadedFont(bytes, name: _nameOf(picked.name));
    } on FontException {
      if (mounted) _report(l10n.fontFileUnreadable);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  /// The file's name without its extension, which is what the row shows.
  ///
  /// A font's real name lives in the font's own name table, and reading that
  /// means parsing a table the app has no other reason to know about. The
  /// filename is what the user recognises having just picked it.
  static String _nameOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  void _report(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Radio values are non-nullable, so "no font chosen" gets a sentinel that no
/// font id can collide with.
const _systemValue = '';

/// Matches the cache slot `AppManager.useSideloadedFont` writes to.
const _sideloadId = 'sideload';
