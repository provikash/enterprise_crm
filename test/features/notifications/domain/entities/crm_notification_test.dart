import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_channel.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrmNotification Domain Entity', () {
    final now = DateTime.utc(2026, 10, 16, 12, 0);

    final notification = CrmNotification(
      id: 'notif-001',
      recipientUserId: 'usr-42',
      title: 'Approval Required: PO-9821',
      body: 'Purchase Order #PO-9821 requires your executive approval.',
      category: NotificationCategory.approvalRequest,
      priority: NotificationPriority.critical,
      referenceModule: CrmModule.purchase,
      referenceEntityType: 'purchase_order',
      referenceEntityId: 'po-9821',
      isRead: false,
      createdAt: now,
      payload: const {'amount': 25000.0},
    );

    test('instantiates with expected attributes', () {
      expect(notification.id, 'notif-001');
      expect(notification.recipientUserId, 'usr-42');
      expect(notification.title, 'Approval Required: PO-9821');
      expect(
        notification.body,
        'Purchase Order #PO-9821 requires your executive approval.',
      );
      expect(notification.category, NotificationCategory.approvalRequest);
      expect(notification.priority, NotificationPriority.critical);
      expect(notification.referenceModule, CrmModule.purchase);
      expect(notification.referenceEntityType, 'purchase_order');
      expect(notification.referenceEntityId, 'po-9821');
      expect(notification.isRead, isFalse);
      expect(notification.readAt, isNull);
      expect(notification.createdAt, now);
      expect(notification.payload['amount'], 25000.0);
    });

    test('defensively exposes unmodifiable payload', () {
      expect(
        () => (notification.payload as dynamic)['key'] = 'val',
        throwsUnsupportedError,
      );
    });

    test('copyWith produces updated notification correctly', () {
      final readTime = now.add(const Duration(minutes: 5));
      final readNotification = notification.copyWith(
        isRead: true,
        readAt: readTime,
      );

      expect(readNotification.id, notification.id);
      expect(readNotification.isRead, isTrue);
      expect(readNotification.readAt, readTime);
      expect(readNotification.title, notification.title);
    });

    test('equality and hashCode evaluate properly', () {
      final duplicate = CrmNotification(
        id: 'notif-001',
        recipientUserId: 'usr-42',
        title: 'Approval Required: PO-9821',
        body: 'Purchase Order #PO-9821 requires your executive approval.',
        category: NotificationCategory.approvalRequest,
        priority: NotificationPriority.critical,
        isRead: false,
        createdAt: now,
      );

      expect(notification == duplicate, isTrue);
      expect(notification.hashCode, duplicate.hashCode);
    });
  });

  group('NotificationCategory Enum', () {
    test('displays human readable names', () {
      expect(
        NotificationCategory.approvalRequest.displayName,
        'Approval Request',
      );
      expect(
        NotificationCategory.approvalDecision.displayName,
        'Approval Decision',
      );
      expect(NotificationCategory.systemAlert.displayName, 'System Alert');
      expect(NotificationCategory.announcement.displayName, 'Announcement');
      expect(NotificationCategory.reminder.displayName, 'Reminder');
    });
  });

  group('NotificationPriority Enum', () {
    test('displays correct labels', () {
      expect(NotificationPriority.info.label, 'Info');
      expect(NotificationPriority.success.label, 'Success');
      expect(NotificationPriority.warning.label, 'Warning');
      expect(NotificationPriority.critical.label, 'Critical');
    });
  });

  group('NotificationChannel Enum', () {
    test('displays correct channel name', () {
      expect(NotificationChannel.inApp.displayName, 'In-App');
    });
  });
}
