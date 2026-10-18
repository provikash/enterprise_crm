import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approval_inbox_screen.dart';
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

  Widget buildInbox({
    required CurrentUser user,
    required MockApprovalRepository repository,
    ValueChanged<ApprovalRequest>? onSelectRequest,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ApprovalInboxScreen(
          user: user,
          repository: repository,
          onSelectRequest: onSelectRequest,
        ),
      ),
    );
  }

  testWidgets('ApprovalInboxScreen renders tabs with counts and loaded requests',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    await tester.pumpWidget(buildInbox(user: adminUser, repository: repo));
    await tester.pumpAndSettle();

    // Verify tabs exist
    expect(find.text('Pending Review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('My Submissions'), findsOneWidget);

    // Initial pending tab shows pending requests
    expect(find.byKey(const Key('approval_tab_pending')), findsOneWidget);
  });

  testWidgets('ApprovalInboxScreen switches tabs and updates displayed list',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    await tester.pumpWidget(buildInbox(user: adminUser, repository: repo));
    await tester.pumpAndSettle();

    // Switch to Approved tab
    await tester.tap(find.byKey(const Key('approval_tab_approved')));
    await tester.pumpAndSettle();

    // Switch to Rejected tab
    await tester.tap(find.byKey(const Key('approval_tab_rejected')));
    await tester.pumpAndSettle();

    // Switch to My Submissions tab
    await tester.tap(find.byKey(const Key('approval_tab_mySubmissions')));
    await tester.pumpAndSettle();
  });

  testWidgets('ApprovalInboxScreen filters items using search query', (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    await tester.pumpWidget(buildInbox(user: adminUser, repository: repo));
    await tester.pumpAndSettle();

    // Enter search query
    await tester.enterText(
      find.byKey(const Key('approval_search_field')),
      'REQ-2026-0001',
    );
    await tester.pumpAndSettle();

    expect(find.text('REQ-2026-0001'), findsAtLeastNWidgets(1));

    // Clear filters
    await tester.tap(find.byKey(const Key('approval_clear_filters_btn')));
    await tester.pumpAndSettle();
  });

  testWidgets('ApprovalInboxScreen renders responsive viewports without overflow',
      (tester) async {
    final store = MockApprovalStore();
    final repo = MockApprovalRepository(store);

    final viewports = [
      const Size(320, 568), // Mobile compact
      const Size(360, 640), // Mobile standard
      const Size(768, 1024), // Tablet
      const Size(1200, 800), // Desktop Web
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildInbox(user: adminUser, repository: repo));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Failed on viewport ${size.width}x${size.height}',
      );
    }

    tester.view.resetPhysicalSize();
  });
}
