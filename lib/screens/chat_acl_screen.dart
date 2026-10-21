import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';

/// Configures the default permission mask for a chat.
class AclScreen extends StatefulWidget {
  final ChatInfo chat;
  const AclScreen({super.key, required this.chat});

  @override
  State<AclScreen> createState() => _AclScreenState();
}

class _AclScreenState extends State<AclScreen> {
  /// Titles are resolved through [l10n] rather than stored, so the map only has
  /// to name the permission key and its icon.
  static const _permissionIcons = <String, IconData>{
    'write_messages': Icons.send_outlined,
    'delete_others_messages': Icons.delete_sweep_outlined,
    'edit_others_messages': Icons.edit_note_outlined,
    'restrict_users': Icons.person_remove_outlined,
    'edit_profile': Icons.edit_outlined,
    'add_admins': Icons.admin_panel_settings_outlined,
  };

  late final Set<String> _selected = widget.chat.permissions.toSet();
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AppManager.instance.api.updateChatPermissions(
        widget.chat.id,
        _selected.toList(),
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

  /// The label and explanation for a permission key, in the active locale.
  _PermissionDefinition _describe(String key, AppLocalizations l10n) =>
      switch (key) {
        'write_messages' => _PermissionDefinition(
          l10n.permissionWriteMessages,
          l10n.permissionWriteMessagesDescription,
          Icons.send_outlined,
        ),
        'delete_others_messages' => _PermissionDefinition(
          l10n.permissionDeleteOthersMessages,
          l10n.permissionDeleteOthersMessagesDescription,
          Icons.delete_sweep_outlined,
        ),
        'edit_others_messages' => _PermissionDefinition(
          l10n.permissionEditOthersMessages,
          l10n.permissionEditOthersMessagesDescription,
          Icons.edit_note_outlined,
        ),
        'restrict_users' => _PermissionDefinition(
          l10n.permissionRestrictUsers,
          l10n.permissionRestrictUsersDescription,
          Icons.person_remove_outlined,
        ),
        'edit_profile' => _PermissionDefinition(
          l10n.permissionEditProfile,
          l10n.permissionEditProfileDescription,
          Icons.edit_outlined,
        ),
        'add_admins' => _PermissionDefinition(
          l10n.permissionAddAdmins,
          l10n.permissionAddAdminsDescription,
          Icons.admin_panel_settings_outlined,
        ),
        _ => _PermissionDefinition(
          l10n.aclEditMessages,
          l10n.aclEditMessagesDescription,
          Icons.edit_note_outlined,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final available = <String>{
      ..._permissionIcons.keys,
      if (widget.chat.chatType == 'channel') 'edit_others_messages',
    }.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatSettingsAccessControl),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              l10n.aclDefaultPermissions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              l10n.aclDescription,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < available.length; i++) ...[
                    _PermissionTile(
                      definition: _describe(available[i], l10n),
                      value: _selected.contains(available[i]),
                      enabled: !_busy,
                      onChanged: (value) => setState(() {
                        if (value) {
                          _selected.add(available[i]);
                        } else {
                          _selected.remove(available[i]);
                        }
                      }),
                    ),
                    if (i < available.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_busy ? l10n.commonSaving : l10n.aclSavePermissions),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDefinition {
  final String title;
  final String description;
  final IconData icon;
  const _PermissionDefinition(this.title, this.description, this.icon);
}

class _PermissionTile extends StatelessWidget {
  final _PermissionDefinition definition;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.definition,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      secondary: Icon(definition.icon),
      title: Text(definition.title),
      subtitle: Text(definition.description),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
