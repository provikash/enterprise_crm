import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/approvals/domain/policies/approvals_access_policy.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/mappers/crm_permission_presentation.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_permission_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalsAccessPolicy', () {
    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'Administrator',
      accountType: AccountType.admin,
    );

    const standardUserWithoutModule = CurrentUser(
      id: 'usr_std_no_module',
      displayName: 'Standard User (No Module)',
      accountType: AccountType.user,
      modules: {CrmModule.leadManagement},
      permissions: {CrmPermissions.leadUpdate},
    );

    const fullApprovalsUser = CurrentUser(
      id: 'usr_approver',
      displayName: 'Approver User',
      accountType: AccountType.user,
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

    final pendingRequest = ApprovalRequest(
      id: 'appr-001',
      requestNumber: 'REQ-2026-0001',
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: 'po-101',
      entityTitle: 'Purchase Order #PO-101',
      requesterId: 'usr_requester',
      requesterName: 'Requester Person',
      status: ApprovalStatus.pending,
      priority: ApprovalPriority.normal,
      submittedAt: DateTime.utc(2026, 10, 16),
      steps: const [
        ApprovalStep(
          id: 'step-1',
          stepOrder: 1,
          title: 'Manager Approval',
          status: ApprovalStepStatus.pending,
        ),
      ],
    );

    final terminalRequest = pendingRequest.copyWith(
      status: ApprovalStatus.approved,
    );

    test('Admin has unrestricted access to all operations', () {
      expect(ApprovalsAccessPolicy.canAccessModule(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canViewApprovals(adminUser), isTrue);
      expect(
        ApprovalsAccessPolicy.canPerformDecision(adminUser, pendingRequest),
        isTrue,
      );
      expect(ApprovalsAccessPolicy.canSubmitRequest(adminUser), isTrue);
      expect(
        ApprovalsAccessPolicy.canCancelRequest(adminUser, pendingRequest),
        isTrue,
      );
      expect(ApprovalsAccessPolicy.canExport(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canViewNotifications(adminUser), isTrue);
      expect(ApprovalsAccessPolicy.canManageNotifications(adminUser), isTrue);
    });

    test('User without module assignment is denied all access', () {
      expect(
        ApprovalsAccessPolicy.canAccessModule(standardUserWithoutModule),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canViewApprovals(standardUserWithoutModule),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          standardUserWithoutModule,
          pendingRequest,
        ),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canSubmitRequest(standardUserWithoutModule),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canCancelRequest(
          standardUserWithoutModule,
          pendingRequest,
        ),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canExport(standardUserWithoutModule),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canViewNotifications(standardUserWithoutModule),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canManageNotifications(standardUserWithoutModule),
        isFalse,
      );
    });

    test('Maker-Checker Principle: Requester cannot approve their own request', () {
      final requesterUser = CurrentUser(
        id: 'usr_requester',
        displayName: 'Requester Person',
        accountType: AccountType.user,
        modules: const {CrmModule.approvalsNotifications},
        permissions: const {
          CrmPermissions.approvalsView,
          CrmPermissions.approvalsAction,
        },
      );

      // The request was submitted by 'usr_requester'
      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          requesterUser,
          pendingRequest,
        ),
        isFalse,
      );
    });

    test('Authorized non-requester can approve actionable request', () {
      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          fullApprovalsUser,
          pendingRequest,
        ),
        isTrue,
      );
    });

    test('Assigned step user check restricts action to assigned user', () {
      final assignedStepRequest = pendingRequest.copyWith(
        steps: const [
          ApprovalStep(
            id: 'step-1',
            stepOrder: 1,
            title: 'Assigned Reviewer Step',
            assignedUserId: 'usr_specific_approver',
            status: ApprovalStepStatus.pending,
          ),
        ],
      );

      // fullApprovalsUser id is 'usr_approver', not 'usr_specific_approver'
      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          fullApprovalsUser,
          assignedStepRequest,
        ),
        isFalse,
      );

      const specificUser = CurrentUser(
        id: 'usr_specific_approver',
        displayName: 'Specific Approver',
        accountType: AccountType.user,
        modules: {CrmModule.approvalsNotifications},
        permissions: {CrmPermissions.approvalsAction},
      );

      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          specificUser,
          assignedStepRequest,
        ),
        isTrue,
      );
    });

    test('Decisions cannot be made on terminal requests', () {
      expect(
        ApprovalsAccessPolicy.canPerformDecision(adminUser, terminalRequest),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canPerformDecision(
          fullApprovalsUser,
          terminalRequest,
        ),
        isFalse,
      );
    });

    test('Only requester or admin can cancel an actionable request', () {
      const requesterUser = CurrentUser(
        id: 'usr_requester',
        displayName: 'Requester Person',
        accountType: AccountType.user,
        modules: {CrmModule.approvalsNotifications},
        permissions: {CrmPermissions.approvalsSubmit},
      );

      expect(
        ApprovalsAccessPolicy.canCancelRequest(requesterUser, pendingRequest),
        isTrue,
      );
      expect(
        ApprovalsAccessPolicy.canCancelRequest(fullApprovalsUser, pendingRequest),
        isFalse,
      );
      expect(
        ApprovalsAccessPolicy.canCancelRequest(adminUser, pendingRequest),
        isTrue,
      );
      expect(
        ApprovalsAccessPolicy.canCancelRequest(requesterUser, terminalRequest),
        isFalse,
      );
    });
  });

  group('Permissions & Catalog Registration', () {
    test('CrmPermissions recognizes all 6 Approvals & Notifications permissions', () {
      const expectedPermissions = [
        CrmPermissions.approvalsView,
        CrmPermissions.approvalsAction,
        CrmPermissions.approvalsSubmit,
        CrmPermissions.approvalsExport,
        CrmPermissions.notificationsView,
        CrmPermissions.notificationsManage,
      ];

      for (final perm in expectedPermissions) {
        expect(CrmPermissions.isKnown(perm), isTrue);
        expect(
          CrmPermissions.moduleFor(perm),
          equals(CrmModule.approvalsNotifications),
        );
      }

      final modulePerms =
          CrmPermissions.permissionsFor(CrmModule.approvalsNotifications);
      expect(modulePerms.containsAll(expectedPermissions), isTrue);
    });

    test('CrmPermissionPresentation provides human-readable labels', () {
      expect(
        CrmPermissionPresentation.displayNameFor(CrmPermissions.approvalsView),
        equals('View approvals'),
      );
      expect(
        CrmPermissionPresentation.displayNameFor(CrmPermissions.approvalsAction),
        equals('Approve or reject requests'),
      );
      expect(
        CrmPermissionPresentation.displayNameFor(CrmPermissions.notificationsView),
        equals('View notifications'),
      );
    });

    test('MockPermissionCatalog contains definitions for all 6 permissions', () {
      final catalogIds =
          MockPermissionCatalog.definitions.map((d) => d.id).toSet();

      expect(catalogIds.contains(CrmPermissions.approvalsView), isTrue);
      expect(catalogIds.contains(CrmPermissions.approvalsAction), isTrue);
      expect(catalogIds.contains(CrmPermissions.approvalsSubmit), isTrue);
      expect(catalogIds.contains(CrmPermissions.approvalsExport), isTrue);
      expect(catalogIds.contains(CrmPermissions.notificationsView), isTrue);
      expect(catalogIds.contains(CrmPermissions.notificationsManage), isTrue);
    });
  });
}
