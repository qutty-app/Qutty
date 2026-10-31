/// What the app keeps on the device for offline use.
///
/// The two halves are counted apart because they are cleared apart: the media
/// cache holds pictures and attachments, the offline store holds the
/// conversations, the messages and the people.
class CacheOverview {
  /// How many media files are stored.
  final int mediaFiles;

  /// How much space the media files take.
  final int mediaBytes;

  /// The largest the media cache may grow.
  final int mediaLimitBytes;

  /// How many conversations are stored.
  final int chatCount;

  /// How many messages are stored across every conversation.
  final int messageCount;

  /// How many people are stored.
  final int profileCount;

  /// How much space the stored conversations take.
  final int chatBytes;

  const CacheOverview({
    required this.mediaFiles,
    required this.mediaBytes,
    required this.mediaLimitBytes,
    required this.chatCount,
    required this.messageCount,
    required this.profileCount,
    required this.chatBytes,
  });

  static const empty = CacheOverview(
    mediaFiles: 0,
    mediaBytes: 0,
    mediaLimitBytes: 0,
    chatCount: 0,
    messageCount: 0,
    profileCount: 0,
    chatBytes: 0,
  );

  /// How much space the whole cache takes.
  int get totalBytes => mediaBytes + chatBytes;
}
