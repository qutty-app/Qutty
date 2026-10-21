import 'package:flutter/material.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qutty/widgets/avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final int chatid;
  const EditProfileScreen({super.key, required this.chatid});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final manager = AppManager.instance;
  late final TextEditingController name;
  late final TextEditingController bio;
  late final TextEditingController handle;
  bool busy = false;
  bool get ischat => widget.chatid != 0;
  int get chatid => widget.chatid;
  String? error;

  Future<void> pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await manager.updateAvatar(result.files.single);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> removeAvatar() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await manager.removeAvatar();
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: manager.profile?.displayName);
    bio = TextEditingController(text: manager.profile?.bio);
    handle = TextEditingController(
      text: manager.profile?.handles.isNotEmpty == true
          ? manager.profile?.handles.first
          : '',
    );
  }

  Future<void> save() async {
    final l10n = context.l10n;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (name.text.trim().isEmpty) {
        throw ApiException(0, l10n.editProfileNameEmpty);
      }
      String hdl;
      if (handle.text.trim() == "_") {
        throw ApiException(0, l10n.editProfileHandleReserved);
      } else if (handle.text.trim().isEmpty) {
        hdl = "_";
      } else {
        hdl = handle.text.trim();
      }
      if (ischat) {
        await manager.api.updateChat(
          chatid,
          bio: bio.text.trim(),
          displayName: name.text.trim(),
          handle: hdl,
        );
      } else {
        await manager.updateProfile(name.text.trim(), bio.text.trim(), hdl);
      }
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
    final profile = manager.profile;
    final hasAvatar = profile?.avatarUrl.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsEditProfile)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Avatar(
                    baseUrl: manager.api.baseUrl,
                    imageUrl: profile?.avatarUrl ?? '',
                    displayName: profile?.displayName ?? '',
                    radius: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (profile?.handles.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${profile!.handles.first}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (profile?.bio.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            profile!.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.editProfileChangeAvatar,
                        onPressed: busy ? null : pickAvatar,
                        icon: const Icon(Icons.photo_camera_outlined),
                      ),
                      if (hasAvatar)
                        IconButton(
                          tooltip: l10n.editProfileRemoveAvatar,
                          onPressed: busy ? null : removeAvatar,
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: l10n.createChatDisplayName),
            maxLength: 32,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: handle,
            decoration: InputDecoration(labelText: l10n.commonHandle),
            maxLength: 32,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: bio,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(labelText: l10n.editProfileBio),
            maxLength: 200,
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy ? null : save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.commonSaveChanges),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    handle.dispose();
    super.dispose();
  }
}
