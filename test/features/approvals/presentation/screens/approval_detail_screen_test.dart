import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/approvals/domain/inputs/create_approval_request_input.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approval_detail_screen.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final adminUser = CurrentUser(
    id: 'usr-admin',
    accountType: AccountType.admin,
    modules: {CrmModule.approvalsNotifications},
    permissions: const {},
    displayName: 'Admin User',
  );

  Widget buildDetailScreen({
    required String requestId,
    required CurrentUser user,
    required MockApprovalRepository repository,
  }) {
    return MaterialApp(
      home: ApprovalDetailScreen(
        requestId: requestId,
        user: user,
        repository: repository,
      ),
    );
  }

  testWidgets('ApprovalDetailScreen renders request header, steps, and audit trail',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    await tester.pumpWidget(
      buildDetailScreen(
        requestId: 'appr-001',
        user: adminUser,
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // Verify header card items
    expect(find.text('REQ-2026-0001'), findsOneWidget);
    expect(find.text('Purchase Order #PO-9821 (ACME Steel)'), findsOneWidget);
    expect(find.text('Procurement'), findsOneWidget);

    // Verify stepper and audit timeline
    expect(find.text('Workflow Approval Steps'), findsOneWidget);
    expect(find.text('Audit Activity Timeline'), findsOneWidget);

    // Verify admin can see decision actions
    expect(find.byKey(const Key('approval_action_approve_btn')), findsOneWidget);
    expect(find.byKey(const Key('approval_action_reject_btn')), findsOneWidget);
    expect(find.byKey(const Key('approval_action_revision_btn')), findsOneWidget);
  });

  testWidgets('ApprovalDetailScreen enforces Maker-Checker: requester cannot approve',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    // Get appr-001 requester ID
    final req = store.getApprovalById('appr-001')!;
    final requesterUser = CurrentUser(
      id: req.requesterId, // Same requester as appr-001
      accountType: AccountType.user,
      modules: {CrmModule.approvalsNotifications},
      permissions: {'approvals.view', 'approvals.action'},
      displayName: req.requesterName,
    );

    await tester.pumpWidget(
      buildDetailScreen(
        requestId: 'appr-001',
        user: requesterUser,
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // Maker-Checker blocks requester from deciding on their own request
    expect(find.byKey(const Key('approval_action_approve_btn')), findsNothing);
    expect(find.byKey(const Key('approval_detail_governance_notice')), findsOneWidget);
  });

  testWidgets('ApprovalDetailScreen displays step routing notice for non-assigned user',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    final assignedReq = await repo.submitRequest(
      const CreateApprovalRequestInput(
        module: CrmModule.purchase,
        entityType: 'purchase_order',
        entityId: 'po-custom-assigned',
        entityTitle: 'Special PO (Assigned Step)',
        requesterId: 'usr_other_requester',
        requesterName: 'Other Person',
        steps: [
          ApprovalStep(
            id: 'step-assigned-test',
            stepOrder: 1,
            title: 'Designated Audit Step',
            assignedRole: 'Finance Director',
            assignedUserId: 'usr_frank_finance',
            assignedUserName: 'Frank Finance',
            status: ApprovalStepStatus.pending,
          ),
        ],
      ),
    );

    // Standard user with approvals.action who is neither Frank Finance nor admin
    final standardUser = CurrentUser(
      id: 'usr_new_user',
      accountType: AccountType.user,
      modules: {CrmModule.approvalsNotifications},
      permissions: {'approvals.view', 'approvals.action'},
      displayName: 'New User',
    );

    await tester.pumpWidget(
      buildDetailScreen(
        requestId: assignedReq.id,
        user: standardUser,
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('approval_action_approve_btn')), findsNothing);
    expect(find.byKey(const Key('approval_detail_governance_notice')), findsOneWidget);
    expect(find.textContaining('Step Routing: This workflow step is assigned to Frank Finance'), findsOneWidget);
  });

  testWidgets('ApprovalDetailScreen allows standard user with approvals.action to approve role-based request',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    // Standard user with approvals.action on appr-001 (role-based Finance Director step)
    final standardUser = CurrentUser(
      id: 'usr_permitted_standard',
      accountType: AccountType.user,
      modules: {CrmModule.approvalsNotifications},
      permissions: {'approvals.view', 'approvals.action'},
      displayName: 'Standard Approver',
    );

    await tester.pumpWidget(
      buildDetailScreen(
        requestId: 'appr-001',
        user: standardUser,
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    // Action buttons must be present!
    expect(find.byKey(const Key('approval_action_approve_btn')), findsOneWidget);
    expect(find.byKey(const Key('approval_action_reject_btn')), findsOneWidget);
  });

  testWidgets('ApprovalDetailScreen renders without overflow on 320x568 mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    await tester.pumpWidget(
      buildDetailScreen(
        requestId: 'appr-001',
        user: adminUser,
        repository: repo,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
