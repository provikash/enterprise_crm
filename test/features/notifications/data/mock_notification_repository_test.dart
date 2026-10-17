import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/domain/inputs/create_notification_input.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';

void main() {
  group('MockNotificationRepository', () {
    late MockNotificationStore store;
    late MockNotificationRepository repository;

    setUp(() {
      store = MockNotificationStore();
      repository = MockNotificationRepository(store);
    });

    test('getNotifications returns initial seed notifications for user', () async {
      final notifs = await repository.getNotifications(recipientUserId: 'usr_admin');
      expect(notifs.length, 3);
    });

    test('getNotifications filters unread only', () async {
      final unread = await repository.getNotifications(
        recipientUserId: 'usr_admin',
        unreadOnly: true,
      );
      expect(unread.length, 2);
      expect(unread.every((n) => !n.isRead), isTrue);
    });

    test('getNotifications filters by category', () async {
      final alerts = await repository.getNotifications(
        recipientUserId: 'usr_admin',
        category: NotificationCategory.systemAlert,
      );
      expect(alerts.length, 1);
      expect(alerts.first.id, 'notif-103');
    });

    test('getUnreadCount returns correct unread count', () async {
      final count = await repository.getUnreadCount('usr_admin');
      expect(count, 2);
    });

    test('markAsRead marks specific notification as read and updates count', () async {
      await repository.markAsRead(notificationId: 'notif-101', userId: 'usr_admin');
      final count = await repository.getUnreadCount('usr_admin');
      expect(count, 1);

      final notifs = await repository.getNotifications(recipientUserId: 'usr_admin');
      final notif = notifs.firstWhere((n) => n.id == 'notif-101');
      expect(notif.isRead, isTrue);
      expect(notif.readAt, isNotNull);
    });

    test('markAllAsRead marks all user notifications as read', () async {
      await repository.markAllAsRead('usr_admin');
      final count = await repository.getUnreadCount('usr_admin');
      expect(count, 0);
    });

    test('clearNotification removes notification from inbox', () async {
      await repository.clearNotification(notificationId: 'notif-103', userId: 'usr_admin');
      final notifs = await repository.getNotifications(recipientUserId: 'usr_admin');
      expect(notifs.any((n) => n.id == 'notif-103'), isFalse);
    });

    test('dispatchNotification creates and returns new notification', () async {
      final input = CreateNotificationInput(
        recipientUserId: 'usr_admin',
        title: 'Discount Threshold Exceeded',
        body: 'Lead #LD-44 requires director exception approval.',
        category: NotificationCategory.approvalRequest,
        priority: NotificationPriority.critical,
        referenceModule: CrmModule.leadManagement,
        referenceEntityType: 'lead',
        referenceEntityId: 'LD-44',
      );

      final created = await repository.dispatchNotification(input);
      expect(created.id, startsWith('notif-'));
      expect(created.recipientUserId, 'usr_admin');
      expect(created.isRead, isFalse);

      final count = await repository.getUnreadCount('usr_admin');
      expect(count, 3);
    });

    test('watchNotifications emits reactive stream updates', () async {
      final stream = repository.watchNotifications('usr_admin');

      expectLater(
        stream,
        emitsInOrder([
          predicate<dynamic>((list) => list is List && list.length == 4),
        ]),
      );

      await repository.dispatchNotification(
        CreateNotificationInput(
          recipientUserId: 'usr_admin',
          title: 'Streaming Test Alert',
          body: 'Stream test body',
        ),
      );
    });
  });
}
