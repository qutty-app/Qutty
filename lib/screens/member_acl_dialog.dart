import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';

/// Per-member permission editor.
class MemberAclDialog extends StatefulWidget {
  final int chatId;
  final MemberInfo member;
  final List<String> chatPermissions;

  const MemberAclDialog({
    super.key,
    required this.chatId,
    required this.member,
    required this.chatPermissions,
  });

  @override
  State<MemberAclDialog> createState() => _MemberAclDialogState();
}

class _MemberAclDialogState extends State<MemberAclDialog> {
  /// The permission keys this dialog can toggle, in display order. Labels come
  /// from the localizations so the same list works in every language.
  static const _permissionKeys = <String>[
    'write_messages',
    'delete_others_messages',
    'edit_others_messages',
    'restrict_users',
    'edit_profile',
    'add_admins',
  ];

  late final Set<String> _selected = widget.member.permissions.toSet();
  late String _role = widget.member.role;
  bool _busy = false;

  bool get _isCreator => widget.member.role == 'creator';

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AppManager.instance.api.updateMemberPermissions(
        widget.chatId,
        widget.member.userId,
        _selected.toList(),
        role: _role,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _labelFor(String key, AppLocalizations l10n) => switch (key) {
    'write_messages' => l10n.permissionWriteMessages,
    'delete_others_messages' => l10n.permissionDeleteOthersMessages,
    'edit_others_messages' => l10n.aclEditMessages,
    'restrict_users' => l10n.permissionRestrictUsers,
    'edit_profile' => l10n.permissionEditProfile,
    'add_admins' => l10n.permissionAddAdmins,
    _ => l10n.aclEditMessages,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool locked = _isCreator;
    final isAdmin = _role == 'admin';
    final isMember = _role == 'member';
    final isRestricted = _role == 'restricted';

    return AlertDialog(
      title: Text(widget.member.displayName),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (locked)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.membersOwnerLocked,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'restricted',
                    label: Text(l10n.roleRestricted),
                  ),
                  ButtonSegment(value: 'member', label: Text(l10n.roleMember)),
                  ButtonSegment(value: 'admin', label: Text(l10n.roleAdmin)),
                ],
                selected: {locked ? 'admin' : _role},
                onSelectionChanged: locked || _busy
                    ? null
                    : (value) => setState(() => _role = value.first),
              ),
              const SizedBox(height: 16),
              for (final key in _permissionKeys) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_labelFor(key, l10n)),
                  value: isMember
                      ? widget.chatPermissions.contains(key)
                      : isAdmin
                      ? _selected.contains(key) ||
                            widget.chatPermissions.contains(key)
                      : isRestricted
                      ? _selected.contains(key) &&
                            widget.chatPermissions.contains(key)
                      : _selected.contains(key),
                  onChanged:
                      locked ||
                          _busy ||
                          isMember ||
                          (isAdmin && widget.chatPermissions.contains(key)) ||
                          (isRestricted &&
                              !widget.chatPermissions.contains(key))
                      ? null
                      : (value) {
                          // Members always inherit chat-level defaults.
                          if (isMember) return;
                          if (isAdmin && widget.chatPermissions.contains(key)) {
                            return;
                          }
                          if (isRestricted &&
                              !widget.chatPermissions.contains(key) &&
                              value) {
                            return;
                          }
                          setState(() {
                            if (value) {
                              _selected.add(key);
                            } else {
                              _selected.remove(key);
                            }
                          });
                        },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy || locked ? null : _save,
          child: Text(_busy ? l10n.commonSaving : l10n.commonSave),
        ),
      ],
    );
  }
}

/// Convenience helpers re-exported to keep imports tidy in callers.
class MemberAclHelpers {
  static Future<void> copyInviteLink(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.chatSettingsInviteCopied)),
    );
  }

  static Future<void> openMemberProfile(BuildContext context, int userId) {
    return GoRouter.of(context).push('/user/$userId');
  }
}
