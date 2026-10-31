import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/settings_ui.dart';

/// The Developer portal's bots page: where a user's bots live.
///
/// A bot is a developer app the account owns: the backend created it as a user
/// row with `account_type` `bot`, bound it to the owner through a developer app
/// and gave it a session token that is handed out exactly once, at creation. The
/// token is the bot's whole credential, so creating, rotating and deleting bots
/// is the whole of the client-side story here.
class BotPortalScreen extends StatefulWidget {
  const BotPortalScreen({super.key});

  @override
  State<BotPortalScreen> createState() => _BotPortalScreenState();
}

class _BotPortalScreenState extends State<BotPortalScreen> {
  final _manager = AppManager.instance;

  List<BotInfo> _bots = const [];
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
      final bots = await _manager.api.bots();
      if (!mounted) return;
      setState(() {
        _bots = bots;
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
          _error = L10n.current.botsLoadFailed;
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
      if (mounted) _snack(context.l10n.botsActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _createBot() async {
    final created = await Navigator.of(context).push<CreatedBot>(
      MaterialPageRoute(builder: (_) => const BotFormScreen()),
    );
    if (created == null || !mounted) return;
    setState(() {
      _bots = [created.bot, ..._bots];
    });
    _snack(context.l10n.botsCreated);
    // The token only exists because the server handed it out here, and never
    // again: surfacing it now is the whole point of creating a bot.
    await _showTokenDialog(created.token);
  }

  Future<void> _editBot(BotInfo bot) async {
    final updated = await Navigator.of(
      context,
    ).push<BotInfo>(MaterialPageRoute(builder: (_) => BotFormScreen(bot: bot)));
    if (updated == null || !mounted) return;
    setState(() {
      _bots = [
        for (final item in _bots)
          if (item.id == updated.id) updated else item,
      ];
    });
    _snack(context.l10n.botsUpdated);
  }

  Future<void> _deleteBot(BotInfo bot) async {
    final confirmed = await _confirm(
      title: context.l10n.botsDeleteTitle,
      body: context.l10n.botsDeleteBody(bot.displayName),
      confirmLabel: context.l10n.commonDelete,
    );
    if (confirmed == false) return;
    await _guard(() async {
      await _manager.api.deleteBot(bot.id);
      if (!mounted) return;
      setState(() {
        _bots = _bots.where((item) => item.id != bot.id).toList();
      });
      _snack(context.l10n.botsDeleted);
    });
  }

  Future<void> _resetToken(BotInfo bot) async {
    final confirmed = await _confirm(
      title: context.l10n.botsResetTokenTitle,
      body: context.l10n.botsResetTokenBody,
      confirmLabel: context.l10n.botsResetTokenAction,
    );
    if (confirmed == false) return;
    await _guard(() async {
      final token = await _manager.api.resetBotToken(bot.id);
      if (!mounted) return;
      await _showTokenDialog(token);
    });
  }

  /// Shows a freshly rotated token once, because that is the only moment the
  /// bot can ever be given its credential.
  Future<void> _showTokenDialog(String token) async {
    final l10n = context.l10n;
    if (token.isEmpty) {
      _snack(l10n.botsTokenMissing);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.botsTokenTitle),
        content: Text(token),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.botsTokenCopied)),
              );
            },
            child: Text(l10n.botsTokenCopy),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.botsPortalTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorBody(l10n)
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                SettingsSection(
                  title: l10n.botsTitle,
                  subtitle: l10n.botsSubtitle,
                  children: [
                    SettingsTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: l10n.botsCreate,
                      onTap: _busy ? null : _createBot,
                    ),
                    if (_bots.isEmpty)
                      _EmptyTile(text: l10n.botsNoBots)
                    else
                      for (final bot in _bots) _botTile(bot, l10n),
                  ],
                ),
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
          FilledButton(onPressed: _load, child: Text(l10n.commonTryAgain)),
        ],
      ),
    );
  }

  Widget _botTile(BotInfo bot, AppLocalizations l10n) {
    final api = _manager.api;
    return ListTile(
      leading: Avatar(
        baseUrl: api.baseUrl,
        imageUrl: bot.avatarUrl,
        displayName: bot.displayName,
        radius: 24,
        fallbackIcon: Icons.smart_toy_outlined,
      ),
      title: Text(bot.displayName),
      subtitle: Text(
        [
          if (bot.handles.isNotEmpty) '@${bot.handles.first}',
          if (bot.bio.isNotEmpty) bot.bio,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.botsResetTokenTooltip,
            icon: const Icon(Icons.key_outlined),
            onPressed: _busy ? null : () => _resetToken(bot),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : () => _deleteBot(bot),
          ),
        ],
      ),
      onTap: _busy ? null : () => _editBot(bot),
    );
  }
}

/// The full-screen form for creating or editing a bot, laid out like the create
/// chat screen: a preview up top, a "Details" block of fields, and one action
/// button pinned to the bottom. The token only ever comes out of a create, so
/// the handle is only offered when there is a bot to name yet.
class BotFormScreen extends StatefulWidget {
  final BotInfo? bot;

  const BotFormScreen({super.key, this.bot});

  @override
  State<BotFormScreen> createState() => _BotFormScreenState();
}

class _BotFormScreenState extends State<BotFormScreen> {
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _handle = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final bot = widget.bot;
    if (bot != null) {
      _displayName.text = bot.displayName;
      _bio.text = bot.bio;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    // The handle is create-only: the backend never accepts one on update.
    _handle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final displayName = _displayName.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = l10n.createChatNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.bot == null) {
        final created = await AppManager.instance.api.createBot(
          displayName: displayName,
          bio: _bio.text.trim(),
          handle: _handle.text.trim(),
        );
        if (mounted) Navigator.pop(context, created);
      } else {
        final updated = await AppManager.instance.api.updateBot(
          widget.bot!.id,
          displayName: displayName,
          bio: _bio.text.trim(),
        );
        if (mounted) Navigator.pop(context, updated);
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => _error = exception.message);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.botsCreateFailed);
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
        title: Text(
          widget.bot == null ? l10n.botsCreateAction : l10n.commonSaveChanges,
        ),
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
            label: Text(
              widget.bot == null
                  ? l10n.botsCreateAction
                  : l10n.commonSaveChanges,
            ),
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
                Icons.smart_toy_outlined,
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
            controller: _displayName,
            enabled: !_busy,
            autofocus: widget.bot == null,
            maxLength: 32,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.createChatDisplayName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bio,
            enabled: !_busy,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.commonDescription,
              prefixIcon: const Icon(Icons.short_text_outlined),
            ),
          ),
          if (widget.bot == null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _handle,
              enabled: !_busy,
              maxLength: 32,
              decoration: InputDecoration(
                labelText: l10n.commonHandle,
                prefixIcon: const Icon(Icons.link_outlined),
                helperText: l10n.createChatUsernameOptionalHelper,
              ),
            ),
          ],
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
