import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/api/join_link.dart';
import 'package:qutty/l10n/l10n.dart';

class JoinPreviewScreen extends StatefulWidget {
  final String rawLink;
  const JoinPreviewScreen({super.key, required this.rawLink});
  @override
  State<JoinPreviewScreen> createState() => _JoinPreviewScreenState();
}

class _JoinPreviewScreenState extends State<JoinPreviewScreen> {
  final manager = AppManager.instance;
  ChatInfo? chat;
  JoinLink? link;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    link = parseJoinLink(widget.rawLink);
    load();
  }

  Future<void> load() async {
    if (link == null) {
      setState(() => error = context.l10n.joinPreviewInvalidLink);
      return;
    }
    try {
      final value = await manager.api.previewJoin(link!);
      if (mounted) setState(() => chat = value);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  Future<void> join() async {
    if (link == null) return;
    setState(() => busy = true);
    try {
      final id = await manager.api.joinLink(
        link!.value,
        link!.type == JoinLinkType.handle,
      );
      await manager.refreshChats();
      if (mounted) context.go('/chat/$id');
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.message;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinPreviewTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: chat == null
              ? (error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(error!, textAlign: TextAlign.center),
                      ))
              : ListView(
                  padding: const EdgeInsets.all(28),
                  shrinkWrap: true,
                  children: [
                    Avatar(
                      baseUrl: AppManager.instance.api.baseUrl,
                      imageUrl: chat!.avatarUrl,
                      displayName: chat!.displayName,
                      radius: 44,
                      fallbackIcon: chat!.chatType == 'channel'
                          ? Icons.campaign_outlined
                          : Icons.forum_outlined,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        chat!.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (chat!.handles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Center(child: Text('@${chat!.handles.first}')),
                    ],
                    if (chat!.bio.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(chat!.bio, textAlign: TextAlign.center),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: busy ? null : join,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(
                        busy ? l10n.joinPreviewJoining : l10n.joinPreviewJoin,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: busy ? null : () => context.pop(),
                      child: Text(l10n.commonDismiss),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
