import 'package:flutter/material.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/avatar.dart';

/// Asks which conversation a message (or a selection of messages) should be
/// forwarded to.
///
/// Returns the chosen chat, or null when the dialog is dismissed. The list is
/// filtered by a search field and rendered like the chat list, so a destination
/// is picked the same way a chat is opened; [excludeChatId] keeps the ChatInfo
/// the messages already live in out of the results when the caller does not
/// want a same-chat forward.
Future<ChatInfo?> showForwardPicker(
  BuildContext context, {
  required List<ChatInfo> chats,
  required String baseUrl,
  int? excludeChatId,
}) {
  return showDialog<ChatInfo>(
    context: context,
    builder: (context) => _ForwardPickerDialog(
      chats: chats.where((chat) => chat.id != excludeChatId).toList(),
      baseUrl: baseUrl,
    ),
  );
}

class _ForwardPickerDialog extends StatefulWidget {
  const _ForwardPickerDialog({required this.chats, required this.baseUrl});

  final List<ChatInfo> chats;
  final String baseUrl;

  @override
  State<_ForwardPickerDialog> createState() => _ForwardPickerDialogState();
}

class _ForwardPickerDialogState extends State<_ForwardPickerDialog> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// Chats whose name or handle matches the query, case-insensitively. An empty
  /// query keeps every chat.
  List<ChatInfo> get _filtered {
    final query = search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.chats;
    return widget.chats.where((chat) {
      if (chat.displayName.toLowerCase().contains(query)) return true;
      return chat.handles.any((handle) => handle.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chats = _filtered;
    return AlertDialog(
      title: Text(l10n.chatForwardTitle),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.chatForwardSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: chats.isEmpty
                  ? Center(child: Text(l10n.chatForwardNoChats))
                  : ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ListTile(
                          leading: Avatar(
                            baseUrl: widget.baseUrl,
                            imageUrl: chat.avatarUrl,
                            displayName: chat.displayName,
                            fallbackIcon: chat.chatType == 'channel'
                                ? Icons.campaign_outlined
                                : Icons.forum_outlined,
                          ),
                          title: Text(chat.displayName),
                          onTap: () => Navigator.of(context).pop(chat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}
