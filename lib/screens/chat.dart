import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/join_link.dart';
import 'package:qutty/api/ugc_link.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/adaptive.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/forward_picker.dart';
import 'package:qutty/widgets/markdown.dart';
import 'package:qutty/widgets/media_picker.dart';
import 'package:qutty/widgets/ugc.dart';
import 'package:qutty/widgets/ugc_composer.dart';
import 'package:qutty/widgets/ugc_popup.dart';
import 'package:qutty/widgets/ugc_share.dart';
import 'package:url_launcher/url_launcher.dart';

/// Entries of the message action menu opened by a right click or a tap.
enum _MessageAction { reply, copy, forward, select, delete }

/// Whether this build expects a mouse that can right-click.
///
/// On such a platform the message menu belongs to the secondary button alone,
/// and a long press on a sticker keeps its old meaning of starting
/// multi-select. Touch platforms have no secondary button, so there a long
/// press is the way into the menu.
bool get _hasContextMenuButton =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

class ChatScreen extends StatefulWidget {
  final int chatId;

  /// The message the screen should scroll to once the page is loaded, or null
  /// to open at the usual place. It is set when a chat is opened from a
  /// forwarded message so the original lands on screen.
  final int? focusMessageId;

  const ChatScreen({super.key, required this.chatId, this.focusMessageId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final manager = AppManager.instance;
  final composer = TextEditingController();
  final composerFocus = FocusNode();
  final scrollController = ScrollController();
  ChatInfo? chat;
  List<MessageInfo> messages = const [];
  String? error;
  PlatformFile? selectedFile;
  bool? isMember;
  bool canWrite = false;
  StreamSubscription<MessageInfo>? _messageSub;
  StreamSubscription<MessageChange>? _messageChangeSub;

  MediaPickerTab _pickerTab = MediaPickerTab.emoji;
  bool _pickerOpen = false;

  /// Set while a picked GIF is being downloaded and sent, so a second tap
  /// cannot queue the same GIF twice.
  bool _sendingGif = false;

  /// Multi-select state. While [_selectionMode] is on, tapping a message
  /// toggles its membership instead of opening the action menu, and the app
  /// bar is swapped for the selection actions.
  bool _selectionMode = false;
  final Set<int> _selectedMessageIds = {};

  /// Where the last pointer went down. It anchors the message action menu at
  /// the cursor, so a right click opens it like a desktop context menu.
  Offset _menuAnchor = Offset.zero;

  /// The message the composer is answering, or null when it is a fresh one.
  /// While set, the composer shows a quoted preview and the next send carries
  /// its id as `reply_to`.
  MessageInfo? _replyTarget;

  /// The message a jump is still owed to, taken from [ChatScreen.focusMessageId]
  /// and cleared once the scroll lands. While it is set the list is built in
  /// full so a target outside the viewport still exists to scroll to.
  int? _pendingFocusId;

  /// Anchors [_pendingFocusId]'s bubble for `Scrollable.ensureVisible`.
  final GlobalKey _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pendingFocusId = widget.focusMessageId;
    // The panel is dismissed by the composer taking focus back, which is the
    // same gesture that dismisses the keyboard, so there is nothing else to
    // watch for: the popup closes for touch, for a keyboard shortcut that
    // focuses the field, and for the user tapping straight into the text.
    composerFocus.addListener(_closePickerOnFocus);
    // Tells AppManager which conversation is on screen so an incoming message
    // for this chat does not also raise a notification.
    manager.setActiveChat(widget.chatId);
    _subscribeMessages();
    load();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      setState(() {
        messages = const [];
        _selectionMode = false;
        _selectedMessageIds.clear();
        _replyTarget = null;
        _pendingFocusId = widget.focusMessageId;
      });
      manager.setActiveChat(widget.chatId);
      _subscribeMessages();
      load();
    } else if (oldWidget.focusMessageId != widget.focusMessageId &&
        widget.focusMessageId != null) {
      // The same chat opened again on a different message: jump to it without
      // refetching the page.
      setState(() => _pendingFocusId = widget.focusMessageId);
      _focusPendingMessage();
    }
  }

  /// Listens for live traffic about this chat: new messages pushed over the
  /// websocket, and edits or deletions of messages already on screen.
  void _subscribeMessages() {
    _messageSub?.cancel();
    _messageSub = manager
        .subscribeMessages(widget.chatId)
        .listen(_appendMessage);
    _messageChangeSub?.cancel();
    _messageChangeSub = manager
        .subscribeMessageChanges(widget.chatId)
        .listen(_applyMessageChange);
  }

  void _appendMessage(MessageInfo message) {
    if (!mounted) return;
    if (message.chatId != widget.chatId) return;
    if (messages.any((existing) => existing.id == message.id)) return;
    final wasAtBottom = _isNearBottom;
    setState(() => messages = [...messages, message]);
    if (wasAtBottom) _scrollToBottom(animated: true);
    // A message that lands while the view is at the bottom is being read, so
    // advance this member's cursor; one that arrives while scrolled up is left
    // for the moment it is actually seen.
    final mine = message.senderId == manager.profile?.id;
    if (wasAtBottom || mine) {
      unawaited(manager.markRead(widget.chatId, messageId: message.id));
    }
  }

  /// Applies an edit or deletion of an already-rendered message, whether it
  /// came from this client's own action or from another member over the
  /// websocket (opcode 9 for edits, opcode 10 for deletions).
  ///
  /// Without this the open chat keeps showing a message that no longer exists
  /// on the server: the delete event lands on [AppManager]'s per-chat change
  /// stream, and nothing else refreshes a list that is already on screen.
  void _applyMessageChange(MessageChange change) {
    if (!mounted) return;
    if (change.chatId != widget.chatId) return;
    final replacement = change.message;
    if (replacement == null) {
      // Deletion: drop the bubble. A message the user had selected loses its
      // selection with it, and an emptied selection leaves multi-select so the
      // bar cannot sit there counting nothing.
      if (!messages.any((message) => message.id == change.messageId)) {
        return;
      }
      setState(() {
        messages = messages
            .where((message) => message.id != change.messageId)
            .toList();
        if (_selectedMessageIds.remove(change.messageId) &&
            _selectedMessageIds.isEmpty) {
          _selectionMode = false;
        }
        // A reply to a message that no longer exists would quote a ghost, so
        // the composer falls back to a fresh send.
        if (_replyTarget?.id == change.messageId) _replyTarget = null;
      });
      return;
    }
    // Edit: the server sends the whole replacement message, so the bubble is
    // swapped in place and keeps its position in the list.
    final index = messages.indexWhere(
      (message) => message.id == change.messageId,
    );
    if (index == -1) return;
    setState(() {
      messages = [...messages]..[index] = replacement;
      // The quoted preview in the composer tracks edits to the target.
      if (_replyTarget?.id == change.messageId) _replyTarget = replacement;
    });
  }

  /// Reports that everything currently in the list has been read, by advancing
  /// this member's cursor to the newest message.
  void _markReadUpToLatest() {
    if (messages.isEmpty) return;
    unawaited(manager.markRead(widget.chatId, messageId: messages.last.id));
  }

  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels < 160;
  }

  void _scrollToBottom({required bool animated}) {
    if (!scrollController.hasClients) return;
    if (animated) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  /// Scrolls to the message [ChatScreen.focusMessageId] names, once it exists.
  ///
  /// The jump is best effort: a message older than the loaded page has nothing
  /// to scroll to and the chat simply opens where it otherwise would. Between
  /// the load and the jump the list builds every message, so a target above or
  /// below the viewport is present and can be reached.
  void _focusPendingMessage() {
    final id = _pendingFocusId;
    if (id == null) return;
    if (!messages.any((message) => message.id == id)) {
      setState(() => _pendingFocusId = null);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingFocusId != id) return;
      final targetContext = _focusKey.currentContext;
      if (targetContext == null) {
        setState(() => _pendingFocusId = null);
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ).whenComplete(() {
          if (mounted && _pendingFocusId == id) {
            setState(() => _pendingFocusId = null);
          }
        }),
      );
    });
  }

  Future<void> load() async {
    try {
      final loadedChat = await manager.api.chat(widget.chatId);
      MemberInfo? member;
      try {
        member = await manager.api.selfMember(widget.chatId);
      } on ApiException catch (exception) {
        if (exception.statusCode != 404) rethrow;
      }
      final loadedMessages = await manager.api.messages(widget.chatId);
      if (mounted) {
        setState(() {
          chat = loadedChat;
          messages = _mergeMessages(loadedMessages);
          isMember = member != null;
          canWrite =
              member != null &&
              (member.role == 'creator' ||
                  member.role == 'admin' ||
                  member.permissions.contains('write_messages') ||
                  member.permissions.contains('administrator'));
        });
        // Opening the conversation is reading it, so report the newest message
        // as read and seed the member cursors that drive the reader counts.
        _markReadUpToLatest();
        unawaited(manager.refreshReadCursors(widget.chatId));
        _focusPendingMessage();
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  /// Folds any realtime messages that arrived while the history request was in
  /// flight back into the freshly loaded snapshot, keyed by id and ordered by id
  /// so a message newer than the snapshot is not lost.
  List<MessageInfo> _mergeMessages(List<MessageInfo> loaded) {
    final byId = <int, MessageInfo>{
      for (final message in loaded) message.id: message,
    };
    for (final message in messages) {
      if (message.chatId == widget.chatId) byId[message.id] = message;
    }
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> send() async {
    final text = composer.text.trim();
    if (text.isEmpty && selectedFile == null) return;
    // Captured before the send so the quote is sent with this message even if
    // the user picks a different target while the request is in flight.
    final replyTarget = _replyTarget;
    composer.clear();
    try {
      final file = selectedFile;
      final attachment = file == null
          ? null
          : await manager.api.uploadFile(file);
      final message = await manager.sendMessage(
        widget.chatId,
        text,
        attachment: attachment,
        replyTo: replyTarget?.id,
      );
      if (mounted) {
        setState(() {
          selectedFile = null;
          // Only drop the quote that was actually sent: a reply chosen while
          // this request was running still describes the next message.
          if (identical(_replyTarget, replyTarget)) _replyTarget = null;
        });
      }
      _appendMessage(message);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  /// Sends a GIF picked from the media panel.
  ///
  /// The GIF is fetched into our own storage first, so the message ends up
  /// holding an ordinary file reference and the chat and message paths never
  /// learn that a third-party catalogue exists. It is sent on its own rather
  /// than appended to the composer, because a GIF is the whole message.
  ///
  /// Returns a Future so the panel can show the work; errors land in the same
  /// [error] line as a failed text send.
  Future<void> sendGif(GifInfo gif) async {
    if (_sendingGif) return;
    setState(() {
      _sendingGif = true;
      error = null;
    });
    try {
      final replyTarget = _replyTarget;
      final file = await manager.api.resolveGif(gif.slug);
      final message = await manager.sendMessage(
        widget.chatId,
        '',
        attachment: file,
        replyTo: replyTarget?.id,
      );
      if (!mounted) return;
      setState(() {
        if (identical(_replyTarget, replyTarget)) _replyTarget = null;
      });
      _appendMessage(message);
      _closePicker();
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => _sendingGif = false);
    }
  }

  void insertNewline() => insertAtCursor('\n');

  /// Puts [text] where the caret is rather than always at the end, so a
  /// half-written message is not scrambled by picking an emoji.
  void insertAtCursor(String text) {
    final value = composer.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : start;
    composer.value = TextEditingValue(
      text: value.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
  }

  void _togglePicker() {
    if (_pickerOpen) {
      _closePicker();
      return;
    }
    // The panel lives in the layout, so a raised keyboard would compete with it
    // for the same space. Handing focus back first makes the panel stand in for
    // the keyboard, on a phone and on a desktop alike.
    composerFocus.unfocus();
    setState(() => _pickerOpen = true);
  }

  void _closePicker() {
    if (!_pickerOpen) return;
    setState(() => _pickerOpen = false);
  }

  void _closePickerOnFocus() {
    if (composerFocus.hasFocus) _closePicker();
  }

  /// Leaves the picker for the developer portal, where the user's UGC items are
  /// made. The composer keeps its text, so a half-written message survives the
  /// trip and the new sticker can be picked on the way back.
  void openUgcPortal() {
    _closePicker();
    context.push('/settings/developer/ugc');
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null && mounted) {
      setState(() => selectedFile = result.files.single);
    }
  }

  /// Starts a call in this chat, or hangs up the call already running here.
  ///
  /// The call itself lives on [AppManager] so it survives navigation; this only
  /// drives the AppBar button and surfaces the two errors worth a dialog.
  Future<void> toggleCall() async {
    final active = manager.activeCall;
    if (active != null) {
      if (active.chatId == widget.chatId) await manager.leaveCall();
      return;
    }

    try {
      // A call already running in this chat is joined rather than restarted:
      // group and channel calls never ring, so this button is how you get in.
      if (manager.activeVoiceCallForChat(widget.chatId) != null) {
        await manager.acceptIncomingVoiceCall(widget.chatId);
      } else {
        await manager.startCall(widget.chatId);
      }
    } on ApiException catch (exception) {
      if (mounted &&
          exception.statusCode != 503 &&
          exception.statusCode != 404) {
        setState(() => error = exception.message);
      }
      if (mounted &&
          (exception.statusCode == 503 || exception.statusCode == 404)) {
        final l10n = context.l10n;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(l10n.chatCallsUnsupported),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonOk),
              ),
            ],
          ),
        );
      }
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    }
  }

  Future<void> openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.chatUnableToOpenAttachment)),
        );
      }
    }
  }

  Widget attachmentView(String name, int size, String url, String contentType) {
    final sizeLabel = size < 1024 * 1024
        ? '${(size / 1024).ceil()} KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    final lowerType = contentType.toLowerCase();
    final lowerName = name.toLowerCase();
    final isSvg = lowerType == 'image/svg+xml' || lowerName.endsWith('.svg');
    final isImage = isSvg || lowerType.startsWith('image/');
    return InkWell(
      onTap: () => openAttachment(url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isSvg
                  ? SvgPicture.network(
                      url,
                      width: 280,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholderBuilder: (_) => const SizedBox.shrink(),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : Image.network(
                      url,
                      width: 280,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isImage ? Icons.image_outlined : Icons.attach_file,
                size: 18,
              ),
              Flexible(child: Text('$name  ($sizeLabel)')),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> joinFromMessage(String value) async {
    final link = parseJoinLink(value);
    if (link == null) return;
    try {
      await manager.api.joinLink(link.value, link.type == JoinLinkType.handle);
      await manager.refreshChats();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.chatJoined)));
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  Future<void> joinChat() async {
    final handle = chat?.handles.firstOrNull;
    if (handle == null) {
      if (mounted) {
        setState(() => error = context.l10n.chatNoJoinLink);
      }
      return;
    }
    try {
      await manager.api.joinLink(handle, true);
      await manager.refreshChats();
      await load();
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  /// Renders [text] with its UGC references drawn as images.
  ///
  /// When [standalone] is set the message is a sticker drop -- nothing but
  /// references, with no attachment, quote or forward beside them -- so the
  /// items are drawn at [kUgcStickerSize] and, in `build`, without a bubble
  /// behind them. The flag rather than a re-check of [text] keeps a tag that
  /// rides along with an attachment inline, where it belongs, instead of
  /// claiming the whole bubble. A reference inside ordinary text is an emoji
  /// and takes [kUgcEmojiSize], small enough to flow with the words.
  Widget messageText(
    MessageInfo message,
    String text,
    TextStyle? style, {
    bool standalone = false,
  }) {
    if (standalone && parseUgcIds(text).length == 1) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in parseUgcIds(text))
            _ugcImage(message, id, size: kUgcStickerSize),
        ],
      );
    } else if (standalone && parseUgcIds(text).length > 1) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in parseUgcIds(text))
            _ugcImage(message, id, size: kUgcEmojiSize),
        ],
      );
    }
    return MessageMarkdown(
      text: text,
      style: style,
      onTap: handleMessageLink,
      ugcBuilder: (id) => _ugcImage(message, id, size: kUgcEmojiSize),
    );
  }

  /// One UGC image inside a message, with the gestures its own surface takes.
  ///
  /// A tap opens the item's popup rather than the message menu, and on a touch
  /// platform a long press opens that menu in place of starting multi-select.
  /// A platform with a mouse is left alone -- its word for the menu is the
  /// secondary button, which the bubble still reads -- so a long press there
  /// falls through to the bubble and keeps starting a selection.
  Widget _ugcImage(MessageInfo message, int id, {required double size}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // In multi-select the whole bubble toggles, stickers included.
        if (_selectionMode) {
          _toggleSelected(message.id);
          return;
        }
        unawaited(_openUgcPopup(id));
      },
      onLongPressStart: _hasContextMenuButton
          ? null
          : (details) {
              if (_selectionMode) {
                _toggleSelected(message.id);
                return;
              }
              _menuAnchor = details.globalPosition;
              unawaited(_showMessageMenu(message, details.globalPosition));
            },
      child: UgcView(id: id, size: size),
    );
  }

  /// Opens a message's sticker in the same popup the composer's picker uses.
  ///
  /// The pack is resolved here rather than in the bubble, because a message
  /// carries only the item id: the pack's own name and saved state are what the
  /// popup adds on top of the bare preview.
  Future<void> _openUgcPopup(int id) async {
    final item = await _resolveUgcItem(id);
    if (!mounted || item == null) return;
    UgcPack? loaded;
    try {
      loaded = await manager.api.ugcPack(item.packId);
    } catch (_) {
      // The popup is still worth showing without the pack: it just loses the
      // heart and the share link, since both act on a pack.
    }
    // A final copy, so the null checks below promote inside the closures that
    // the popup is handed.
    final pack = loaded;
    var saved = false;
    if (pack != null) {
      try {
        saved = (await manager.api.ugcFavoritePacks()).any(
          (favorite) => favorite.id == pack.id,
        );
      } catch (_) {
        // The saved list is a nicety: the popup simply starts as an offer to
        // save when it cannot be read.
      }
    }
    if (!mounted) return;
    await showUgcPopup(
      context,
      item: item,
      packName: pack?.displayName,
      saved: saved,
      onToggleSave: pack == null
          ? null
          : (wanted) => _toggleFavoritePack(pack, wanted),
      onInsert: () => insertAtCursor('<ugc:$id>'),
      onShare: pack == null
          ? null
          : () => copyUgcPackLink(context, pack.id),
    );
  }

  /// Flips whether [pack] is saved, reporting what the server did.
  ///
  /// The popup's heart is direct manipulation, so a refusal has to say so: the
  /// method answers whether the change stuck, and the popup puts the heart
  /// back when it did not.
  Future<bool> _toggleFavoritePack(UgcPack pack, bool saved) async {
    try {
      saved
          ? await manager.api.addUgcFavoritePack(pack.id)
          : await manager.api.removeUgcFavoritePack(pack.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? context.l10n.ugcPickerSaved
                  : context.l10n.ugcPickerRemoved,
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The UGC item with [id], fetched on first sight.
  ///
  /// The bubble already asks the manager for it while rendering, so a tap
  /// usually finds it cached; the fetch covers the case of a press that lands
  /// before the image has resolved.
  Future<UgcItem?> _resolveUgcItem(int id) async {
    final cached = manager.ugcItem(id);
    if (cached != null) return cached;
    try {
      return await manager.api.ugcItem(id);
    } catch (_) {
      return null;
    }
  }

  /// The read indicator shown inside the current member's own bubbles.
  ///
  /// A direct chat shows a single tick once the message is sent and a double
  /// tick when the peer's cursor reaches it (two readers: sender and peer),
  /// unless [AppManager.forceReadCount] asks for the reader count instead.
  /// Groups and channels always show how many members have read the message.
  Widget _readStatus(MessageInfo message) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final count = manager.readCountForMessage(message) ?? message.readCount;
    final showCount = chat?.chatType != 'dm' || manager.forceReadCount;
    if (!showCount) {
      final read = count >= 2;
      return Tooltip(
        message: read ? l10n.chatMessageRead : l10n.chatMessageSent,
        child: Icon(
          read ? Icons.done_all : Icons.done,
          size: 16,
          color: read
              ? colors.primary
              : colors.onPrimaryContainer.withValues(alpha: 0.6),
        ),
      );
    }
    return Tooltip(
      message: l10n.chatReadBy(count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_red_eye_outlined,
            size: 16,
            color: colors.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  /// Enters multi-select with [messageId] as the first selected message.
  void _startSelection(int messageId) {
    setState(() {
      _selectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  /// Leaves multi-select and clears the selection.
  void _stopSelection() {
    if (!_selectionMode && _selectedMessageIds.isEmpty) return;
    setState(() {
      _selectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  /// Adds or removes [messageId] while multi-select is active.
  void _toggleSelected(int messageId) {
    setState(() {
      if (!_selectedMessageIds.add(messageId)) {
        _selectedMessageIds.remove(messageId);
      }
    });
  }

  /// The selected messages in the order they appear, so a bulk forward keeps
  /// the conversation's own ordering.
  List<MessageInfo> _selectedMessages() => messages
      .where((message) => _selectedMessageIds.contains(message.id))
      .toList();

  /// Deletes every selected message and leaves multi-select.
  ///
  /// The bubbles drop from the list immediately; the requests go through
  /// [AppManager.deleteMessage] so the removal is also echoed to subscribers
  /// and the cached chat preview stops showing a message that is gone.
  Future<void> _deleteSelected() async {
    final ids = _selectedMessageIds.toList();
    _stopSelection();
    setState(() {
      messages = messages
          .where((message) => !ids.contains(message.id))
          .toList();
      if (_replyTarget != null && ids.contains(_replyTarget!.id)) {
        _replyTarget = null;
      }
    });
    for (final id in ids) {
      await manager.deleteMessage(widget.chatId, id);
    }
  }

  /// Forwards every message in [source] into the conversation the user picks.
  ///
  /// One pick covers the whole batch: the action menu forwards a single message
  /// and the selection bar forwards everything selected. Each copy is created
  /// server-side, and one forwarded into the chat currently on screen is
  /// appended here because the server never echoes a message back to its own
  /// sender over the websocket.
  Future<void> _forwardMessages(List<MessageInfo> source) async {
    if (source.isEmpty) return;
    final target = await showForwardPicker(
      context,
      chats: manager.chats,
      baseUrl: manager.api.baseUrl,
    );
    if (!mounted || target == null) return;
    try {
      for (final message in source) {
        final copy = await manager.forwardMessage(message, target.id);
        if (!mounted) return;
        if (copy.chatId == widget.chatId) _appendMessage(copy);
      }
      if (!mounted) return;
      _stopSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chatForwardedTo(target.displayName)),
        ),
      );
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    }
  }

  /// Placeholder handler for the actions that have no behaviour yet.
  void _selectionActionUnavailable() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.chatActionUnavailable)));
  }

  /// Makes [message] the quote the composer will answer and hands focus back to
  /// the text field, so the next keystroke belongs to the reply.
  void _startReply(MessageInfo message) {
    setState(() => _replyTarget = message);
    composerFocus.requestFocus();
  }

  /// Drops a pending reply and leaves the drafted text alone.
  void _cancelReply() {
    if (_replyTarget == null) return;
    setState(() => _replyTarget = null);
  }

  /// One line describing [message] for a quoted preview: its text, else the
  /// attachment's name, else a label for a message whose content is not loaded.
  String _messagePreview(MessageInfo message) {
    final text = ugcPreviewText(
      message.text.trim(),
      context.l10n.ugcStickerPreview,
    );
    if (text.isNotEmpty) return text;
    if (message.attachmentName.isNotEmpty) return message.attachmentName;
    return context.l10n.chatReplyUnavailable;
  }

  /// The message [message] answers, when it is among the loaded ones. The
  /// backend sends only the replied-to id, so a quote older than the fetched
  /// page resolves to null and the caller falls back to a generic label.
  MessageInfo? _repliedTo(MessageInfo message) =>
      messages.where((item) => item.id == message.replied).firstOrNull;

  /// Handles a tap or right click on a message bubble.
  ///
  /// In multi-select it toggles the message; otherwise it opens the action menu
  /// anchored at the pointer, the way a file manager opens its context menu.
  void _handleMessageTap(MessageInfo message) {
    if (_selectionMode) {
      _toggleSelected(message.id);
      return;
    }
    _showMessageMenu(message, _menuAnchor);
  }

  Future<void> _showMessageMenu(MessageInfo message, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final l10n = context.l10n;
    final hasText = message.text.trim().isNotEmpty;

    final action = await showMenu<_MessageAction>(
      context: context,
      // Modern rounded styling
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      // Position the menu relative to the touch coordinates
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: _MessageAction.reply,
          child: _menuRow(Icons.reply, l10n.chatMenuReply),
        ),
        PopupMenuItem(
          value: _MessageAction.copy,
          enabled: hasText,
          child: _menuRow(Icons.copy_outlined, l10n.commonCopy),
        ),
        PopupMenuItem(
          value: _MessageAction.forward,
          child: _menuRow(Icons.forward_outlined, l10n.chatMenuForward),
        ),
        PopupMenuItem(
          value: _MessageAction.select,
          child: _menuRow(Icons.check_box_outlined, l10n.chatMenuSelect),
        ),
        PopupMenuItem(
          value: _MessageAction.delete,
          child: _menuRow(Icons.delete_outline, l10n.commonDelete),
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.chatMessageCopied)));
      case _MessageAction.select:
        _startSelection(message.id);
      case _MessageAction.reply:
        _startReply(message);
      case _MessageAction.forward:
        await _forwardMessages([message]);
      case _MessageAction.delete:
        // Through the manager so the removal is echoed to the on-screen list
        // and the cached chat preview, the same way multi-select delete does.
        unawaited(manager.deleteMessage(message.chatId, message.id));
    }
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
    );
  }

  /// The strip above the composer that names the message being answered, with
  /// the way out. It mirrors the quote drawn on the sent bubble, so the preview
  /// is what the reply will show.
  Widget _replyBanner(MessageInfo target) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatMenuReply,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.primary),
                ),
                Text(
                  _messagePreview(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonDismiss,
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  /// The bar drawn inside a bubble that replies to [message], quoting the
  /// parent's text when it is still loaded.
  Widget _replyQuote(MessageInfo message) {
    final colors = Theme.of(context).colorScheme;
    final parent = _repliedTo(message);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.primary, width: 3)),
      ),
      child: Text(
        parent == null
            ? context.l10n.chatReplyUnavailable
            : _messagePreview(parent),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// The "Forwarded from `author`" header drawn on a forwarded bubble.
  ///
  /// A forward the backend attributed to someone is tappable and leads back to
  /// the original through [_openForwardAuthor]; one with no author (an older
  /// copy) keeps the plain, inert label.
  Widget _forwardedHeader(MessageInfo message) {
    final colors = Theme.of(context).colorScheme;
    final author = message.forwardAuthor;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: author == null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forward_outlined,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(context.l10n.chatForwarded, style: labelStyle),
              ],
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openForwardAuthor(message),
              child: Tooltip(
                message: context.l10n.chatForwardedOpen,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (author.avatarUrl.isNotEmpty)
                      Avatar(
                        displayName: author.displayName,
                        imageUrl: author.avatarUrl,
                        baseUrl: manager.api.baseUrl,
                        radius: 8,
                        fallbackIcon: author.isChannel
                            ? Icons.campaign_outlined
                            : Icons.person_outline,
                      )
                    else
                      Icon(
                        author.isChannel
                            ? Icons.campaign_outlined
                            : Icons.forward_outlined,
                        size: 14,
                        color: colors.primary,
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        context.l10n.chatForwardedFrom(author.displayName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle?.copyWith(color: colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Opens where a forwarded message came from.
  ///
  /// A channel is itself a chat, so a channel forward jumps into that channel
  /// and, when the original message id is known, asks it to scroll there. A
  /// personal forward has no chat to open, so it falls back to the author's
  /// profile. Either way the tap "tries" to reach the source, and an author the
  /// backend could not resolve leaves the header inert.
  void _openForwardAuthor(MessageInfo message) {
    final author = message.forwardAuthor;
    if (author == null) return;
    if (author.isChannel) {
      final origin = message.forwarded;
      openChatRoute(context, author.id, focusMessageId: origin);
    } else {
      context.push('/user/${author.id}');
    }
  }

  /// The normal chat app bar: the back button on narrow layouts, the tappable
  /// title and the call control.
  PreferredSizeWidget _buildChatAppBar() {
    final l10n = context.l10n;
    final callOngoing = manager.activeVoiceCallForChat(widget.chatId) != null;
    return AppBar(
      leading: isWideScreen(context)
          ? null
          : IconButton(
              tooltip: l10n.chatBackToChats,
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
            ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: chat == null
            ? null
            : () async {
                if (chat!.chatType == 'dm' && chat!.peerUserId != null) {
                  context.push('/user/${chat!.peerUserId}');
                } else {
                  await context.push('/chat/${widget.chatId}/profile');
                  if (mounted) load();
                }
              },
        child: Container(
          width: double.infinity,
          height:
              kToolbarHeight, // Explicitly set the height of the standard AppBar
          alignment: Alignment
              .centerLeft, // Or Alignment.center if the text is centered
          child: Text(chat?.displayName ?? l10n.chatConversation),
        ),
      ),
      actions: [
        IconButton(
          tooltip: switch (manager.activeCall?.chatId) {
            null => callOngoing ? l10n.chatJoinCall : l10n.chatStartCall,
            final id when id == widget.chatId => l10n.chatEndCall,
            _ => l10n.chatInCall,
          },
          onPressed: switch (manager.activeCall?.chatId) {
            null => toggleCall,
            final id when id == widget.chatId => toggleCall,
            _ => null,
          },
          icon: Icon(
            manager.activeCall?.chatId == widget.chatId
                ? Icons.call_end
                : callOngoing
                ? Icons.call
                : Icons.call_outlined,
          ),
        ),
      ],
    );
  }

  /// The app bar shown while messages are selected: the selected count, a way
  /// out of the mode, and the bulk actions (only delete works so far).
  PreferredSizeWidget _buildSelectionAppBar() {
    final l10n = context.l10n;
    return AppBar(
      leading: IconButton(
        tooltip: l10n.chatSelectionStop,
        onPressed: _stopSelection,
        icon: const Icon(Icons.close),
      ),
      title: Text(l10n.chatSelectionCount(_selectedMessageIds.length)),
      actions: [
        IconButton(
          tooltip: l10n.commonCopy,
          onPressed: _selectionActionUnavailable,
          icon: const Icon(Icons.copy_outlined),
        ),
        IconButton(
          tooltip: l10n.chatMenuForward,
          onPressed: () => unawaited(_forwardMessages(_selectedMessages())),
          icon: const Icon(Icons.forward_outlined),
        ),
        IconButton(
          tooltip: l10n.commonDelete,
          onPressed: _deleteSelected,
          icon: const Icon(Icons.delete_outline),
        ),
        IconButton(
          tooltip: l10n.chatMenuMore,
          onPressed: _selectionActionUnavailable,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  /// Wraps a bubble so a tap or right click opens its action menu and a long
  /// press starts a multi-selection, without stealing taps from links inside.
  Widget _messageGestures(MessageInfo message, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _menuAnchor = details.globalPosition,
      onSecondaryTapDown: (details) => _menuAnchor = details.globalPosition,
      onTap: () => _handleMessageTap(message),
      onSecondaryTap: () => _handleMessageTap(message),
      onLongPressStart: (_) => _startSelection(message.id),
      child: child,
    );
  }

  Future<void> handleMessageLink(String value) async {
    if (parseJoinLink(value) != null) {
      await joinFromMessage(value);
      return;
    }
    // A shared pack opens in the app rather than in a browser: the link is how
    // the pack reaches this account, and the screen is where it gets saved.
    final packId = parseUgcShareLink(value);
    if (packId != null) {
      context.push('/sticker/$packId');
      return;
    }
    var target = value;
    if (RegExp(r'^www\.').hasMatch(target)) target = 'https://$target';
    final uri = Uri.tryParse(target);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chatUnableToOpenLink)),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.chatUnableToOpenLink)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final l10n = context.l10n;
        return Scaffold(
          appBar: _selectionMode ? _buildSelectionAppBar() : _buildChatAppBar(),
          body: Column(
            children: [
              if (error != null)
                MaterialBanner(
                  content: Text(error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => error = null),
                      child: Text(l10n.commonDismiss),
                    ),
                  ],
                ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: chat == null && error == null
                            ? const CircularProgressIndicator()
                            : error != null
                            ? const Icon(Icons.chat_bubble_outline, size: 48)
                            : Text(l10n.chatSendFirstMessage),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        // While a jump is owed the whole page is built, so a
                        // target outside the viewport is present to scroll to.
                        scrollCacheExtent: _pendingFocusId != null
                            ? const ScrollCacheExtent.pixels(100000)
                            : null,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine = message.senderId == manager.profile?.id;
                          // A sticker-only message drops its bubble: no reply
                          // quote, forward header or attachment means the UGCs
                          // are the whole message, so the coloured background
                          // would only frame a sticker that is meant to float.
                          final ugcOnly =
                              isUgcOnly(message.text) &&
                              message.attachmentName.isEmpty &&
                              !message.isReply &&
                              !message.isForward;
                          // The message body: the quoted parent and the forward
                          // attribution, then the attachment, then the text,
                          // all sized to their content.
                          final body = Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.isReply) _replyQuote(message),
                              if (message.isForward) _forwardedHeader(message),
                              if (message.attachmentName.isNotEmpty)
                                attachmentView(
                                  message.attachmentName,
                                  message.attachmentSize,
                                  message.attachmentUrl,
                                  message.attachmentType,
                                ),
                              if (message.text.isNotEmpty)
                                messageText(
                                  message,
                                  message.text,
                                  DefaultTextStyle.of(context).style,
                                  standalone: ugcOnly,
                                ),
                            ],
                          );
                          final selected = _selectedMessageIds.contains(
                            message.id,
                          );
                          final bubble = Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: ugcOnly
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                            constraints: const BoxConstraints(maxWidth: 560),
                            decoration: BoxDecoration(
                              color: ugcOnly
                                  ? Colors.transparent
                                  : mine
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: selected
                                  ? Border.all(color: colors.primary, width: 2)
                                  : null,
                            ),
                            // The read indicator belongs to the message it
                            // describes, so it sits inside the bubble. Laying it
                            // beside a Flexible body keeps a short bubble short
                            // while pinning the indicator to the bottom-right.
                            // On a sticker-only bubble the background is gone,
                            // so the tick keeps its own little bubble of colour
                            // to stay legible over the chat wallpaper.
                            child: mine
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(child: body),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 6,
                                          bottom: ugcOnly ? 6 : 2,
                                        ),
                                        child: ugcOnly
                                            ? DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color:
                                                      colors.primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  child: _readStatus(message),
                                                ),
                                              )
                                            : _readStatus(message),
                                      ),
                                    ],
                                  )
                                : body,
                          );
                          final messageContent = Tooltip(
                            message: l10n.chatMessageId(message.id),
                            child: bubble,
                          );
                          final content = _messageGestures(
                            message,
                            manager.developerInfo ? messageContent : bubble,
                          );
                          final Widget item = mine
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: content,
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8,
                                        bottom: 8,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _selectionMode
                                            ? _toggleSelected(message.id)
                                            : context.push(
                                                '/user/${message.senderId}',
                                              ),
                                        child: const CircleAvatar(
                                          radius: 16,
                                          child: Icon(
                                            Icons.person_outline,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(child: content),
                                  ],
                                );
                          // The bubble a pending jump targets carries the key
                          // `_focusPendingMessage` scrolls to.
                          return message.id == _pendingFocusId
                              ? KeyedSubtree(key: _focusKey, child: item)
                              : item;
                        },
                      ),
              ),
              if (isMember == false)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: joinChat,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(l10n.chatJoin),
                    ),
                  ),
                )
              else if (isMember == true &&
                  !canWrite &&
                  chat?.chatType == 'chat')
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: Text(l10n.chatNoWritePermission)),
                  ),
                )
              else if (isMember == true && canWrite)
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyTarget != null) _replyBanner(_replyTarget!),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: l10n.chatAttachFile,
                              onPressed: pickFile,
                              icon: const Icon(Icons.attach_file),
                            ),
                            IconButton(
                              tooltip: l10n.chatEmojiSelectButton,
                              onPressed: _togglePicker,
                              icon: const Icon(Icons.emoji_emotions_outlined),
                            ),
                            Expanded(
                              child: Shortcuts(
                                shortcuts: {
                                  SingleActivator(LogicalKeyboardKey.enter):
                                      const _SendMessageIntent(),
                                  SingleActivator(
                                    LogicalKeyboardKey.numpadEnter,
                                  ): const _SendMessageIntent(),
                                  SingleActivator(
                                    LogicalKeyboardKey.enter,
                                    shift: true,
                                  ): const _InsertNewlineIntent(),
                                  SingleActivator(
                                    LogicalKeyboardKey.enter,
                                    control: true,
                                  ): const _InsertNewlineIntent(),
                                  SingleActivator(
                                    LogicalKeyboardKey.enter,
                                    meta: true,
                                  ): const _InsertNewlineIntent(),
                                  SingleActivator(
                                    LogicalKeyboardKey.numpadEnter,
                                    shift: true,
                                  ): const _InsertNewlineIntent(),
                                },
                                child: Actions(
                                  actions: {
                                    _SendMessageIntent:
                                        CallbackAction<_SendMessageIntent>(
                                          onInvoke: (_) {
                                            send();
                                            return null;
                                          },
                                        ),
                                    _InsertNewlineIntent:
                                        CallbackAction<_InsertNewlineIntent>(
                                          onInvoke: (_) {
                                            insertNewline();
                                            return null;
                                          },
                                        ),
                                  },
                                  child: ExtendedTextField(
                                    controller: composer,
                                    focusNode: composerFocus,
                                    minLines: 1,
                                    maxLines: 5,
                                    onSubmitted: (_) => send(),
                                    // Draws an unescaped `<ugc:id>` as the
                                    // item's emoji and an escaped one as the
                                    // literal tag, while the controller keeps
                                    // the plain text either way.
                                    specialTextSpanBuilder:
                                        UgcComposerSpanBuilder(),
                                    decoration: InputDecoration(
                                      hintText: l10n.chatWriteMessage,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: l10n.chatSend,
                              onPressed: send,
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                      if (_pickerOpen)
                        SizedBox(
                          height: 264,
                          child: Material(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: MediaPickerPanel(
                              tab: _pickerTab,
                              onTabChanged: (tab) =>
                                  setState(() => _pickerTab = tab),
                              onEmojiSelected: insertAtCursor,
                              onGifSelected: sendGif,
                              onUgcSelected: (item) =>
                                  insertAtCursor('<ugc:${item.id}>'),
                              onOpenUgcPortal: openUgcPortal,
                              api: manager.api,
                              onClose: _closePicker,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _messageChangeSub?.cancel();
    // Only clear if this screen still owns the active-chat marker: a route
    // replacement can dispose the old chat after the new one has initialised,
    // and clearing unconditionally would suppress the new chat's notifications.
    // The call itself is owned by AppManager, so leaving a chat never hangs up.
    if (manager.activeChatId == widget.chatId) {
      manager.setActiveChat(null);
    }
    composerFocus
      ..removeListener(_closePickerOnFocus)
      ..dispose();
    composer.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}

class _InsertNewlineIntent extends Intent {
  const _InsertNewlineIntent();
}
