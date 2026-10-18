import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/domain/services/notification_dispatcher.dart';
import 'package:enterprise_crm/features/notifications/domain/inputs/create_notification_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockNotificationStore store;
  late MockNotificationRepository repo;
  late DefaultNotificationDispatcher dispatcher;

  setUp(() {
    store = MockNotificationStore();
    repo = MockNotificationRepository(store);
    dispatcher = DefaultNotificationDispatcher(repo);
  });

  test('dispatch delegates to repository and creates notification', () async {
    const input = CreateNotificationInput(
      recipientUserId: 'usr-admin',
      title: 'Test Notification',
      body: 'This is a test notification message.',
      category: NotificationCategory.announcement,
      priority: NotificationPriority.info,
    );

    final result = await dispatcher.dispatch(input);
    expect(result.id, isNotEmpty);
    expect(result.recipientUserId, 'usr-admin');
    expect(result.title, 'Test Notification');
    expect(result.category, NotificationCategory.announcement);
  });

  test('notifyApprovalRequested creates approvalRequest notification for approver',
      () async {
    final request = ApprovalRequest(
      id: 'req-100',
      requestNumber: 'REQ-2026-0100',
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: 'po-55',
      entityTitle: 'Purchase Order #55',
      requesterId: 'usr-requester',
      requesterName: 'Alice',
      status: ApprovalStatus.pending,
      priority: ApprovalPriority.urgent,
      submittedAt: DateTime(2026, 3, 10),
    );

    final notif = await dispatcher.notifyApprovalRequested(
      request: request,
      approverUserId: 'usr-approver-99',
    );

    expect(notif.recipientUserId, 'usr-approver-99');
    expect(notif.category, NotificationCategory.approvalRequest);
    expect(notif.priority, NotificationPriority.critical);
    expect(notif.title, contains('REQ-2026-0100'));
    expect(notif.body, contains('Purchase Order #55'));
    expect(notif.payload['requestId'], 'req-100');
  });

  test('notifyApprovalDecision dispatches decision alert to requester', () async {
    final request = ApprovalRequest(
      id: 'req-100',
      requestNumber: 'REQ-2026-0100',
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: 'po-55',
      entityTitle: 'Purchase Order #55',
      requesterId: 'usr-requester-77',
      requesterName: 'Alice',
      status: ApprovalStatus.approved,
      priority: ApprovalPriority.normal,
      submittedAt: DateTime(2026, 3, 10),
    );

    final notif = await dispatcher.notifyApprovalDecision(
      request: request,
      decision: 'Approved',
      notes: 'Sign-off complete.',
    );

    expect(notif.recipientUserId, 'usr-requester-77');
    expect(notif.category, NotificationCategory.approvalDecision);
    expect(notif.priority, NotificationPriority.success);
    expect(notif.body, contains('Remarks: "Sign-off complete."'));
  });

  test('notifySystemAlert dispatches general operational notification', () async {
    final notif = await dispatcher.notifySystemAlert(
      recipientUserId: 'usr-admin',
      title: 'Database Backup',
      message: 'Nightly backup finished with 0 errors.',
      priority: NotificationPriority.info,
    );

    expect(notif.recipientUserId, 'usr-admin');
    expect(notif.category, NotificationCategory.systemAlert);
    expect(notif.title, 'Database Backup');
  });
}
