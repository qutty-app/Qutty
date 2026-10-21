import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/settings_ui.dart';

import 'chat_members_screen.dart';
import 'chat_acl_screen.dart';
import 'edit_chat_screen.dart';

/// Settings hub for a single chat. Loads the chat and current member on entry
/// and shows relevant sections based on permissions.
class ChatSettingsScreen extends StatefulWidget {
  final int chatId;
  final String? initialTab;

  const ChatSettingsScreen({super.key, required this.chatId, this.initialTab});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  late Future<_ChatSettingsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    if (widget.initialTab == 'members') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatMembersScreen(chatId: widget.chatId),
            ),
          );
        }
      });
    }
  }

  Future<_ChatSettingsData> _load() async {
    final api = AppManager.instance.api;
    final chat = await api.chat(widget.chatId);
    final me = await api.selfMember(widget.chatId);
    return _ChatSettingsData(chat: chat, me: me);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _createInviteLink() async {
    try {
      final result = await AppManager.instance.api.createInviteLink(
        widget.chatId,
      );
      final link = 'qutty.app/invite/${result['code']}';
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _InviteLinkDialog(link: link),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatSettingsLeaveTitle),
        content: Text(l10n.chatSettingsLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.chatSettingsLeave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppManager.instance.api.leaveChat(widget.chatId);
      await AppManager.instance.refreshChats();
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _confirmDelete(_ChatSettingsData data) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatSettingsDeleteTitle(data.chat.displayName)),
        content: Text(l10n.chatSettingsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppManager.instance.api.deleteChat(widget.chatId);
      await AppManager.instance.refreshChats();
      if (!mounted) return;
      context.go('/');
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatSettingsTitle)),
      body: FutureBuilder<_ChatSettingsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingCenter();
          }
          if (snapshot.hasError) {
            return StatusPlaceholder(
              icon: Icons.error_outline,
              title: l10n.chatSettingsLoadFailed,
              message: snapshot.error.toString(),
              action: FilledButton(
                onPressed: _refresh,
                child: Text(l10n.commonTryAgain),
              ),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _Body(
              data: data,
              scheme: scheme,
              onMembers: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatMembersScreen(chatId: widget.chatId),
                ),
              ),
              onAccessControl: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AclScreen(chat: data.chat)),
              ),
              onEditProfile: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => EditChatScreen(chat: data.chat),
                    ),
                  )
                  .then((_) => _refresh()),
              onInvite: _createInviteLink,
              onLeave: data.chat.chatType == 'dm' || data.me.role == 'creator'
                  ? null
                  : _confirmLeave,
              onDelete: data.me.role == 'creator'
                  ? () => _confirmDelete(data)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _ChatSettingsData {
  final ChatInfo chat;
  final MemberInfo me;
  const _ChatSettingsData({required this.chat, required this.me});
}

class _Body extends StatelessWidget {
  final _ChatSettingsData data;
  final ColorScheme scheme;
  final VoidCallback onMembers;
  final VoidCallback onAccessControl;
  final VoidCallback onEditProfile;
  final VoidCallback onInvite;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const _Body({
    required this.data,
    required this.scheme,
    required this.onMembers,
    required this.onAccessControl,
    required this.onEditProfile,
    required this.onInvite,
    this.onLeave,
    this.onDelete,
  });

  bool get _canManage =>
      data.me.role == 'creator' ||
      data.me.role == 'admin' ||
      data.me.permissions.contains('administrator');

  bool get _canCreateInvite =>
      data.me.role == 'creator' || data.me.permissions.contains('add_admins');

  @override
  Widget build(BuildContext context) {
    final chat = data.chat;
    final l10n = context.l10n;
    final isDm = chat.chatType == 'dm';
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Avatar(
                  baseUrl: AppManager.instance.api.baseUrl,
                  imageUrl: chat.avatarUrl,
                  displayName: chat.displayName,
                  radius: 36,
                  fallbackIcon: iconForChatType(chat.chatType),
                ),
                const SizedBox(height: 12),
                Text(
                  chat.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (chat.handles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${chat.handles.first}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 10),
                StatusBadge(
                  label: labelForRole(data.me.role, l10n: l10n),
                  color: scheme.primary,
                  icon: iconForChatType(chat.chatType),
                ),
              ],
            ),
          ),
        ),
        if (!isDm) ...[
          SettingsSection(
            title: l10n.chatSettingsProfileSection,
            children: [
              if (_canManage)
                SettingsTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: l10n.settingsEditProfile,
                  subtitle: l10n.chatSettingsEditProfileSubtitle,
                  onTap: onEditProfile,
                ),
              SettingsTile(
                leading: const Icon(Icons.link_outlined),
                title: l10n.chatSettingsCreateInvite,
                subtitle: l10n.chatSettingsCreateInviteSubtitle,
                onTap: _canCreateInvite ? onInvite : null,
                enabled: _canCreateInvite,
              ),
            ],
          ),
          SettingsSection(
            title: l10n.chatSettingsPermissions,
            children: [
              SettingsTile(
                leading: const Icon(Icons.people_outline),
                title: l10n.chatSettingsMembers,
                subtitle: l10n.chatSettingsMembersSubtitle,
                onTap: onMembers,
              ),
              SettingsTile(
                leading: const Icon(Icons.tune_outlined),
                title: l10n.chatSettingsAccessControl,
                subtitle: l10n.chatSettingsAccessControlSubtitle,
                onTap: data.me.role == 'creator' ? onAccessControl : null,
                enabled: data.me.role == 'creator',
              ),
            ],
          ),
        ] else ...[
          SettingsSection(
            title: l10n.chatSettingsDirectMessage,
            children: [
              SettingsTile(
                leading: const Icon(Icons.person_outline),
                title: l10n.chatSettingsOpenContactProfile,
                onTap: chat.peerUserId == null
                    ? null
                    : () => context.push('/user/${chat.peerUserId}'),
              ),
            ],
          ),
        ],
        if (onLeave != null || onDelete != null)
          SettingsSection(
            title: l10n.chatSettingsDangerZone,
            children: [
              if (onLeave != null)
                SettingsTile(
                  leading: const Icon(Icons.logout),
                  title: l10n.chatSettingsLeaveTile,
                  destructive: true,
                  onTap: onLeave,
                ),
              if (onDelete != null)
                SettingsTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: l10n.chatSettingsDeleteTile,
                  subtitle: l10n.chatSettingsDeleteTileSubtitle,
                  destructive: true,
                  onTap: onDelete,
                ),
            ],
          ),
      ],
    );
  }
}

class _InviteLinkDialog extends StatelessWidget {
  final String link;
  const _InviteLinkDialog({required this.link});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.chatSettingsInviteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chatSettingsInviteBody,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(link, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: link)),
          child: Text(l10n.commonCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
