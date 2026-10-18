import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
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
