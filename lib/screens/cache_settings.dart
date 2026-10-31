import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/services/cache_overview.dart';
import 'package:qutty/widgets/settings_ui.dart';

/// The screen that shows what the app keeps on the device and lets the user
/// decide how much of it there should be.
///
/// The cache is what makes Qutty readable in a tunnel: the conversations that
/// were read, the pictures that were seen and the people that were met are all
/// kept here. This screen says how much of that there is, and offers the ways
/// to get rid of it.
class CacheSettingsScreen extends StatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  State<CacheSettingsScreen> createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends State<CacheSettingsScreen> {
  /// The sizes the media cache may be limited to.
  static const List<int> _limitOptions = <int>[
    64 * 1024 * 1024,
    128 * 1024 * 1024,
    256 * 1024 * 1024,
    512 * 1024 * 1024,
    1024 * 1024 * 1024,
  ];

  CacheOverview _overview = CacheOverview.empty;
  bool _loading = true;

  /// The switches as they were last seen, so a change of the manager is only
  /// noticed when one of them actually moved.
  bool? _cacheMedia;
  bool? _cacheChats;

  @override
  void initState() {
    super.initState();
    _cacheMedia = AppManager.instance.cacheMedia;
    _cacheChats = AppManager.instance.cacheChats;
    AppManager.instance.addListener(_onManagerChanged);
    _refresh();
  }

  @override
  void dispose() {
    AppManager.instance.removeListener(_onManagerChanged);
    super.dispose();
  }

  /// Reloads the numbers shown on the screen.
  Future<void> _refresh() async {
    final overview = await AppManager.instance.cacheOverview();
    if (!mounted) return;
    setState(() {
      _overview = overview;
      _loading = false;
    });
  }

  /// Refreshes the numbers when the cache switches change.
  ///
  /// Turning a switch off empties what it was keeping, so the sizes on the
  /// screen would be wrong until they are read again.
  void _onManagerChanged() {
    final manager = AppManager.instance;
    if (_cacheMedia == manager.cacheMedia &&
        _cacheChats == manager.cacheChats) {
      return;
    }
    _cacheMedia = manager.cacheMedia;
    _cacheChats = manager.cacheChats;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cacheTitle)),
      body: ListenableBuilder(
        listenable: AppManager.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SettingsSection(
              title: l10n.cacheOfflineSection,
              subtitle: l10n.cacheTitleSubtitle,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.image_outlined),
                  title: l10n.cacheMediaToggle,
                  subtitle: l10n.cacheMediaToggleSubtitle,
                  trailing: Switch(
                    value: AppManager.instance.cacheMedia,
                    onChanged: _setCacheMedia,
                  ),
                  onTap: () => _setCacheMedia(
                    !AppManager.instance.cacheMedia,
                  ),
                ),
                SettingsTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: l10n.cacheChatsToggle,
                  subtitle: l10n.cacheChatsToggleSubtitle,
                  trailing: Switch(
                    value: AppManager.instance.cacheChats,
                    onChanged: _setCacheChats,
                  ),
                  onTap: () =>
                      _setCacheChats(!AppManager.instance.cacheChats),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.cacheStorageSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.sd_storage_outlined),
                  title: l10n.cacheMediaLabel,
                  subtitle: _loading
                      ? l10n.commonLoading
                      : '${formatBytes(_overview.mediaBytes)} · '
                            '${l10n.cacheMediaFiles(_overview.mediaFiles)}',
                ),
                SettingsTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: l10n.cacheChatsLabel,
                  subtitle: _loading
                      ? l10n.commonLoading
                      : '${formatBytes(_overview.chatBytes)} · '
                            '${l10n.cacheChatCount(_overview.chatCount)}',
                ),
                SettingsTile(
                  leading: const Icon(Icons.summarize_outlined),
                  title: l10n.cacheTotalLabel,
                  subtitle: _loading
                      ? l10n.commonLoading
                      : formatBytes(_overview.totalBytes),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.cacheContentsSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.mark_email_unread_outlined),
                  title: l10n.cacheMessagesLabel,
                  subtitle: l10n.cacheMessageCount(_overview.messageCount),
                ),
                SettingsTile(
                  leading: const Icon(Icons.people_outline),
                  title: l10n.cacheProfilesLabel,
                  subtitle: l10n.cacheProfileCount(_overview.profileCount),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.cacheLimitLabel,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: l10n.cacheLimitLabel,
                  subtitle: l10n.cacheLimitSubtitle,
                  trailing: Text(
                    _loading
                        ? l10n.commonLoading
                        : formatBytes(_overview.mediaLimitBytes),
                  ),
                  onTap: _pickLimit,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.cacheClearSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: l10n.cacheClearMedia,
                  destructive: true,
                  onTap: () => _confirmClear(
                    title: l10n.cacheClearMediaTitle,
                    body: l10n.cacheClearMediaBody,
                    action: AppManager.instance.clearMediaCache,
                  ),
                ),
                SettingsTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: l10n.cacheClearChats,
                  destructive: true,
                  onTap: () => _confirmClear(
                    title: l10n.cacheClearChatsTitle,
                    body: l10n.cacheClearChatsBody,
                    action: AppManager.instance.clearChatCache,
                  ),
                ),
                SettingsTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: l10n.cacheClearAll,
                  destructive: true,
                  onTap: () => _confirmClear(
                    title: l10n.cacheClearAllTitle,
                    body: l10n.cacheClearAllBody,
                    action: AppManager.instance.clearAllCache,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCacheMedia(bool value) async {
    await AppManager.instance.setCacheMedia(value);
    await _refresh();
  }

  Future<void> _setCacheChats(bool value) async {
    await AppManager.instance.setCacheChats(value);
    await _refresh();
  }

  /// Lets the user pick how much space media may take.
  Future<void> _pickLimit() async {
    final l10n = context.l10n;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.cacheLimitLabel),
        children: [
          for (final option in _limitOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Row(
                children: [
                  if (option == _overview.mediaLimitBytes)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 12),
                  Text(formatBytes(option)),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    await AppManager.instance.setCacheLimit(selected);
    await _refresh();
  }

  /// Asks before emptying something, because there is no undo for it.
  Future<void> _confirmClear({
    required String title,
    required String body,
    required Future<void> Function() action,
  }) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await action();
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
  }
}
