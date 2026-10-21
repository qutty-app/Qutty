import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/services/notification_service.dart';

void main() {
  late AppManager manager;
  late NotificationService service;

  setUp(() {
    manager = AppManager.instance;
    service = NotificationService.instance;
    // The rules are per-manager state, so each test starts from a known point.
    manager.notificationsEnabled = true;
    manager.setForeground(true);
    manager.setActiveChat(null);
  });

  tearDown(() {
    manager.notificationsEnabled = true;
    manager.setForeground(true);
    manager.setActiveChat(null);
  });

  group('suppression rule', () {
    test('stays quiet for the chat the user is reading', () {
      manager.setActiveChat(11);

      expect(
        manager.shouldNotifyForChatId(11),
        isFalse,
        reason: 'the conversation is already on screen',
      );
    });

    test('alerts for a different chat while reading one', () {
      manager.setActiveChat(11);

      expect(manager.shouldNotifyForChatId(12), isTrue);
    });

    test('alerts on the chat list, where no chat is active', () {
      expect(manager.shouldNotifyForChatId(11), isTrue);
    });

    test('alerts for the open chat once the app is backgrounded', () {
      manager.setActiveChat(11);
      manager.setForeground(false);

      expect(
        manager.shouldNotifyForChatId(11),
        isTrue,
        reason: 'a backgrounded app is not displaying the conversation',
      );
    });

    test('the master switch silences every case', () {
      manager.setActiveChat(99);
      manager.notificationsEnabled = false;

      expect(manager.shouldNotifyForChatId(99), isFalse);
      expect(manager.shouldNotifyForChatId(12), isFalse);

      manager.setForeground(false);
      expect(manager.shouldNotifyForChatId(12), isFalse);
    });
  });

  group('service rule', () {
    test('treats a null active chat as no chat on screen', () {
      expect(
        service.shouldNotify(isForeground: true, activeChatId: null, chatId: 5),
        isTrue,
      );
    });

    test('only suppresses the exact matching chat', () {
      expect(
        service.shouldNotify(isForeground: true, activeChatId: 5, chatId: 5),
        isFalse,
      );
      expect(
        service.shouldNotify(isForeground: true, activeChatId: 5, chatId: 6),
        isTrue,
      );
    });
  });
}
