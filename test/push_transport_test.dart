import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/services/push_transport.dart';

void main() {
  group('decodeMessageData', () {
    NotificationPayload? decode(Map<String, Object?> data) =>
        decodeMessageData(data);

    test('decodes a message payload from the backend', () {
      final payload = decode({
        'type': 'message',
        'chat_id': '42',
        'title': 'Alice',
        'text': 'hi',
        'message_id': '9001',
      });

      expect(payload, isNotNull);
      expect(payload!.chatId, 42);
      expect(payload.title, 'Alice');
      expect(payload.body, 'hi');
      expect(
        payload.messageId,
        '9001',
        reason: 'the message id is what collapses a socket and a push pair',
      );
    });

    test('falls back to the sender when there is no text', () {
      final payload = decode({
        'type': 'message',
        'chat_id': '7',
        'title': 'Alice',
        'sender_name': 'Alice',
      });

      expect(payload!.body, 'Alice');
    });

    test('describes an attachment with no text', () {
      final payload = decode({'type': 'message', 'chat_id': '7'});

      expect(payload!.body, 'New message');
    });

    test('accepts a numeric chat id, which arrives typed from APNs', () {
      // APNs hands the payload over an untyped platform-channel map, so a value
      // that was a number in JSON arrives as a Dart num rather than a String.
      final payload = decode({'type': 'message', 'chat_id': 42});

      expect(payload!.chatId, 42);
    });

    test('ignores a payload with no chat to route to', () {
      expect(decode({'type': 'message'}), isNull);
      expect(decode({'type': 'message', 'chat_id': 'not-a-number'}), isNull);
    });

    test('ignores an unknown notification type', () {
      expect(
        decode({'type': 'reaction', 'chat_id': '42'}),
        isNull,
        reason: 'an unhandled type must not appear as an empty alert',
      );
    });

    test('ignores an empty payload', () {
      expect(decode({}), isNull);
    });
  });

  group('transport selection', () {
    test('round-trips through the persisted name', () {
      // The stored value is the enum name, so a rename would orphan every
      // existing selection.
      for (final transport in PushTransport.values) {
        expect(PushTransport.fromName(transport.name), transport);
      }
    });

    test('ignores an unknown or missing stored name', () {
      expect(PushTransport.fromName('hms'), isNull);
      expect(PushTransport.fromName(null), isNull);
    });

    test('exposes the requested display labels', () {
      expect(PushTransport.apns.label, 'APN');
      expect(PushTransport.websocket.label, 'Websocket');
    });
  });
}
