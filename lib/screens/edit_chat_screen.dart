import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/settings_ui.dart';

/// Edit the display name, handle, description and avatar of a chat.
class EditChatScreen extends StatefulWidget {
  final ChatInfo chat;
  const EditChatScreen({super.key, required this.chat});

  @override
  State<EditChatScreen> createState() => _EditChatScreenState();
}

class _EditChatScreenState extends State<EditChatScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.chat.displayName,
  );
  late final TextEditingController _bio = TextEditingController(
    text: widget.chat.bio,
  );
  late final TextEditingController _handle = TextEditingController(
    text: widget.chat.handles.isEmpty ? '' : widget.chat.handles.first,
  );
  late String _avatarUrl = widget.chat.avatarUrl;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _busy = true);
    try {
      final updated = await AppManager.instance.api.updateChatAvatar(
        widget.chat.id,
        result.files.single,
      );
      await AppManager.instance.refreshChats();
      if (mounted) setState(() => _avatarUrl = updated.avatarUrl);
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _busy = true);
    try {
      final updated = await AppManager.instance.api.removeChatAvatar(
        widget.chat.id,
      );
      await AppManager.instance.refreshChats();
      if (mounted) setState(() => _avatarUrl = updated.avatarUrl);
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AppManager.instance.api.updateChat(
        widget.chat.id,
        displayName: name,
        bio: _bio.text.trim(),
        handle: _handle.text.trim(),
      );
      await AppManager.instance.refreshChats();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final chat = widget.chat;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          chat.chatType == 'channel'
              ? l10n.editChatChannelSettings
              : l10n.chatSettingsTitle,
        ),
        actions: [
          IconButton(
            tooltip: l10n.commonSave,
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Avatar(
                  baseUrl: AppManager.instance.api.baseUrl,
                  imageUrl: _avatarUrl,
                  displayName: chat.displayName,
                  radius: 32,
                  fallbackIcon: iconForChatType(chat.chatType),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.editChatTapForPicture,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _busy ? null : _pickAvatar,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(
                              _avatarUrl.isEmpty
                                  ? l10n.editChatUpload
                                  : l10n.editChatReplace,
                            ),
                          ),
                          if (_avatarUrl.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _removeAvatar,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.commonRemove),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.commonDetails,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.commonName,
                    prefixIcon: const Icon(Icons.title_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TextField(
                  controller: _handle,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: l10n.commonHandle,
                    prefixIcon: const Icon(Icons.alternate_email),
                    helperText: l10n.editChatHandleHelper,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _bio,
                  enabled: !_busy,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.commonDescription,
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_busy ? l10n.commonSaving : l10n.commonSaveChanges),
            ),
          ),
        ],
      ),
    );
  }
}
