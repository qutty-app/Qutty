import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';

class CreateChatScreen extends StatefulWidget {
  final String chatType;

  const CreateChatScreen({super.key, required this.chatType});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final manager = AppManager.instance;
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  PlatformFile? avatar;
  bool busy = false;
  String? error;

  bool get isChannel => widget.chatType == 'channel';

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted || result == null || result.files.single.bytes == null) return;
    setState(() => avatar = result.files.single);
  }

  Future<void> create() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      setState(() => error = context.l10n.createChatNameRequired);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await manager.api.createChat(
        name,
        '',
        usernameController.text.trim(),
        chatType: widget.chatType,
      );
      if (avatar != null) {
        await manager.api.updateChatAvatar(id, avatar!);
      }
      if (mounted) context.pop(true);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final title = isChannel
        ? l10n.createChatNewChannel
        : l10n.createChatNewChat;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: l10n.createChatClose,
          onPressed: busy ? null : () => context.pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            onPressed: busy ? null : create,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              isChannel
                  ? l10n.createChatCreateChannel
                  : l10n.createChatCreateChat,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Center(
            child: Stack(
              children: [
                avatar == null
                    ? Avatar(
                        baseUrl: manager.api.baseUrl,
                        displayName: nameController.text,
                        radius: 52,
                        fallbackIcon: isChannel
                            ? Icons.campaign_outlined
                            : Icons.forum_outlined,
                      )
                    : CircleAvatar(
                        radius: 52,
                        backgroundImage: MemoryImage(avatar!.bytes!),
                      ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: l10n.createChatChooseAvatar,
                    onPressed: busy ? null : pickAvatar,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
              ],
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
            controller: nameController,
            enabled: !busy,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.createChatDisplayName,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: usernameController,
            enabled: !busy,
            decoration: InputDecoration(
              labelText: l10n.createChatUsernameOptional,
              helperText: l10n.createChatUsernameOptionalHelper,
              prefixIcon: const Icon(Icons.alternate_email),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
    );
  }
}
