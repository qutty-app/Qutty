import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp _linkPattern = RegExp(r'https?://[^\s<>"()]+');

class ProfileScreen extends StatelessWidget {
  final int id;
  final String type;
  const ProfileScreen({super.key, required this.id, required this.type});

  Future<Map<String, dynamic>> _loadProfileData() async {
    final manager = AppManager.instance;
    final profile = manager.profile!;

    if (type != "user" && type != "chat") {
      throw ArgumentError('type must be either "user" or "chat"');
    }

    // Sentinel for "the server did not give us a handle"; compared against below
    // to decide whether to render the @handle row, so it must stay stable and
    // must never be a value a localized string could produce.
    const missing = 'N/A';
    final isCurrentUser = type == "user" && profile.id == id;
    String dname = missing;
    String handle = missing;
    String avatarUrl = "";
    String bio = profile.bio;
    bool isChatAdmin = false;
    int? chatId;
    final int? userId = type == "user" ? id : null;

    if (isCurrentUser) {
      avatarUrl = profile.avatarUrl;
      dname = profile.displayName;
      handle = profile.handles.isNotEmpty ? profile.handles.first : missing;
    } else if (type == "chat") {
      final chat = await manager.api.chat(id);
      avatarUrl = chat.avatarUrl;
      dname = chat.displayName;
      handle = chat.handles.isNotEmpty ? chat.handles.first : missing;
      bio = chat.bio;
      try {
        final member = await manager.api.selfMember(id);
        isChatAdmin =
            member.role == 'creator' ||
            member.role == 'admin' ||
            member.permissions.contains('administrator');
      } on ApiException catch (exception) {
        if (exception.statusCode != 404) rethrow;
      }
    } else {
      final user = await manager.api.user(id);
      avatarUrl = user.avatarUrl;
      dname = user.displayName;
      handle = user.handles.isNotEmpty ? user.handles.first : missing;
      bio = user.bio;
    }

    chatId ??= type == 'chat'
        ? id
        : manager.chats
              .where((chat) => chat.chatType == 'dm' && chat.peerUserId == id)
              .firstOrNull
              ?.id;

    List<MessageInfo> messages = const [];
    if (chatId != null) {
      try {
        messages = await manager.api.messages(chatId);
      } on ApiException catch (exception) {
        if (exception.statusCode != 404) rethrow;
      }
    }

    return {
      'dname': dname,
      'handle': handle,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'chatId': chatId,
      'userId': userId,
      'messages': messages,
      'isCurrentUser': isCurrentUser,
      'isChatAdmin': isChatAdmin,
    };
  }

  Future<void> openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileUnableToOpen)),
        );
      }
    }
  }

  String sizeLabel(int size) => size < 1024 * 1024
      ? '${(size / 1024).ceil()} KB'
      : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final dname = data?['dname'] ?? l10n.settingsEditProfile;
        final isCurrentUser = data?['isCurrentUser'] ?? false;
        final isChatAdmin = data?['isChatAdmin'] ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text(dname),
            actions: [
              if (isCurrentUser || (type == "chat" && isChatAdmin))
                IconButton(
                  tooltip: l10n.commonSettings,
                  onPressed: () => context.push(
                    type == "user" ? '/settings' : '/chat/$id/settings',
                  ),
                  icon: const Icon(Icons.settings_outlined),
                ),
            ],
          ),
          body: () {
            final data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(l10n.profileError(snapshot.error.toString())),
              );
            }
            if (data == null) {
              return Center(child: Text(l10n.profileNotFound));
            }

            final handle = data['handle'] as String;
            final avatarUrl = data['avatarUrl'] as String;
            final bio = data['bio'] as String;
            final chatId = data['chatId'] as int?;
            final userId = data['userId'] as int?;
            final messages =
                (data['messages'] as List<MessageInfo>?) ?? const [];

            final media = <MessageInfo>[];
            final gifs = <MessageInfo>[];
            final files = <MessageInfo>[];
            final linkSet = <String>{};
            for (final message in messages) {
              final hasAttachment = message.attachmentKey.isNotEmpty;
              final contentType = message.attachmentType.toLowerCase();
              final name = message.attachmentName.toLowerCase();
              final isGif =
                  hasAttachment &&
                  (contentType == 'image/gif' || name.endsWith('.gif'));
              if (isGif) {
                gifs.add(message);
              } else if (hasAttachment &&
                  (contentType.startsWith('image/') ||
                      contentType.startsWith('video/'))) {
                media.add(message);
              } else if (hasAttachment) {
                files.add(message);
              }
              for (final match in _linkPattern.allMatches(message.text)) {
                linkSet.add(match.group(0)!);
              }
            }
            final links = linkSet.toList(growable: false);

            final header = Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Avatar(
                        baseUrl: manager.api.baseUrl,
                        imageUrl: avatarUrl,
                        displayName: dname,
                        radius: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        dname,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (handle != "N/A") ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '@$handle',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(bio, textAlign: TextAlign.center),
                    ],
                    if (manager.developerInfo &&
                        (chatId != null || userId != null)) ...[
                      const SizedBox(height: 16),
                      if (chatId != null) Text(l10n.profileChatId(chatId)),
                      if (userId != null) Text(l10n.profileUserId(userId)),
                    ],
                  ],
                ),
              ),
            );

            return SafeArea(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const Divider(height: 1),
                    TabBar(
                      tabs: [
                        Tab(text: l10n.profileTabMedia(media.length)),
                        Tab(text: l10n.profileTabGifs(gifs.length)),
                        Tab(text: l10n.profileTabLinks(links.length)),
                        Tab(text: l10n.profileTabFiles(files.length)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _AttachmentGrid(
                            messages: media,
                            emptyText: l10n.profileNoMedia,
                            onTap: (message) =>
                                openUrl(context, message.attachmentUrl),
                            scheme: scheme,
                          ),
                          _AttachmentGrid(
                            messages: gifs,
                            emptyText: l10n.profileNoGifs,
                            onTap: (message) =>
                                openUrl(context, message.attachmentUrl),
                            scheme: scheme,
                          ),
                          _LinksList(
                            links: links,
                            emptyText: l10n.profileNoLinks,
                            onTap: (link) => openUrl(context, link),
                            scheme: scheme,
                          ),
                          _FilesList(
                            messages: files,
                            emptyText: l10n.profileNoFiles,
                            onTap: (message) =>
                                openUrl(context, message.attachmentUrl),
                            sizeLabel: sizeLabel,
                            scheme: scheme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }(),
        );
      },
    );
  }
}

class _AttachmentGrid extends StatelessWidget {
  final List<MessageInfo> messages;
  final String emptyText;
  final ValueChanged<MessageInfo> onTap;
  final ColorScheme scheme;

  const _AttachmentGrid({
    required this.messages,
    required this.emptyText,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final type = message.attachmentType.toLowerCase();
        final name = message.attachmentName.toLowerCase();
        final isSvg = type == 'image/svg+xml' || name.endsWith('.svg');
        final isImage = isSvg || type.startsWith('image/');
        return GestureDetector(
          onTap: () => onTap(message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isSvg
                ? SvgPicture.network(
                    message.attachmentUrl,
                    fit: BoxFit.cover,
                    placeholderBuilder: (_) =>
                        ColoredBox(color: scheme.surfaceContainerHighest),
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : isImage
                ? Image.network(
                    message.attachmentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.play_circle_outline),
                  ),
          ),
        );
      },
    );
  }
}

class _LinksList extends StatelessWidget {
  final List<String> links;
  final String emptyText;
  final ValueChanged<String> onTap;
  final ColorScheme scheme;

  const _LinksList({
    required this.links,
    required this.emptyText,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(link),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => onTap(link),
        );
      },
    );
  }
}

class _FilesList extends StatelessWidget {
  final List<MessageInfo> messages;
  final String emptyText;
  final ValueChanged<MessageInfo> onTap;
  final ColorScheme scheme;
  final String Function(int) sizeLabel;

  const _FilesList({
    required this.messages,
    required this.emptyText,
    required this.onTap,
    required this.scheme,
    required this.sizeLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(message.attachmentName),
          subtitle: Text(sizeLabel(message.attachmentSize)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => onTap(message),
        );
      },
    );
  }
}
