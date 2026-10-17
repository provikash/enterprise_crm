import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/data/services/default_approval_bridge.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/policies/approvals_access_policy.dart';
import 'package:enterprise_crm/features/approvals/domain/services/approval_export_service.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_action_cubit.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_action_state.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_inbox_cubit.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_inbox_state.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/services/notification_dispatcher.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AN-10 Approvals & Notifications End-to-End Security & Regression Tests', () {
    late MockApprovalStore approvalStore;
    late MockNotificationStore notificationStore;
    late MockNotificationRepository notificationRepo;
    late DefaultNotificationDispatcher dispatcher;
    late MockApprovalRepository approvalRepo;
    late DefaultApprovalBridge bridge;

    final adminUser = const CurrentUser(
      id: 'usr-admin',
      accountType: AccountType.admin,
      displayName: 'System Admin',
      modules: {CrmModule.approvalsNotifications},
      permissions: {
        CrmPermissions.approvalsView,
        CrmPermissions.approvalsAction,
        CrmPermissions.approvalsSubmit,
        CrmPermissions.approvalsExport,
        CrmPermissions.notificationsView,
        CrmPermissions.notificationsManage,
      },
    );

    final requesterUser = const CurrentUser(
      id: 'usr-requester',
      accountType: AccountType.user,
      displayName: 'Requester Alice',
      modules: {
        CrmModule.approvalsNotifications,
        CrmModule.purchase,
      },
      permissions: {
        CrmPermissions.approvalsView,
        CrmPermissions.approvalsSubmit,
        CrmPermissions.notificationsView,
      },
    );

    final approverUser = const CurrentUser(
      id: 'usr-approver',
      accountType: AccountType.user,
      displayName: 'Approver Bob',
      modules: {
        CrmModule.approvalsNotifications,
        CrmModule.purchase,
      },
      permissions: {
        CrmPermissions.approvalsView,
        CrmPermissions.approvalsAction,
        CrmPermissions.notificationsView,
        CrmPermissions.notificationsManage,
      },
    );

    final outsiderUser = const CurrentUser(
      id: 'usr-outsider',
      accountType: AccountType.user,
      displayName: 'Outsider Dave',
      modules: {CrmModule.calling},
      permissions: {},
    );

    setUp(() {
      approvalStore = MockApprovalStore();
      notificationStore = MockNotificationStore();
      notificationRepo = MockNotificationRepository(notificationStore);
      dispatcher = DefaultNotificationDispatcher(notificationRepo);
      approvalRepo = MockApprovalRepository(approvalStore, dispatcher);
      bridge = DefaultApprovalBridge(
        repository: approvalRepo,
        notificationDispatcher: dispatcher,
      );
    });

    test('Access Policy Matrix: strict enforcement across all roles and permissions', () {
      // Module access
      expect(ApprovalsAccessPolicy.canAccessModule(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canAccessModule(requesterUser), isTrue);
      expect(ApprovalsAccessPolicy.canAccessModule(approverUser), isTrue);
      expect(ApprovalsAccessPolicy.canAccessModule(outsiderUser), isFalse);

      // Submit permission
      expect(ApprovalsAccessPolicy.canSubmitRequest(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canSubmitRequest(requesterUser), isTrue);
      expect(ApprovalsAccessPolicy.canSubmitRequest(approverUser), isFalse);

      // Export permission
      expect(ApprovalsAccessPolicy.canExport(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canExport(requesterUser), isFalse);
      expect(ApprovalsAccessPolicy.canExport(approverUser), isFalse);

      // Notification management
      expect(ApprovalsAccessPolicy.canManageNotifications(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canManageNotifications(approverUser), isTrue);
      expect(ApprovalsAccessPolicy.canManageNotifications(requesterUser), isFalse);
    });

    test('Maker-Checker Invariant: non-admin submitter cannot approve own request', () async {
      final req = await bridge.submitPurchaseOrderApproval(
        poNumber: 'PO-770',
        vendorName: 'Acme Steel',
        totalAmount: 50000.0,
        requester: requesterUser,
      );

      // Requester cannot approve their own submission
      expect(ApprovalsAccessPolicy.canPerformDecision(requesterUser, req), isFalse);

      // Approver can approve
      expect(ApprovalsAccessPolicy.canPerformDecision(approverUser, req), isTrue);

      // Admin can approve
      expect(ApprovalsAccessPolicy.canPerformDecision(adminUser, req), isTrue);
    });

    test('Session Isolation & Recipient Data Privacy: users cannot read each others notifications', () async {
      // Dispatch alert to requesterUser
      await dispatcher.notifySystemAlert(
        recipientUserId: requesterUser.id,
        title: 'Secret Alert for Alice',
        message: 'Confidential message',
      );

      // Dispatch alert to approverUser
      await dispatcher.notifySystemAlert(
        recipientUserId: approverUser.id,
        title: 'Secret Alert for Bob',
        message: 'Confidential message',
      );

      final aliceNotifs = await notificationRepo.getNotifications(
        recipientUserId: requesterUser.id,
      );
      final bobNotifs = await notificationRepo.getNotifications(
        recipientUserId: approverUser.id,
      );

      expect(aliceNotifs.any((n) => n.title == 'Secret Alert for Alice'), isTrue);
      expect(aliceNotifs.any((n) => n.title == 'Secret Alert for Bob'), isFalse);

      expect(bobNotifs.any((n) => n.title == 'Secret Alert for Bob'), isTrue);
      expect(bobNotifs.any((n) => n.title == 'Secret Alert for Alice'), isFalse);
    });

    test('Session Teardown: notification stream cancels cleanly on user logout', () async {
      final notifCubit = NotificationCubit(notificationRepo);

      notifCubit.watchNotifications(approverUser.id);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifCubit.state is NotificationLoaded, isTrue);

      // Simulate logout: close cubit
      await notifCubit.close();
      expect(notifCubit.isClosed, isTrue);

      // Dispatching after logout executes cleanly without leaking to closed cubit
      await dispatcher.notifySystemAlert(
        recipientUserId: approverUser.id,
        title: 'Post Logout Notification',
        message: 'Ignored cleanly',
      );
    });

    test('End-to-End Workflow: Bridge Submission -> Inbox -> Decision -> Dispatch -> RFC-4180 Export', () async {
      // 1. Submit purchase approval via bridge
      final submission = await bridge.submitPurchaseOrderApproval(
        poNumber: 'PO-888',
        vendorName: 'Global Metals Inc',
        totalAmount: 88500.0,
        currencyCode: 'USD',
        requester: requesterUser,
        priority: ApprovalPriority.urgent,
      );

      expect(submission.status, ApprovalStatus.pending);
      expect(submission.requestNumber, isNotEmpty);

      // 2. Inbox Cubit loads and lists the pending request
      final inboxCubit = ApprovalInboxCubit(
        approvalRepo,
        currentUserId: approverUser.id,
      );

      await inboxCubit.loadApprovals();
      expect(inboxCubit.state is ApprovalInboxLoaded, isTrue);
      final loadedInbox = inboxCubit.state as ApprovalInboxLoaded;
      expect(
        loadedInbox.allRequests.any((r) => r.id == submission.id),
        isTrue,
      );

      // 3. Approver executes approval decision with comment
      final actionCubit = ApprovalActionCubit(approvalRepo);

      await actionCubit.approve(
        requestId: submission.id,
        actor: approverUser,
        comment: 'Verified purchase specs and pricing.',
        request: submission,
      );

      expect(actionCubit.state is ApprovalActionSuccess, isTrue);
      final success = actionCubit.state as ApprovalActionSuccess;
      expect(success.updatedRequest.status, ApprovalStatus.approved);

      // 4. Verify notification was dispatched to the requester
      final requesterNotifs = await notificationRepo.getNotifications(
        recipientUserId: requesterUser.id,
      );

      final decisionNotif = requesterNotifs.firstWhere(
        (n) => n.referenceEntityId == submission.id,
      );
      expect(decisionNotif.title, contains('Approved'));

      // Requester marks as read
      await notificationRepo.markAsRead(
        notificationId: decisionNotif.id,
        userId: requesterUser.id,
      );

      final updatedNotif = (await notificationRepo.getNotifications(
        recipientUserId: requesterUser.id,
      )).firstWhere((n) => n.id == decisionNotif.id);
      expect(updatedNotif.isRead, isTrue);

      // 5. Admin queries audit trail and exports RFC-4180 CSV
      final auditTrail = await approvalRepo.getAuditTrail(submission.id);
      expect(auditTrail.isNotEmpty, isTrue);
      expect(auditTrail.any((a) => a.actorUserId == approverUser.id), isTrue);

      final allRequests = await approvalRepo.getApprovals();
      final csv = ApprovalExportService.exportApprovalsToCsv(allRequests);

      expect(csv.contains('Global Metals Inc'), isTrue);
      expect(csv.contains('88500.00'), isTrue);
      expect(csv.contains('USD'), isTrue);

      // Clean up cubits
      await inboxCubit.close();
      await actionCubit.close();
    });
  });
}
