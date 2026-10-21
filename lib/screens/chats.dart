import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/join_link.dart';
import 'package:qutty/api/ugc_link.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/adaptive.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/api/ugc_tags.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final manager = AppManager.instance;
  final searchController = TextEditingController();
  SearchResults? searchResults;
  JoinLink? searchJoinLink;
  bool searching = false;
  String? error;

  @override
  void initState() {
    super.initState();
    manager.addListener(handlePendingLink);
    handlePendingLink();
  }

  Future<void> handlePendingLink() async {
    if (manager.pendingDeepLink == null || !manager.isLoggedIn) return;
    try {
      final value = manager.takePendingDeepLink();
      if (!mounted || value == null) return;
      // A sticker pack has a page of its own; everything else here is an
      // invite, which is previewed and joined from one screen.
      final packId = parseUgcShareLink(value);
      if (packId != null) {
        context.push('/sticker/$packId');
        return;
      }
      context.push('/join-preview?link=${Uri.encodeComponent(value)}');
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  Future<void> search(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          searchResults = null;
          searchJoinLink = null;
          searching = false;
        });
      }
      return;
    }
    final joinLink = parseJoinLink(query);
    setState(() => searching = true);
    try {
      SearchResults results;
      if (query.startsWith("@")) {
        final results1 = await manager.api.search(query);
        final results2 = await manager.api.search(query.substring(1));
        results = SearchResults(
          chats: results1.chats + results2.chats,
          users: results1.users + results2.users,
        );
      } else {
        results = await manager.api.search(query);
      }
      if (mounted && searchController.text.trim() == query) {
        setState(() {
          searchResults = results;
          if (query.startsWith("@")) {
            searchJoinLink = null;
          } else {
            searchJoinLink = joinLink;
          }
          searching = false;
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          error = exception.message;
          searching = false;
        });
      }
    }
  }

  Future<void> createChat() async {
    await context.push('/create-chat?type=chat');
    await manager.refreshChats();
  }

  Future<void> createChannel() async {
    await context.push('/create-chat?type=channel');
    await manager.refreshChats();
  }

  void openChat(int id) {
    openChatRoute(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            IconButton(
              tooltip: l10n.chatsProfileTooltip,
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.person_outline),
            ),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.chatsSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: CustomExpandableFab(
        distance: 60.0,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chatsNewChannel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                heroTag: 'channel_fab',
                onPressed: createChannel,
                child: const Icon(Icons.campaign_outlined),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chatsNewChat,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                heroTag: 'chat_fab',
                onPressed: createChat,
                child: const Icon(Icons.forum_outlined),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, child) {
          return RefreshIndicator(
            onRefresh: manager.refreshChats,
            child: searchResults != null
                ? _SearchList(
                    results: searchResults!,
                    joinLink: searchJoinLink,
                    onJoinLinkTap: (link) => context.push(
                      '/join-preview?link=${Uri.encodeComponent(link.display)}',
                    ),
                    onChatTap: (id) => openChat(id),
                  )
                : manager.chats.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * .32),
                      const Icon(Icons.forum_outlined, size: 48),
                      const SizedBox(height: 12),
                      Center(child: Text(l10n.chatsEmptyTitle)),
                      const SizedBox(height: 8),
                      Center(child: Text(l10n.chatsEmptySubtitle)),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: manager.chats.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chat = manager.chats[index];
                      return ListTile(
                        leading: Avatar(
                          baseUrl: manager.api.baseUrl,
                          imageUrl: chat.avatarUrl,
                          displayName: chat.displayName,
                          fallbackIcon: chat.chatType == 'channel'
                              ? Icons.campaign_outlined
                              : Icons.forum_outlined,
                        ),
                        title: Text(chat.displayName),
                        subtitle: Text(
                          ugcPreviewText(
                            chat.lastMessageForDumbAssChatList.length > 40
                                ? '${chat.lastMessageForDumbAssChatList.substring(0, 38)}...'
                                : chat.lastMessageForDumbAssChatList,
                            context.l10n.ugcStickerPreview,
                          ),
                        ),
                        onTap: () => openChat(chat.id),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    manager.removeListener(handlePendingLink);
    searchController.dispose();
    super.dispose();
  }
}

class CustomExpandableFab extends StatefulWidget {
  final List<Widget> children;
  final double distance;

  const CustomExpandableFab({
    super.key,
    required this.children,
    this.distance = 60.0,
  });

  @override
  State<CustomExpandableFab> createState() => _CustomExpandableFabState();
}

class _CustomExpandableFabState extends State<CustomExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: widget.distance * (widget.children.length + 1),
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          ...List.generate(widget.children.length, (index) {
            return AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final double fabSizeDifference =
                    (56.0 - 40.0) / 2; // Adjusts center alignment difference
                final double stepDistance =
                    (widget.distance * (index + 1)) + fabSizeDifference;

                final double translateY =
                    -stepDistance * _expandAnimation.value;
                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: IgnorePointer(ignoring: !_open, child: child),
                  ),
                );
              },
              child: widget.children[index],
            );
          }),
          FloatingActionButton(
            onPressed: _toggle,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * math.pi / 4,
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchList extends StatelessWidget {
  final SearchResults results;
  final JoinLink? joinLink;
  final ValueChanged<int> onChatTap;
  final ValueChanged<JoinLink> onJoinLinkTap;
  const _SearchList({
    required this.results,
    required this.onChatTap,
    this.joinLink,
    required this.onJoinLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = results.chats.length + results.users.length;
    if (total == 0 && joinLink == null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(child: Text(l10n.chatsNoMatches)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: total + (joinLink == null ? 0 : 1),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (joinLink != null && index == 0) {
          return ListTile(
            leading: const Icon(Icons.link),
            title: Text(joinLink!.display),
            subtitle: Text(l10n.chatsPreviewAndJoin),
            onTap: () => onJoinLinkTap(joinLink!),
          );
        }
        final adjustedIndex = joinLink == null ? index : index - 1;
        if (adjustedIndex < results.chats.length) {
          final chat = results.chats[adjustedIndex];
          return ListTile(
            leading: Avatar(
              baseUrl: AppManager.instance.api.baseUrl,
              imageUrl: chat.avatarUrl,
              displayName: chat.displayName,
              fallbackIcon: Icons.forum_outlined,
            ),
            title: Text(chat.displayName),
            subtitle: Text(
              chat.handles.isEmpty ? chat.bio : '@${chat.handles.first}',
            ),
            onTap: () => onChatTap(chat.id),
          );
        }
        final user = results.users[adjustedIndex - results.chats.length];
        return ListTile(
          leading: Avatar(
            baseUrl: AppManager.instance.api.baseUrl,
            imageUrl: user.avatarUrl,
            displayName: user.displayName,
          ),
          title: Text(user.displayName),
          subtitle: Text(
            user.handles.isEmpty ? user.bio : '@${user.handles.first}',
          ),
          trailing: IconButton(
            tooltip: l10n.chatsMessageUser,
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () async {
              final id = await AppManager.instance.api.openDM(user.id);
              await AppManager.instance.refreshChats();
              if (context.mounted) onChatTap(id);
            },
          ),
        );
      },
    );
  }
}
