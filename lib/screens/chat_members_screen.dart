import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/settings_ui.dart';

import 'member_acl_dialog.dart';

/// Lists every member of a chat and exposes per-member management for users
/// who have permission to do so.
class ChatMembersScreen extends StatefulWidget {
  final int chatId;
  const ChatMembersScreen({super.key, required this.chatId});

  @override
  State<ChatMembersScreen> createState() => _ChatMembersScreenState();
}

class _ChatMembersScreenState extends State<ChatMembersScreen> {
  Future<_MembersData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MembersData> _load() async {
    final api = AppManager.instance.api;
    final results = await Future.wait([
      api.chat(widget.chatId),
      api.members(widget.chatId),
      api.selfMember(widget.chatId),
    ]);
    return _MembersData(
      chat: results[0] as ChatInfo,
      members: results[1] as List<MemberInfo>,
      me: results[2] as MemberInfo,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openMemberActions(MemberInfo member, _MembersData data) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(member.displayName),
                subtitle: Text(labelForRole(member.role, l10n: l10n)),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(l10n.membersViewProfile),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/user/${member.userId}');
                },
              ),
              if (_canTransfer(data, member))
                ListTile(
                  leading: const Icon(Icons.swap_horiz_outlined),
                  title: Text(l10n.membersGiveChat(data.chat.displayName)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _transferChat(member, data);
                  },
                ),
              if (_canManage(data) && member.role != 'creator')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(l10n.membersManagePermissions),
                  onTap: () async {
                    Navigator.pop(context);
                    await showDialog<void>(
                      context: context,
                      builder: (_) => MemberAclDialog(
                        chatId: widget.chatId,
                        member: member,
                        chatPermissions: data.chat.permissions,
                      ),
                    );
                    await _refresh();
                  },
                ),
              if (_canManage(data) && member.role != 'creator')
                ListTile(
                  leading: Icon(
                    Icons.person_remove_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    l10n.membersRemoveFromChat,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _confirmRemove(member, data);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(MemberInfo member, _MembersData data) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.membersRemoveTitle(member.displayName)),
        content: Text(l10n.membersRemoveBody),
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
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      // The backend uses DELETE /chats/{id}/members/{user_id} via KickMemberHandler.
      // We piggy-back on deleteSession-style API by reusing the manager's existing
      // http client. There is no dedicated kick client method, so call it inline.
      await _kickMember(data.chat.id, member.userId);
      await _refresh();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _kickMember(int chatId, int userId) async {
    await AppManager.instance.api.kickMember(chatId, userId);
  }

  Future<void> _transferChat(MemberInfo member, _MembersData data) async {
    final acknowledged =
        await showDialog<bool>(
          context: context,
          builder: (context) => _TransferWarningDialog(
            member: member,
            chatName: data.chat.displayName,
          ),
        ) ??
        false;
    if (!acknowledged || !mounted) return;

    final password = await showDialog<String>(
      context: context,
      builder: (context) => _TransferPasswordDialog(
        chatName: data.chat.displayName,
        username: _username(member),
      ),
    );
    if (password == null || !mounted) return;
    try {
      await AppManager.instance.api.transferChat(
        widget.chatId,
        member.userId,
        password,
      );
      await AppManager.instance.refreshChats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.membersOwnershipGiven(member.displayName)),
        ),
      );
      await _refresh();
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  String _username(MemberInfo member) =>
      member.username.isEmpty ? member.displayName : member.username;

  bool _canTransfer(_MembersData data, MemberInfo member) =>
      data.chat.chatType != 'dm' &&
      data.me.role == 'creator' &&
      member.role == 'admin';

  bool _canManage(_MembersData data) {
    final me = data.me;
    return me.role == 'creator' ||
        me.role == 'admin' ||
        me.permissions.contains('add_admins');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle)),
      body: FutureBuilder<_MembersData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingCenter();
          }
          if (snapshot.hasError) {
            return StatusPlaceholder(
              icon: Icons.error_outline,
              title: l10n.membersLoadFailed,
              message: snapshot.error.toString(),
              action: FilledButton(
                onPressed: _refresh,
                child: Text(l10n.commonTryAgain),
              ),
            );
          }
          final data = snapshot.data!;
          final sorted = [...data.members]
            ..sort((a, b) {
              final order = {
                'creator': 0,
                'admin': 1,
                'member': 2,
                'restricted': 3,
              };
              final cmp = (order[a.role] ?? 9).compareTo(order[b.role] ?? 9);
              return cmp != 0 ? cmp : a.displayName.compareTo(b.displayName);
            });
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = sorted[index];
                return ListTile(
                  onTap: () => context.push('/user/${member.userId}'),
                  leading: Avatar(
                    baseUrl: AppManager.instance.api.baseUrl,
                    imageUrl: member.avatarUrl,
                    displayName: member.displayName,
                  ),
                  title: Row(
                    children: [
                      Flexible(child: Text(member.displayName)),
                      if (member.userId == data.me.userId) ...[
                        const SizedBox(width: 6),
                        StatusBadge(
                          label: l10n.membersYou,
                          color: Colors.indigo,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(labelForRole(member.role, l10n: l10n)),
                  trailing: IconButton(
                    tooltip: l10n.membersMore,
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _openMemberActions(member, data),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MembersData {
  final ChatInfo chat;
  final List<MemberInfo> members;
  final MemberInfo me;
  const _MembersData({
    required this.chat,
    required this.members,
    required this.me,
  });
}

class _TransferWarningDialog extends StatefulWidget {
  final MemberInfo member;
  final String chatName;

  const _TransferWarningDialog({required this.member, required this.chatName});

  @override
  State<_TransferWarningDialog> createState() => _TransferWarningDialogState();
}

class _TransferWarningDialogState extends State<_TransferWarningDialog> {
  bool acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final username = widget.member.username.isEmpty
        ? widget.member.displayName
        : widget.member.username;
    return AlertDialog(
      title: Text(l10n.membersTransferTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.membersTransferAttention,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Avatar(
                baseUrl: AppManager.instance.api.baseUrl,
                imageUrl: widget.member.avatarUrl,
                displayName: widget.member.displayName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.member.displayName),
                    Text(l10n.membersTransferUsername(username)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: acknowledged,
            onChanged: (value) => setState(() => acknowledged = value ?? false),
            title: Text(
              l10n.membersTransferAcknowledge(widget.chatName, username),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: acknowledged ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.commonContinue),
        ),
      ],
    );
  }
}

class _TransferPasswordDialog extends StatefulWidget {
  final String chatName;
  final String username;

  const _TransferPasswordDialog({
    required this.chatName,
    required this.username,
  });

  @override
  State<_TransferPasswordDialog> createState() =>
      _TransferPasswordDialogState();
}

class _TransferPasswordDialogState extends State<_TransferPasswordDialog> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.membersEnterPassword),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(labelText: l10n.password),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            l10n.membersGiveConfirm(widget.chatName, widget.username),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (controller.text.isNotEmpty) Navigator.pop(context, controller.text);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
