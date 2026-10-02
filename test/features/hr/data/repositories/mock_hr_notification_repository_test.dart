import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_notification_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_notification_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_notification_exception.dart';

void main() {
  group('MockHrNotificationRepository Tests (HR-9.7)', () {
    late MockHrNotificationStore store;
    late MockHrNotificationRepository repository;

    setUp(() {
      store = MockHrNotificationStore(seedInitialData: true);
      repository = MockHrNotificationRepository(store: store);
    });

    test('retrieves seeded notifications for usr_admin ordered newest first', () async {
      final notifs = await repository.getNotificationsForUser('usr_admin');

      expect(notifs.length, equals(2));
      expect(notifs.first.id, equals('notif_003')); // 11:00 UTC
      expect(notifs.last.id, equals('notif_001')); // 09:30 UTC
      expect(notifs.every((n) => n.recipientUserId == 'usr_admin'), isTrue);
    });

    test('retrieves unread count accurately for user', () async {
      final adminUnread = await repository.getUnreadCount('usr_admin');
      expect(adminUnread, equals(2));

      final hrUnread = await repository.getUnreadCount('usr_hr');
      expect(hrUnread, equals(0)); // notif_002 is seeded as read
    });

    test('getUnreadNotificationsForUser returns only unread items', () async {
      final unread = await repository.getUnreadNotificationsForUser('usr_admin');
      expect(unread.length, equals(2));
      expect(unread.every((n) => !n.isRead), isTrue);

      final hrUnread = await repository.getUnreadNotificationsForUser('usr_hr');
      expect(hrUnread, isEmpty);
    });

    test('sendNotification persists new notification and returns defensive clone', () async {
      final newNotif = HrNotification(
        id: 'notif_999',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        title: 'New Request Submitted',
        body: 'Generic summary',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        requestId: 'appr_req_10',
        createdAt: DateTime.utc(2026, 2, 6, 8, 0),
      );

      final saved = await repository.sendNotification(newNotif);
      expect(saved.id, equals('notif_999'));

      final list = await repository.getNotificationsForUser('usr_admin');
      expect(list.length, equals(3));
      expect(list.first.id, equals('notif_999')); // Newest first
    });

    test('markAsRead marks notification as read and reduces unread count', () async {
      final updated = await repository.markAsRead('notif_001', recipientUserId: 'usr_admin');

      expect(updated.isRead, isTrue);
      expect(updated.readAt, isNotNull);

      final newCount = await repository.getUnreadCount('usr_admin');
      expect(newCount, equals(1));
    });

    test('markAsRead throws unauthorizedRecipient if notification belongs to another user', () async {
      expect(
        () => repository.markAsRead('notif_001', recipientUserId: 'usr_hr'),
        throwsA(
          isA<HrNotificationException>().having(
            (e) => e.code,
            'code',
            equals(HrNotificationException.unauthorizedRecipient),
          ),
        ),
      );
    });

    test('markAsRead throws notificationNotFound if ID does not exist', () async {
      expect(
        () => repository.markAsRead('notif_non_existent', recipientUserId: 'usr_admin'),
        throwsA(
          isA<HrNotificationException>().having(
            (e) => e.code,
            'code',
            equals(HrNotificationException.notificationNotFound),
          ),
        ),
      );
    });

    test('markAllAsRead marks all unread notifications for recipient as read', () async {
      await repository.markAllAsRead(recipientUserId: 'usr_admin');

      final count = await repository.getUnreadCount('usr_admin');
      expect(count, equals(0));

      final unread = await repository.getUnreadNotificationsForUser('usr_admin');
      expect(unread, isEmpty);
    });

    test('clearUserNotifications clears notifications only for target recipient', () async {
      await repository.clearUserNotifications(recipientUserId: 'usr_admin');

      final adminNotifs = await repository.getNotificationsForUser('usr_admin');
      expect(adminNotifs, isEmpty);

      // usr_hr's notification remains intact
      final hrNotifs = await repository.getNotificationsForUser('usr_hr');
      expect(hrNotifs.length, equals(1));
    });

    test('getNotificationById enforces recipient authorization', () async {
      final notif = await repository.getNotificationById('notif_001', recipientUserId: 'usr_admin');
      expect(notif, isNotNull);
      expect(notif!.id, equals('notif_001'));

      expect(
        () => repository.getNotificationById('notif_001', recipientUserId: 'usr_hr'),
        throwsA(
          isA<HrNotificationException>().having(
            (e) => e.code,
            'code',
            equals(HrNotificationException.unauthorizedRecipient),
          ),
        ),
      );
    });

    test('simulated failure throws deliveryFailed', () async {
      store.simulateFailure = true;

      expect(
        () => repository.getNotificationsForUser('usr_admin'),
        throwsA(
          isA<HrNotificationException>().having(
            (e) => e.code,
            'code',
            equals(HrNotificationException.deliveryFailed),
          ),
        ),
      );
    });
  });
}
