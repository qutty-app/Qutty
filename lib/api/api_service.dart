import 'dart:convert';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:qutty/l10n/l10n.dart';

import 'join_link.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ChatInfo {
  final int id;
  final String chatType;
  final int? peerUserId;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final List<String> handles;
  final List<String> permissions;
  final DateTime createdAt;
  final String lastMessageForDumbAssChatList;

  const ChatInfo({
    required this.id,
    required this.chatType,
    this.peerUserId,
    required this.displayName,
    required this.bio,
    this.avatarUrl = '',
    required this.handles,
    this.permissions = const [],
    required this.createdAt,
    this.lastMessageForDumbAssChatList = "",
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) => ChatInfo(
    id: (json['id'] as num).toInt(),
    chatType: json['chat_type'] as String? ?? 'chat',
    peerUserId: (json['peer_user_id'] as num?)?.toInt(),
    displayName: json['display_name'] as String? ?? L10n.current.unnamedChat,
    bio: json['bio'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    handles: (json['handles'] as List<dynamic>? ?? [])
        .map((handle) => handle.toString())
        .toList(),
    permissions: (json['permissions'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    lastMessageForDumbAssChatList: json['last_message'] as String? ?? '',
  );

  /// The chat as the server would send it, so it can be written to the
  /// offline cache and read back without losing anything.
  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_type': chatType,
    if (peerUserId != null) 'peer_user_id': peerUserId,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'handles': handles,
    'permissions': permissions,
    'created_at': createdAt.toIso8601String(),
    'last_message': lastMessageForDumbAssChatList,
  };
}

class MemberInfo {
  final int userId;
  final String displayName;
  final String username;
  final String role;
  final List<String> permissions;
  final String avatarUrl;
  final String displayTag;
  final DateTime? joinedAt;

  /// The newest message this member has read, or 0 when they have read nothing.
  /// A message is counted as read by this member when its id is at or below
  /// this cursor.
  final int lastReadMessageId;

  const MemberInfo({
    required this.userId,
    required this.displayName,
    this.username = '',
    required this.role,
    required this.permissions,
    this.avatarUrl = '',
    this.displayTag = '',
    this.joinedAt,
    this.lastReadMessageId = 0,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) => MemberInfo(
    userId: (json['user_id'] as num).toInt(),
    displayName: json['display_name'] as String? ?? '',
    username: json['username'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
    avatarUrl: json['avatar_url'] as String? ?? '',
    displayTag: json['display_tag'] as String? ?? '',
    joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? ''),
    lastReadMessageId: (json['last_read_message_id'] as num?)?.toInt() ?? 0,
    permissions: (json['permissions'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(),
  );
}

/// Names the origin a forwarded copy is attributed to.
///
/// The three ids are kept apart the way the backend keeps them: [chatId] and
/// [messageId] identify the copy the actor can actually reach, while
/// [forwardMessageId] is the original message the copy is attributed to. A
/// message is forwardable when it is that origin itself or a forward of it, so
/// re-forwarding a copy keeps pointing at the same origin.
class ForwardManifest {
  final int chatId;
  final int messageId;
  final int forwardMessageId;

  const ForwardManifest({
    required this.chatId,
    required this.messageId,
    required this.forwardMessageId,
  });

  /// Builds the manifest for [message] as it should be forwarded: a plain
  /// message is its own origin, and a copy stays attributed to the origin it
  /// already points at.
  factory ForwardManifest.forMessage(MessageInfo message) => ForwardManifest(
    chatId: message.chatId,
    messageId: message.id,
    forwardMessageId: message.forwarded > 0 ? message.forwarded : message.id,
  );

  Map<String, dynamic> toJson() => {
    'chat_id': chatId,
    'message_id': messageId,
    'forward_message_id': forwardMessageId,
  };
}

/// The original author of a forwarded message: the user who posted it, or the
/// channel it was posted to. The backend only sends this object on forwarded
/// messages, so a plain message has a null [MessageInfo.forwardAuthor].
class ForwardAuthor {
  /// Either `user` or `channel`, matching the table [id] points at.
  final String type;
  final int id;
  final String displayName;
  final String avatarUrl;

  const ForwardAuthor({
    required this.type,
    required this.id,
    required this.displayName,
    this.avatarUrl = '',
  });

  /// Whether the original author is a channel rather than a person.
  bool get isChannel => type == 'channel';

  factory ForwardAuthor.fromJson(Map<String, dynamic> json) => ForwardAuthor(
    type: json['type'] as String? ?? 'user',
    id: (json['id'] as num?)?.toInt() ?? 0,
    displayName: json['display_name'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };
}

class MessageInfo {
  final int id;
  final int chatId;
  final int senderId;
  final String text;
  final String attachmentKey;
  final String attachmentName;
  final String attachmentUrl;
  final String attachmentType;
  final int attachmentSize;
  final bool isEdited;

  /// The id of the message this one was forwarded from, or 0 when it is not a
  /// forward. Forwarded messages are copies, so the backend refuses to edit
  /// them.
  final int forwarded;

  /// The original author a forwarded message is attributed to: the user who
  /// posted it, or the channel it was posted to. Null on regular messages and
  /// on forwards whose origin the backend could not resolve.
  final ForwardAuthor? forwardAuthor;

  /// The id of the message this one replies to, or 0 when it does not reply to
  /// anything. The backend sends only the id, so the quoted content is resolved
  /// from the messages already loaded for the chat.
  final int replied;
  final DateTime createdAt;

  /// How many chat members had read this message when it was last fetched. A
  /// member counts once their read cursor reaches this message's id, so the
  /// number only grows as people catch up. Live updates arrive as read receipts
  /// and are applied by [AppManager], which is why this is a snapshot rather
  /// than a source of truth.
  final int readCount;

  const MessageInfo({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.attachmentKey = '',
    this.attachmentName = '',
    this.attachmentUrl = '',
    this.attachmentType = '',
    this.attachmentSize = 0,
    this.isEdited = false,
    this.forwarded = 0,
    this.forwardAuthor,
    this.replied = 0,
    this.readCount = 0,
    required this.createdAt,
  });

  /// Whether this message is a copy of another one rather than an original.
  bool get isForward => forwarded > 0;

  /// Whether this message answers another one.
  bool get isReply => replied > 0;

  factory MessageInfo.fromJson(Map<String, dynamic> json) => MessageInfo(
    id: (json['id'] as num).toInt(),
    chatId: (json['chat_id'] as num?)?.toInt() ?? 0,
    senderId: (json['sender_id'] as num).toInt(),
    text: json['text'] as String? ?? '',
    attachmentKey: json['attachment_key'] as String? ?? '',
    attachmentName: json['attachment_name'] as String? ?? '',
    attachmentUrl: json['attachment_url'] as String? ?? '',
    attachmentType: json['attachment_type'] as String? ?? '',
    attachmentSize: (json['attachment_size'] as num?)?.toInt() ?? 0,
    isEdited: json['is_edited'] as bool? ?? false,
    forwarded: (json['forwarded'] as num?)?.toInt() ?? 0,
    forwardAuthor: json['forward_author'] is Map<String, dynamic>
        ? ForwardAuthor.fromJson(json['forward_author'] as Map<String, dynamic>)
        : null,
    replied: (json['replied'] as num?)?.toInt() ?? 0,
    readCount: (json['read_count'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );

  MessageInfo copyWith({String? text, bool? isEdited, int? readCount}) =>
      MessageInfo(
        id: id,
        chatId: chatId,
        senderId: senderId,
        text: text ?? this.text,
        attachmentKey: attachmentKey,
        attachmentName: attachmentName,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        attachmentSize: attachmentSize,
        isEdited: isEdited ?? this.isEdited,
        forwarded: forwarded,
        forwardAuthor: forwardAuthor,
        replied: replied,
        readCount: readCount ?? this.readCount,
        createdAt: createdAt,
      );

  /// The message as the server would send it, so it can be written to the
  /// offline cache and read back without losing anything.
  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'sender_id': senderId,
    'text': text,
    'attachment_key': attachmentKey,
    'attachment_name': attachmentName,
    'attachment_url': attachmentUrl,
    'attachment_type': attachmentType,
    'attachment_size': attachmentSize,
    'is_edited': isEdited,
    'forwarded': forwarded,
    if (forwardAuthor != null) 'forward_author': forwardAuthor!.toJson(),
    'replied': replied,
    'read_count': readCount,
    'created_at': createdAt.toIso8601String(),
  };
}

/// A change applied to a message that already existed: it was either edited
/// (the whole message is replaced) or deleted (the message is removed).
///
/// The frontend gets one of these from its own edit/delete call and from the
/// websocket when another member changes a message, so a single handler can
/// keep the on-screen list in sync.
class MessageChange {
  final int chatId;
  final int messageId;

  /// The replacement message for an edit, or null for a deletion.
  final MessageInfo? message;

  const MessageChange({
    required this.chatId,
    required this.messageId,
    this.message,
  });

  bool get isDeleted => message == null;

  factory MessageChange.edited(MessageInfo message) => MessageChange(
    chatId: message.chatId,
    messageId: message.id,
    message: message,
  );

  factory MessageChange.deleted(int chatId, int messageId) =>
      MessageChange(chatId: chatId, messageId: messageId);

  /// Parses a deletion payload: `{chat_id, message_id}`.
  factory MessageChange.fromDeletedJson(Map<String, dynamic> json) =>
      MessageChange(
        chatId: (json['chat_id'] as num?)?.toInt() ?? 0,
        messageId: (json['message_id'] as num?)?.toInt() ?? 0,
      );
}

/// A member's read position in a chat, delivered over the websocket on opcode 8.
///
/// The same payload is both the acknowledgement of a client's own read report
/// and the broadcast that tells the other members a reader has moved. Clients
/// track per-member cursors and treat a message as read by a member when the
/// member's [lastReadMessageId] is at or above the message id.
class ReadReceipt {
  final int chatId;
  final String chatType;
  final int userId;
  final int lastReadMessageId;

  /// How many members (including this reader) have read up to
  /// [lastReadMessageId]. Reachable directly when the cursor sits exactly on a
  /// message, so DMs can show a tick without knowing the member list.
  final int readCount;
  final int memberCount;

  const ReadReceipt({
    required this.chatId,
    this.chatType = '',
    required this.userId,
    required this.lastReadMessageId,
    this.readCount = 0,
    this.memberCount = 0,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) => ReadReceipt(
    chatId: (json['chat_id'] as num?)?.toInt() ?? 0,
    chatType: json['chat_type'] as String? ?? '',
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    lastReadMessageId: (json['last_read_message_id'] as num?)?.toInt() ?? 0,
    readCount: (json['read_count'] as num?)?.toInt() ?? 0,
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
  );
}

class DeviceTokenInfo {
  final int id;
  final String token;
  final String platform;
  final String appVersion;

  /// The push service that issued [token]: "fcm" or "apns".
  final String provider;

  /// Whether an APNs token came from Apple's sandbox rather than production.
  final bool sandbox;

  /// The app identifier this token belongs to. APNs addresses pushes by it, so
  /// it is what allows a build with a different bundle id to be delivered to.
  final String bundleId;

  final DateTime? lastSeenAt;

  const DeviceTokenInfo({
    required this.id,
    required this.token,
    required this.platform,
    required this.appVersion,
    this.provider = 'fcm',
    this.sandbox = false,
    this.bundleId = '',
    this.lastSeenAt,
  });

  factory DeviceTokenInfo.fromJson(Map<String, dynamic> json) =>
      DeviceTokenInfo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        token: json['token'] as String? ?? '',
        platform: json['platform'] as String? ?? 'unknown',
        appVersion: json['app_version'] as String? ?? '',
        provider: json['provider'] as String? ?? 'fcm',
        sandbox: json['sandbox'] as bool? ?? false,
        bundleId: json['bundle_id'] as String? ?? '',
        lastSeenAt: DateTime.tryParse(json['last_seen_at'] as String? ?? ''),
      );
}

class FileInfo {
  final String key;
  final String url;
  final String name;
  final String contentType;
  final int size;

  const FileInfo({
    required this.key,
    required this.url,
    required this.name,
    required this.contentType,
    required this.size,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
    key: json['key'] as String? ?? '',
    url: json['url'] as String? ?? '',
    name: json['name'] as String? ?? 'file',
    contentType: json['content_type'] as String? ?? 'application/octet-stream',
    size: (json['size'] as num?)?.toInt() ?? 0,
  );
}

class Profile {
  final int id;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final List<String> handles;
  final String? email;
  final String accountType;
  final DateTime? lastOnline;

  const Profile({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl = '',
    required this.handles,
    this.email,
    this.accountType = 'user',
    this.lastOnline,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: (json['id'] as num).toInt(),
    displayName: json['display_name'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    email: json['email'] as String?,
    accountType: json['account_type'] as String? ?? 'user',
    lastOnline: DateTime.tryParse(json['last_online'] as String? ?? ''),
    handles: (json['handles'] as List<dynamic>? ?? [])
        .map((handle) => handle.toString())
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'bio': bio,
    'avatar_url': avatarUrl,
    'handles': handles,
    'email': email,
    'account_type': accountType,
    'last_online': lastOnline?.toIso8601String(),
  };
}

/// A bot: a developer app the account owns, served as a regular user with
/// [BotInfo.accountType] set to `bot`.
///
/// The bot is a user row the backend created for the owner, bound to it through
/// a developer app, and authenticated with a session token the backend hands out
/// exactly once through [CreatedBot]. Bots therefore show up in the same shapes
/// as any other profile, which is what lets a client open a chat with one.
class BotInfo {
  final int id;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String accountType;
  final List<String> handles;
  final DateTime? lastOnline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BotInfo({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl = '',
    required this.accountType,
    required this.handles,
    this.lastOnline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BotInfo.fromJson(Map<String, dynamic> json) => BotInfo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        displayName: json['display_name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        accountType: json['account_type'] as String? ?? 'bot',
        handles: (json['handles'] as List<dynamic>? ?? [])
            .map((handle) => handle.toString())
            .toList(),
        lastOnline: DateTime.tryParse(json['last_online'] as String? ?? ''),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// The bot a freshly created developer app produced, plus the session token
/// that authenticates it.
///
/// The token is returned by the create call and by no other: the backend hands
/// it out exactly once, because it only ever exists as the session token of the
/// bot's own session. Losing it means losing the bot, so the caller is expected
/// to surface it before the value goes away.
class CreatedBot {
  final BotInfo bot;
  final String token;

  const CreatedBot({required this.bot, required this.token});
}

class VoiceToken {
  final String url;
  final String token;
  final String room;
  final bool canPublish;
  final bool voiceControl;

  const VoiceToken({
    required this.url,
    required this.token,
    required this.room,
    required this.canPublish,
    required this.voiceControl,
  });

  factory VoiceToken.fromJson(Map<String, dynamic> json) => VoiceToken(
    url: json['url'] as String? ?? '',
    token: json['token'] as String? ?? '',
    room: json['room'] as String? ?? '',
    canPublish: json['can_publish'] as bool? ?? false,
    voiceControl: json['voice_control'] as bool? ?? false,
  );
}

class SessionInfo {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime lastOnline;
  final String lastIp;

  const SessionInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastOnline,
    this.lastIp = '',
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
    id: ((json['ID'] ?? json['id']) as num).toInt(),
    name:
        json['Name'] as String? ??
        json['name'] as String? ??
        L10n.current.unnamedSession,
    createdAt:
        DateTime.tryParse(
          (json['CreatedAt'] ?? json['created_at'] ?? '').toString(),
        ) ??
        DateTime.now(),
    lastOnline:
        DateTime.tryParse(
          (json['LastOnline'] ?? json['last_online'] ?? '').toString(),
        ) ??
        DateTime.now(),
    lastIp: json['LastIP'] as String? ?? json['last_ip'] as String? ?? '',
  );

  bool get isCurrent => name == 'Qutty';
}

class SearchResults {
  final List<ChatInfo> chats;
  final List<Profile> users;
  const SearchResults({required this.chats, required this.users});
  factory SearchResults.fromJson(Map<String, dynamic> json) => SearchResults(
    chats: (json['chats'] as List<dynamic>? ?? [])
        .map((item) => ChatInfo.fromJson(item as Map<String, dynamic>))
        .toList(),
    users: (json['users'] as List<dynamic>? ?? [])
        .map((item) => Profile.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}

/// One rendition of a GIF at a size and format.
///
/// The picker only ever needs the still [preview] for grid cells, so the
/// animated renditions are kept for the send path and rarely read here.
class GifVariant {
  final String url;
  final int width;
  final int height;
  final int size;

  const GifVariant({
    required this.url,
    required this.width,
    required this.height,
    required this.size,
  });

  static GifVariant? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = json['url'] as String? ?? '';
    if (url.isEmpty) return null;
    return GifVariant(
      url: url,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The renditions available for one size bucket.
class GifFormats {
  final GifVariant? webp;
  final GifVariant? gif;

  const GifFormats({this.webp, this.gif});

  factory GifFormats.fromJson(Object? json) {
    if (json is! Map) return const GifFormats();
    return GifFormats(
      webp: GifVariant.fromJson(json['webp']),
      gif: GifVariant.fromJson(json['gif']),
    );
  }
}

/// One GIF in the picker.
class GifInfo {
  final int id;
  final String slug;
  final String title;

  /// A still JPEG of the first frame.
  ///
  /// Only a fallback: it does not animate, so a picker that shows it looks
  /// like it is serving broken GIFs.
  final String preview;

  /// A rendition that animates, when the server named one.
  ///
  /// The server sets this for favourites, which it serves from its own table
  /// and cannot re-derive from [files].
  final String animationUrl;
  final int width;
  final int height;

  /// Smallest first. `xs` is the only bucket small enough to animate in a grid:
  /// live, an `xs` webp is 26-36KB where `sm` is 81-146KB and is sometimes no
  /// smaller than `md`.
  final GifFormats xs;
  final GifFormats sm;
  final GifFormats md;
  final GifFormats hd;

  const GifInfo({
    required this.id,
    required this.slug,
    required this.title,
    required this.preview,
    required this.animationUrl,
    required this.width,
    required this.height,
    required this.xs,
    required this.sm,
    required this.md,
    required this.hd,
  });

  /// The URL to show for this GIF, preferring one that actually animates.
  ///
  /// WebP is tried before GIF at the same size because it is 3-4x smaller for
  /// the same animation, and both are decoded by every Flutter target. The
  /// still JPEG is last, so a GIF only falls back to it when KLIPY has no
  /// animating rendition for it at all.
  String get displayUrl {
    if (animationUrl.isNotEmpty) return animationUrl;
    for (final formats in [xs, sm, md, hd]) {
      for (final variant in [formats.webp, formats.gif]) {
        if (variant != null && variant.url.isNotEmpty) return variant.url;
      }
    }
    return preview;
  }

  factory GifInfo.fromJson(Map<String, dynamic> json) {
    final files = json['files'];
    final buckets = files is Map ? files : const {};
    GifFormats bucket(String name) => GifFormats.fromJson(buckets[name]);
    return GifInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      animationUrl: json['animation_url'] as String? ?? '',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      xs: bucket('xs'),
      sm: bucket('sm'),
      md: bucket('md'),
      hd: bucket('hd'),
    );
  }

  /// True when this GIF came from the favourites list.
  ///
  /// Favourites are served from our own table with no file renditions attached,
  /// because they are rendered from a stored preview rather than re-fetched.
  bool get isFavorited => id == 0;
}

/// A page of GIFs plus the cursor state needed to ask for more.
class GifPage {
  final List<GifInfo> items;
  final int page;
  final bool hasNext;

  const GifPage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  static const empty = GifPage(items: [], page: 1, hasNext: false);

  factory GifPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return GifPage(
      items: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => GifInfo.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
    );
  }
}

/// A pack of user-generated content: the container an account's stickers and
/// emoji live in.
///
/// Packs and their items are one-to-many server rows, so the pack only names
/// its owner and carries an [itemCount] the server adds when listing.
class UgcPack {
  final int id;
  final int ownerId;
  final String displayName;
  final String description;
  final String flags;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UgcPack({
    required this.id,
    required this.ownerId,
    required this.displayName,
    this.description = '',
    this.flags = '',
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UgcPack.fromJson(Map<String, dynamic> json) => UgcPack(
    id: (json['id'] as num?)?.toInt() ?? 0,
    ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
    displayName: json['display_name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    flags: json['flags'] as String? ?? '',
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

/// One piece of user-generated content: a sticker or emoji image.
///
/// The image lives in ordinary file storage, so [url] is the same kind of
/// reference an attachment carries -- sometimes a full URL, sometimes a
/// root-relative path that [ApiService.absoluteUrl] completes. How an item is
/// drawn is decided by where its tag sits, not by a stored type: sent alone it
/// is a sticker, inside text it is an emoji.
class UgcItem {
  final int id;
  final int ownerId;
  final int packId;
  final String name;
  final String url;
  final String key;
  final int width;
  final int height;
  final int fileSize;
  final String contentType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UgcItem({
    required this.id,
    required this.ownerId,
    required this.packId,
    required this.name,
    required this.url,
    this.key = '',
    this.width = 0,
    this.height = 0,
    this.fileSize = 0,
    this.contentType = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UgcItem.fromJson(Map<String, dynamic> json) => UgcItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
    packId: (json['pack_id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
    key: json['key'] as String? ?? '',
    width: (json['width'] as num?)?.toInt() ?? 0,
    height: (json['height'] as num?)?.toInt() ?? 0,
    fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
    contentType: json['content_type'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

/// Version of [ApiService] and [WebSocketService], reported to the backend as
/// the `Qutty/<version>` product token.
const String kApiServiceVersion = '1.0';

/// Version of the app itself, reported to the backend as the
/// `QuttyFlux/<version>` product token.
const String kAppVersion = '1.0';

/// Whether this build ships through a store (App Store, Play Store, ...).
///
/// Store builds report the enforcement level their platform demands, every
/// other build reports [QuttyEnforce.no].
// ignore: constant_identifier_names
const bool StoreBuild = true;

/// The platform names the backend accepts in the User-Agent.
enum QuttyPlatform {
  ios('IOS'),
  macos('MACOS'),
  nt('NT'),
  winmob('WINMOB'),
  linux('LINUX'),
  android('ANDROID'),
  bsd('BSD'),
  other('OTHER');

  const QuttyPlatform(this.token);

  /// The spelling the backend expects.
  final String token;
}

/// The enforcement levels the backend accepts in the User-Agent.
enum QuttyEnforce {
  no('NO'),
  medium('MEDIUM'),
  high('HIGH');

  const QuttyEnforce(this.token);

  /// The spelling the backend expects.
  final String token;
}

/// The platform this build runs on, spelled the way the backend expects it.
QuttyPlatform get quttyPlatform => kIsWeb
    ? _browserPlatform
    : _platformFromOperatingSystem(Platform.operatingSystem);

/// Maps what [Platform.operatingSystem] reports onto [QuttyPlatform].
QuttyPlatform _platformFromOperatingSystem(String operatingSystem) {
  final isBsd = operatingSystem.contains('bsd');
  final isWindowsMobile =
      operatingSystem.contains('winmo') || operatingSystem.contains('wince');
  return switch (operatingSystem) {
    'ios' => QuttyPlatform.ios,
    'macos' => QuttyPlatform.macos,
    'windows' => QuttyPlatform.nt,
    'linux' => QuttyPlatform.linux,
    'android' => QuttyPlatform.android,
    // Flutter has no enum member for the BSDs or for Windows Mobile, so those
    // two are recognised from the OS name itself.
    _ when isBsd => QuttyPlatform.bsd,
    _ when isWindowsMobile => QuttyPlatform.winmob,
    // Fuchsia, and anything else dart:io knows that we do not.
    _ => QuttyPlatform.other,
  };
}

/// The platform reported on the web, where `dart:io` has no OS to report;
/// Flutter derives it from the browser's user agent.
QuttyPlatform get _browserPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => QuttyPlatform.ios,
  TargetPlatform.macOS => QuttyPlatform.macos,
  TargetPlatform.android => QuttyPlatform.android,
  TargetPlatform.linux => QuttyPlatform.linux,
  TargetPlatform.windows => QuttyPlatform.nt,
  TargetPlatform.fuchsia => QuttyPlatform.other,
};

/// The enforcement level [StoreBuild] demands of [quttyPlatform].
QuttyEnforce get quttyEnforce {
  if (!StoreBuild) return QuttyEnforce.no;
  return switch (quttyPlatform) {
    QuttyPlatform.ios || QuttyPlatform.macos => QuttyEnforce.high,
    QuttyPlatform.android => QuttyEnforce.medium,
    _ => QuttyEnforce.no,
  };
}

/// The User-Agent every request to the backend carries, for example
/// `Qutty/1.0 (IOS HIGH) QuttyFlux/1.0`.
String get userAgent =>
    'Qutty/$kApiServiceVersion '
    '(${quttyPlatform.token} ${quttyEnforce.token}) '
    'QuttyFlux/$kAppVersion';

class ApiService {
  String _baseUrl;
  String? _token;

  ApiService({String baseUrl = 'https://api.qutty.app'})
    : _baseUrl = _normalizeBaseUrl(baseUrl);

  String get baseUrl => _baseUrl;
  set baseUrl(String value) => _baseUrl = _normalizeBaseUrl(value);
  String? get token => _token;
  set token(String? value) =>
      _token = value?.trim().isEmpty == true ? null : value?.trim();

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'https://api.qutty.app';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Builds a request URI, appending [query] when given.
  ///
  /// Entries with an empty value are dropped rather than sent as `?q=`, so an
  /// empty search box does not send a blank parameter the server has to
  /// special-case.
  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/v1$path');
    if (query == null || query.isEmpty) return uri;
    final kept = <String, String>{
      for (final entry in query.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    if (kept.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...kept});
  }

  Future<String> login(String username, String password) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {'username': username, 'password': password, 'client': 'Qutty'},
      authenticated: false,
    );
    return (response['token'] as String?) ??
        (throw ApiException(500, L10n.current.tokenMissing));
  }

  Future<void> loginWithToken(String value) async {
    _token = value.trim();
    try {
      await me();
    } catch (_) {
      _token = null;
      rethrow;
    }
  }

  Future<void> register({
    required String username,
    required String password,
    String email = '',
    String displayName = '',
  }) async {
    await _request(
      'POST',
      '/auth/register',
      body: {
        'username': username,
        'password': password,
        'email': email,
        'display_name': displayName,
      },
      authenticated: false,
    );
  }

  Future<Profile> me() async =>
      Profile.fromJson(await _request('GET', '/account/me'));

  Future<List<ChatInfo>> chats() async {
    final data = await _requestList('GET', '/chats');
    return data.map(ChatInfo.fromJson).toList();
  }

  Future<SearchResults> search(String query) async => SearchResults.fromJson(
    await _request('GET', '/search?q=${Uri.encodeQueryComponent(query)}'),
  );

  Future<Profile> updateProfile(
    String displayName,
    String bio,
    String handle,
  ) async => Profile.fromJson(
    await _request(
      'PATCH',
      '/account/me',
      body: {'display_name': displayName, 'bio': bio, 'handle': handle},
    ),
  );

  Future<Profile> updateAvatar(PlatformFile file) async {
    final extension = file.name.toLowerCase().split('.').last;
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => http.MediaType('image', 'jpeg'),
      'png' => http.MediaType('image', 'png'),
      _ => throw ApiException(400, L10n.current.avatarFormatError),
    };
    final bytes = file.bytes;
    if (bytes == null) {
      throw ApiException(400, L10n.current.unableToReadImage);
    }

    final presignResponse = await _request(
      'POST',
      '/file/presign',
      body: {'filename': file.name, 'content_type': contentType.toString()},
    );
    final uploadUrl = presignResponse['upload_url'] as String?;
    if (uploadUrl == null) {
      throw ApiException(500, L10n.current.avatarUploadFailed);
    }

    final uploadRequest = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = contentType.toString()
      ..headers['User-Agent'] = userAgent;
    uploadRequest.bodyBytes = bytes;
    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ApiException(
        uploadResponse.statusCode,
        uploadBody.trim().isEmpty
            ? L10n.current.avatarUploadFailed
            : uploadBody.trim(),
      );
    }

    return Profile.fromJson(
      await _request(
        'POST',
        '/account/me/avatar',
        body: {'key': presignResponse['key'], 'url': presignResponse['url']},
      ),
    );
  }

  Future<Profile> removeAvatar() async =>
      Profile.fromJson(await _request('DELETE', '/account/me/avatar'));

  Future<ChatInfo> updateChatAvatar(int id, PlatformFile file) async {
    final extension = file.name.toLowerCase().split('.').last;
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => http.MediaType('image', 'jpeg'),
      'png' => http.MediaType('image', 'png'),
      _ => throw ApiException(400, L10n.current.avatarFormatError),
    };
    final bytes = file.bytes;
    if (bytes == null) {
      throw ApiException(400, L10n.current.unableToReadImage);
    }

    final presignResponse = await _request(
      'POST',
      '/file/presign',
      body: {'filename': file.name, 'content_type': contentType.toString()},
    );
    final uploadUrl = presignResponse['upload_url'] as String?;
    if (uploadUrl == null) {
      throw ApiException(500, L10n.current.avatarUploadFailed);
    }

    final uploadRequest = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = contentType.toString()
      ..headers['User-Agent'] = userAgent;
    uploadRequest.bodyBytes = bytes;
    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ApiException(
        uploadResponse.statusCode,
        uploadBody.trim().isEmpty
            ? L10n.current.avatarUploadFailed
            : uploadBody.trim(),
      );
    }

    return ChatInfo.fromJson(
      await _request(
        'POST',
        '/chats/$id/avatar',
        body: {'key': presignResponse['key'], 'url': presignResponse['url']},
      ),
    );
  }

  Future<ChatInfo> removeChatAvatar(int id) async =>
      ChatInfo.fromJson(await _request('DELETE', '/chats/$id/avatar'));

  Future<List<SessionInfo>> sessions() async => (await _requestList(
    'GET',
    '/auth/sessions',
  )).map(SessionInfo.fromJson).toList();

  Future<void> deleteSession(int id) async =>
      _request('DELETE', '/auth/sessions/$id');

  Future<void> deleteAccount(String username, String password) async =>
      _request(
        'DELETE',
        '/account/me',
        body: {'username': username, 'password': password},
      );

  Future<void> changePassword(String oldPassword, String newPassword) async =>
      _request(
        'PUT',
        '/account/password',
        body: {'old_password': oldPassword, 'new_password': newPassword},
      );

  Future<void> changeEmail(String email, String password) async => _request(
    'PUT',
    '/account/email',
    body: {'email': email, 'password': password},
  );

  Future<ChatInfo> chat(int id) async =>
      ChatInfo.fromJson(await _request('GET', '/chats/$id'));

  Future<VoiceToken> startVoice(int chatId) async =>
      VoiceToken.fromJson(await _request('POST', '/chats/$chatId/voice/start'));

  Future<VoiceToken> voiceToken(int chatId) async =>
      VoiceToken.fromJson(await _request('POST', '/chats/$chatId/voice/token'));

  Future<void> endVoice(int chatId) async =>
      _request('POST', '/chats/$chatId/voice/end');

  Future<void> setMicrophone(int chatId, bool enabled) async => _request(
    'PUT',
    '/chats/$chatId/voice/microphone',
    body: {'enabled': enabled},
  );

  Future<ChatInfo> previewJoin(JoinLink link) async => ChatInfo.fromJson(
    await _request(
      'GET',
      '/chats/preview?type=${link.type == JoinLinkType.handle ? 'handle' : 'invite'}&value=${Uri.encodeQueryComponent(link.value)}',
    ),
  );

  Future<List<MemberInfo>> members(int id) async => (await _requestList(
    'GET',
    '/chats/$id/members',
  )).map(MemberInfo.fromJson).toList();

  Future<ChatInfo> updateChat(
    int id, {
    String? displayName,
    String? bio,
    String? handle,
  }) async => ChatInfo.fromJson(
    await _request(
      'PATCH',
      '/chats/$id/',
      body: {'display_name': displayName, 'bio': bio, 'handle': handle},
    ),
  );

  Future<void> updateChatPermissions(int id, List<String> permissions) async =>
      _request(
        'PUT',
        '/chats/$id/permissions',
        body: {'permissions': permissions},
      );

  Future<void> updateMemberPermissions(
    int chatId,
    int userId,
    List<String> permissions, {
    String role = 'member',
  }) async => _request(
    'PUT',
    '/chats/$chatId/members/$userId/permissions',
    body: {'permissions': permissions, 'role': role},
  );

  Future<void> kickMember(int chatId, int userId) async =>
      _request('DELETE', '/chats/$chatId/members/$userId/');

  Future<void> transferChat(int chatId, int userId, String password) async =>
      _request(
        'PUT',
        '/chats/$chatId/transfer',
        body: {'user_id': userId, 'password': password},
      );

  Future<MemberInfo> selfMember(int chatId) async =>
      MemberInfo.fromJson(await _request('GET', '/chats/$chatId/me'));

  Future<void> markRead(int chatId, {int? messageId}) async =>
      _request('POST', '/chats/$chatId/read', body: {'message_id': ?messageId});

  /// Registers a push token for this install. Safe to call repeatedly: the
  /// backend upserts on the token, so a re-registration is a liveness ping
  /// rather than a duplicate row.
  ///
  /// [provider] and [bundleId] have to describe the token being registered, not
  /// this build in general: the server routes on provider, and addresses APNs
  /// pushes by bundle id.
  Future<DeviceTokenInfo> registerDevice({
    required String token,
    required String platform,
    required String provider,
    String bundleId = '',
    bool sandbox = false,
    String appVersion = '',
  }) async => DeviceTokenInfo.fromJson(
    await _request(
      'POST',
      '/devices',
      body: {
        'token': token,
        'platform': platform,
        'app_version': appVersion,
        'provider': provider,
        'sandbox': sandbox,
        'bundle_id': bundleId,
      },
    ),
  );

  Future<List<DeviceTokenInfo>> devices() async => (await _requestList(
    'GET',
    '/devices',
  )).map(DeviceTokenInfo.fromJson).toList();

  Future<void> deleteDevice(int id) => _request('DELETE', '/devices/$id');

  /// Unregisters every push token owned by the current account. Called on
  /// sign-out so a shared device stops receiving this account's messages.
  Future<void> deleteDevices() => _request('DELETE', '/devices');

  Future<MessageInfo> editMessage(
    int chatId,
    int messageId,
    String text,
  ) async => MessageInfo.fromJson(
    await _request(
      'PATCH',
      '/chats/$chatId/messages/$messageId',
      body: {'text': text},
    ),
  );

  Future<List<MessageInfo>> searchMessages(int chatId, String query) async {
    final data = await _requestListWithBody(
      'POST',
      '/chats/$chatId/messages/search',
      body: {'q': query, 'limit': 50},
    );
    return data.map(MessageInfo.fromJson).toList();
  }

  Future<Map<String, dynamic>> createInviteLink(
    int id, {
    int? expiresIn,
  }) async => _request(
    'POST',
    '/chats/$id/invite-links',
    body: {'expires_in': expiresIn},
  );

  Future<void> deleteChat(int id) async => _request('DELETE', '/chats/$id/');

  Future<void> leaveChat(int id) async =>
      _request('DELETE', '/chats/$id/leave');

  Future<void> deleteMessage(int chatId, int messageId) async =>
      _request('DELETE', '/chats/$chatId/messages/$messageId');

  Future<int> createChat(
    String displayName,
    String bio,
    String handle, {
    String chatType = 'chat',
  }) async {
    final data = await _request(
      'POST',
      '/chats/',
      body: {
        'display_name': displayName,
        'bio': bio,
        'username': handle,
        'chat_type': chatType,
      },
    );
    return (data['id'] as num).toInt();
  }

  Future<int> openDM(int userId) async {
    final data = await _request('POST', '/chats/dm', body: {'user_id': userId});
    return (data['id'] as num).toInt();
  }

  Future<Profile> user(int id) async =>
      Profile.fromJson(await _request('GET', '/account/$id'));

  Future<int> joinChat(String handle) async {
    final data = await _request(
      'POST',
      '/chats/join',
      body: {'handle': handle},
    );
    return (data['id'] as num).toInt();
  }

  Future<int> joinInvite(String code) async {
    final data = await _request('POST', '/chats/join/$code');
    return (data['id'] as num).toInt();
  }

  Future<int> joinLink(String value, bool isHandle) async =>
      isHandle ? joinChat(value) : joinInvite(value);

  Future<List<MessageInfo>> messages(int chatId) async {
    final data = await _requestList('GET', '/chats/$chatId/messages');
    return data.map(MessageInfo.fromJson).toList();
  }

  Future<FileInfo> uploadFile(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw ApiException(400, L10n.current.unableToReadFile);
    }
    final contentType = _contentTypeFor(file.name);

    final presignResponse = await _request(
      'POST',
      '/file/presign',
      body: {'filename': file.name, 'content_type': contentType.toString()},
    );
    final uploadUrl = presignResponse['upload_url'] as String?;
    if (uploadUrl == null) {
      throw ApiException(500, L10n.current.fileUploadFailed);
    }

    final uploadRequest = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = contentType.toString()
      ..headers['User-Agent'] = userAgent;
    uploadRequest.bodyBytes = bytes;
    final uploadResponse = await uploadRequest.send();
    final uploadBody = await uploadResponse.stream.bytesToString();
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw ApiException(
        uploadResponse.statusCode,
        uploadBody.trim().isEmpty
            ? L10n.current.fileUploadFailed
            : uploadBody.trim(),
      );
    }

    return FileInfo(
      key: presignResponse['key'] as String? ?? '',
      url: presignResponse['url'] as String? ?? '',
      name: file.name,
      contentType: contentType.toString(),
      size: bytes.length,
    );
  }

  Future<MessageInfo> sendMessage(
    int chatId,
    String text, {
    FileInfo? attachment,
    ForwardManifest? forward,
    int? replyTo,
  }) async => MessageInfo.fromJson(
    await _request(
      'POST',
      '/chats/$chatId/messages',
      body: {
        'text': text,
        if (attachment != null) ...{
          'attachment_key': attachment.key,
          'attachment_name': attachment.name,
          'attachment_url': attachment.url,
          'attachment_type': attachment.contentType,
          'attachment_size': attachment.size,
        },
        if (forward != null) 'forward': forward.toJson(),
        if (replyTo != null && replyTo > 0) 'reply_to': replyTo,
      },
    ),
  );

  http.MediaType _contentTypeFor(String name) {
    final extension = name.toLowerCase().split('.').last;
    final types = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    final value = types[extension] ?? 'application/octet-stream';
    return http.MediaType.parse(value);
  }

  /// The category vocabulary KLIPY publishes, used for the chip row.
  ///

  /// Searches GIFs. An empty [query] returns the default feed, which is what
  /// the picker shows before the user types anything.
  Future<GifPage> searchGifs({
    String query = '',
    int page = 1,
    int perPage = 24,
    String? locale,
  }) async {
    final response = await _request(
      'GET',
      '/gifs/search',
      query: {
        'q': query,
        'page': '$page',
        'per_page': '$perPage',
        if (locale != null && locale.isNotEmpty) 'locale': locale,
      },
    );
    return GifPage.fromJson(response);
  }

  /// The caller's saved GIFs, newest first.
  Future<GifPage> gifFavorites() async {
    return GifPage.fromJson(await _request('GET', '/gifs/favorites'));
  }

  /// Saves a GIF. Saving the same slug twice updates it rather than failing, so
  /// a double tap on an already-full heart is harmless.
  Future<void> addGifFavorite(GifInfo gif) async {
    await _request(
      'POST',
      '/gifs/favorites',
      body: {
        'slug': gif.slug,
        'title': gif.title,
        'preview': gif.preview,
        // Sent so the server can serve an animating rendition for this
        // favourite later, instead of only the still JPEG.
        'animation_url': gif.displayUrl,
        'width': gif.width,
        'height': gif.height,
      },
    );
  }

  Future<void> removeGifFavorite(String slug) async {
    await _request('DELETE', '/gifs/favorites/$slug');
  }

  /// Downloads a GIF into our own storage and returns it as a file.
  ///
  /// The picker calls this when the user taps a GIF, then sends an ordinary
  /// message with the returned [FileInfo]. That keeps Klipy out of the chat and
  /// message paths entirely: they only ever see a stored file.
  Future<FileInfo> resolveGif(String slug) async {
    return FileInfo.fromJson(
      await _request('POST', '/gifs/resolve', body: {'slug': slug}),
    );
  }

  /// Makes [url] absolute when the server handed back a root-relative path.
  ///
  /// Storage can be configured with or without a public base URL, so a stored
  /// file reference is sometimes `/v1/file/...` and sometimes a full URL.
  /// Widgets that hand a URL to `Image.network` need the absolute form either
  /// way, and this is the one place that knows the base URL.
  String absoluteUrl(String url) {
    if (url.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    return '$_baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }

  /// The UGC packs the caller owns, newest first.
  Future<List<UgcPack>> ugcPacks() async =>
      (await _requestList('GET', '/ugc/packs')).map(UgcPack.fromJson).toList();

  /// Creates an empty pack.
  Future<UgcPack> createUgcPack({
    required String displayName,
    String description = '',
  }) async => UgcPack.fromJson(
    await _request(
      'POST',
      '/ugc/packs',
      body: {'display_name': displayName, 'description': description},
    ),
  );

  Future<UgcPack> ugcPack(int id) async =>
      UgcPack.fromJson(await _request('GET', '/ugc/packs/$id'));

  Future<UgcPack> updateUgcPack(
    int id, {
    String? displayName,
    String? description,
    String? flags,
  }) async => UgcPack.fromJson(
    await _request(
      'PATCH',
      '/ugc/packs/$id',
      body: {
        'display_name': ?displayName,
        'description': ?description,
        'flags': ?flags,
      },
    ),
  );

  Future<void> deleteUgcPack(int id) async =>
      _request('DELETE', '/ugc/packs/$id');

  /// The caller's UGC items, or the items of one pack when [packId] is given.
  Future<List<UgcItem>> ugcItems({int? packId}) async {
    final path = packId == null
        ? '/ugc/items'
        : '/ugc/packs/$packId/items';
    return (await _requestList('GET', path)).map(UgcItem.fromJson).toList();
  }

  /// Resolves one item by id, which is how a `<ugc:id>` tag in a message is
  /// turned back into an image.
  Future<UgcItem> ugcItem(int id) async =>
      UgcItem.fromJson(await _request('GET', '/ugc/items/$id'));

  /// Adds an item to a pack the caller owns.
  Future<UgcItem> createUgcItem({
    required int packId,
    required String name,
    required String url,
    String key = '',
    int width = 0,
    int height = 0,
    int fileSize = 0,
    String contentType = '',
  }) async => UgcItem.fromJson(
    await _request(
      'POST',
      '/ugc/items',
      body: {
        'pack_id': packId,
        'name': name,
        'url': url,
        'key': key,
        'width': width,
        'height': height,
        'file_size': fileSize,
        'content_type': contentType,
      },
    ),
  );

  Future<UgcItem> updateUgcItem(
    int id, {
    String? name,
    String? url,
    String? key,
  }) async => UgcItem.fromJson(
    await _request(
      'PATCH',
      '/ugc/items/$id',
      body: {
        'name': ?name,
        'url': ?url,
        'key': ?key,
      },
    ),
  );

  Future<void> deleteUgcItem(int id) async =>
      _request('DELETE', '/ugc/items/$id');

  /// The items the caller has saved across every pack.
  Future<List<UgcItem>> ugcFavoriteItems() async =>
      (await _requestList(
        'GET',
        '/ugc/favorites/items',
      )).map(UgcItem.fromJson).toList();

  Future<void> addUgcFavoriteItem(int itemId) async =>
      _request('POST', '/ugc/favorites/items', body: {'item_id': itemId});

  Future<void> removeUgcFavoriteItem(int itemId) async =>
      _request('DELETE', '/ugc/favorites/items/$itemId');

  /// The packs the caller has saved.
  Future<List<UgcPack>> ugcFavoritePacks() async =>
      (await _requestList(
        'GET',
        '/ugc/favorites/packs',
      )).map(UgcPack.fromJson).toList();

  Future<void> addUgcFavoritePack(int packId) async =>
      _request('POST', '/ugc/favorites/packs', body: {'pack_id': packId});

  Future<void> removeUgcFavoritePack(int packId) async =>
      _request('DELETE', '/ugc/favorites/packs/$packId');

  /// The bots owned by the current account, oldest first.
  Future<List<BotInfo>> bots() async =>
      (await _requestList('GET', '/dev/bot')).map(BotInfo.fromJson).toList();

  /// Creates a bot owned by the current account and returns it with the
  /// session token that authenticates it.
  ///
  /// The backend refuses bots for accounts that are not human accounts
  /// themselves, answering `bots cant have bots` with a 403, and the token only
  /// exists because it is handed out here and nowhere else.
  Future<CreatedBot> createBot({
    required String displayName,
    String bio = '',
    String handle = '',
  }) async {
    final response = await _request(
      'POST',
      '/dev/bot',
      body: {'display_name': displayName, 'bio': bio, 'handle': handle},
    );
    return CreatedBot(
      bot: BotInfo.fromJson((response['bot'] as Map<String, dynamic>?) ?? {}),
      token: response['token'] as String? ?? '',
    );
  }

  /// Loads one of the caller's own bots by id.
  Future<BotInfo> bot(int id) async =>
      BotInfo.fromJson(await _request('GET', '/dev/bot/$id'));

  /// Updates the display name, bio or avatar of one of the caller's own bots.
  Future<BotInfo> updateBot(
    int id, {
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async => BotInfo.fromJson(
    await _request(
      'PATCH',
      '/dev/bot/$id',
      body: {'display_name': displayName, 'bio': bio, 'avatar_url': avatarUrl},
    ),
  );

  /// Deletes one of the caller's own bots, together with its developer app and
  /// its session.
  Future<void> deleteBot(int id) async => _request('DELETE', '/dev/bot/$id');

  /// Rotates the token of one of the caller's own bots, returning the fresh
  /// token. The old token stops working as soon as the rotation lands, and the
  /// new one is only ever handed out here.
  Future<String> resetBotToken(int id) async {
    final response = await _request(
      'POST',
      '/dev/bot/$id/reset-token',
      body: <String, dynamic>{},
    );
    return response['token'] as String? ?? '';
  }

  Future<void> logout() async {
    if (_token != null) {
      await _request('DELETE', '/auth/sessions/current');
    }
    _token = null;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final response = await _send(
      method,
      path,
      body: body,
      query: query,
      authenticated: authenticated,
    );
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _requestList(
    String method,
    String path,
  ) async {
    final response = await _send(method, path);
    return _decodeList(response.body);
  }

  Future<List<Map<String, dynamic>>> _requestListWithBody(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(method, path, body: body);
    return _decodeList(response.body);
  }

  List<Map<String, dynamic>> _decodeList(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
    };
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final encoded = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await http.get(_uri(path, query), headers: headers),
      'POST' => await http.post(
        _uri(path, query),
        headers: headers,
        body: encoded,
      ),
      'DELETE' => await http.delete(_uri(path, query), headers: headers),
      'PATCH' => await http.patch(
        _uri(path, query),
        headers: headers,
        body: encoded,
      ),
      'PUT' => await http.put(
        _uri(path, query),
        headers: headers,
        body: encoded,
      ),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.trim().isEmpty
          ? L10n.current.requestFailed
          : response.body.trim();
      throw ApiException(response.statusCode, '$method $path: $detail');
    }
    return response;
  }
}
