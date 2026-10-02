import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification_channel.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_notification_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_notification_exception.dart';

void main() {
  group('HrNotification Domain Entity Tests (HR-9.7)', () {
    final now = DateTime.utc(2026, 2, 5, 12, 0);

    test('creates valid notification with UTC timestamps and default unread state', () {
      final notif = HrNotification(
        id: 'notif_101',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        title: 'New Request',
        body: 'Request submitted for Attendance Record att_101.',
        target: HrApprovalTarget.attendanceRecord('att_101'),
        requestId: 'appr_req_1',
        createdAt: now,
      );

      expect(notif.id, equals('notif_101'));
      expect(notif.recipientUserId, equals('usr_admin'));
      expect(notif.type, equals(HrNotificationType.approvalRequestSubmitted));
      expect(notif.channel, equals(HrNotificationChannel.inApp));
      expect(notif.isRead, isFalse);
      expect(notif.readAt, isNull);
      expect(notif.createdAt, equals(now));
    });

    test('normalizes non-UTC timestamps to UTC', () {
      final localTime = DateTime(2026, 2, 5, 12, 0);
      final notif = HrNotification(
        id: 'notif_102',
        recipientUserId: 'usr_hr',
        type: HrNotificationType.approvalDecisionRecorded,
        title: 'Decision Recorded',
        body: 'Your request was approved.',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        requestId: 'appr_req_3',
        createdAt: localTime,
      );

      expect(notif.createdAt.isUtc, isTrue);
    });

    test('markAsRead updates isRead to true and records readAt timestamp', () {
      final notif = HrNotification(
        id: 'notif_103',
        recipientUserId: 'usr_hr',
        type: HrNotificationType.approvalDecisionRecorded,
        title: 'Decision Recorded',
        body: 'Your request was approved.',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        requestId: 'appr_req_3',
        createdAt: now,
      );

      final readTime = DateTime.utc(2026, 2, 5, 12, 15);
      final updated = notif.markAsRead(timestamp: readTime);

      expect(updated.isRead, isTrue);
      expect(updated.readAt, equals(readTime));
      // Original remains unchanged (immutability)
      expect(notif.isRead, isFalse);
    });

    test('copyWith produces isolated defensive copy with overrides', () {
      final notif = HrNotification(
        id: 'notif_104',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        title: 'New Request',
        body: 'Body text',
        target: HrApprovalTarget.employeeDocument('doc_1'),
        requestId: 'appr_req_2',
        createdAt: now,
      );

      final copy = notif.copyWith(title: 'Updated Title', isRead: true);

      expect(copy.title, equals('Updated Title'));
      expect(copy.isRead, isTrue);
      expect(copy.id, equals(notif.id));
      expect(copy.recipientUserId, equals(notif.recipientUserId));
    });

    test('value equality and hashCode adhere to domain invariants', () {
      final notif1 = HrNotification(
        id: 'notif_105',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        title: 'Title',
        body: 'Body',
        target: HrApprovalTarget.attendanceRecord('att_101'),
        requestId: 'appr_req_1',
        createdAt: now,
      );

      final notif2 = HrNotification(
        id: 'notif_105',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        title: 'Title',
        body: 'Body',
        target: HrApprovalTarget.attendanceRecord('att_101'),
        requestId: 'appr_req_1',
        createdAt: now,
      );

      expect(notif1, equals(notif2));
      expect(notif1.hashCode, equals(notif2.hashCode));
    });

    test('HrNotificationException formats message and code properly', () {
      const ex = HrNotificationException(
        'Unauthorized access',
        code: HrNotificationException.unauthorizedRecipient,
      );

      expect(ex.code, equals(HrNotificationException.unauthorizedRecipient));
      expect(ex.toString(), contains('unauthorized_recipient'));
      expect(ex.toString(), contains('Unauthorized access'));
    });
  });
}
