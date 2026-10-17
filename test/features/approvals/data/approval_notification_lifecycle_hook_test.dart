import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/approvals/domain/inputs/create_approval_request_input.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/services/notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockApprovalStore approvalStore;
  late MockNotificationStore notifStore;
  late MockNotificationRepository notifRepo;
  late DefaultNotificationDispatcher dispatcher;
  late MockApprovalRepository approvalRepo;

  final adminUser = CurrentUser(
    id: 'usr-admin',
    accountType: AccountType.admin,
    modules: {CrmModule.approvalsNotifications},
    permissions: const {},
    displayName: 'Admin User',
  );

  setUp(() {
    approvalStore = MockApprovalStore();
    notifStore = MockNotificationStore();
    notifRepo = MockNotificationRepository(notifStore);
    dispatcher = DefaultNotificationDispatcher(notifRepo);
    approvalRepo = MockApprovalRepository(approvalStore, dispatcher);
  });

  test('submitRequest automatically dispatches notification to active step approver',
      () async {
    final input = CreateApprovalRequestInput(
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: 'po-test-99',
      entityTitle: 'Test PO #99',
      requesterId: 'usr-requester',
      requesterName: 'Requester Bob',
      priority: ApprovalPriority.high,
      steps: [
        ApprovalStep(
          id: 'step-test-1',
          stepOrder: 1,
          title: 'Manager Review',
          assignedUserId: 'usr-manager-1',
          assignedUserName: 'Manager Mary',
          status: ApprovalStepStatus.pending,
        ),
      ],
    );

    final created = await approvalRepo.submitRequest(input);

    // Verify notification was dispatched to 'usr-manager-1'
    final managerNotifs =
        await notifRepo.getNotifications(recipientUserId: 'usr-manager-1');
    expect(
      managerNotifs.any(
        (n) =>
            n.category == NotificationCategory.approvalRequest &&
            n.title.contains(created.requestNumber),
      ),
      isTrue,
    );
  });

  test('approveRequest automatically dispatches approval decision notification to requester',
      () async {
    final updated = await approvalRepo.approveRequest(
      requestId: 'appr-001',
      actor: adminUser,
      comment: 'Approved by administrator.',
    );

    // Verify notification was dispatched to the requester of appr-001
    final requesterNotifs = await notifRepo.getNotifications(
      recipientUserId: updated.requesterId,
    );

    expect(
      requesterNotifs.any(
        (n) =>
            n.category == NotificationCategory.approvalDecision &&
            n.title.contains('Approved') &&
            n.title.contains(updated.requestNumber),
      ),
      isTrue,
    );
  });

  test('rejectRequest automatically dispatches rejection decision notification to requester',
      () async {
    final updated = await approvalRepo.rejectRequest(
      requestId: 'appr-002',
      actor: adminUser,
      rejectionReason: 'Exceeds budget cap.',
    );

    final requesterNotifs = await notifRepo.getNotifications(
      recipientUserId: updated.requesterId,
    );

    expect(
      requesterNotifs.any(
        (n) =>
            n.category == NotificationCategory.approvalDecision &&
            n.title.contains('Rejected') &&
            n.body.contains('Exceeds budget cap.'),
      ),
      isTrue,
    );
  });
}
