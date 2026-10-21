/// A notification the user should see, already resolved into display strings.
class NotificationPayload {
  final String title;
  final String body;
  final int? chatId;

  /// Identifies the message this notification came from.
  ///
  /// A message can arrive twice -- once over the socket and once over a push
  /// transport -- and the backend stamps the same value in both, so this is
  /// what lets the app show one alert instead of two.
  final String? messageId;

  const NotificationPayload({
    required this.title,
    required this.body,
    this.chatId,
    this.messageId,
  });
}
