import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/screens/approvals_workspace_screen.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final authorizedAdmin = CurrentUser(
    id: 'usr-admin',
    accountType: AccountType.admin,
    modules: {CrmModule.approvalsNotifications},
    permissions: const {},
    displayName: 'Admin User',
  );

  final unauthorizedUser = CurrentUser(
    id: 'usr-unauth',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement}, // Lacks approvals module
    permissions: const {},
    displayName: 'Unauthorized User',
  );

  Widget buildWorkspace({
    required CurrentUser user,
    required MockApprovalRepository repository,
  }) {
    return MaterialApp(
      home: ApprovalsWorkspaceScreen(
        user: user,
        repository: repository,
      ),
    );
  }

  testWidgets('ApprovalsWorkspaceScreen renders header and embedded inbox for authorized user',
      (tester) async {
    final repo = MockApprovalRepository(MockApprovalStore());

    await tester.pumpWidget(buildWorkspace(user: authorizedAdmin, repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Approvals Workspace'), findsOneWidget);
    expect(find.text('GOVERNANCE'), findsOneWidget);
    expect(find.byKey(const Key('approval_inbox_view')), findsOneWidget);
  });

  testWidgets('ApprovalsWorkspaceScreen renders AccessRestrictedScreen for unauthorized user',
      (tester) async {
    final repo = MockApprovalRepository(MockApprovalStore());

    await tester.pumpWidget(buildWorkspace(user: unauthorizedUser, repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(AccessRestrictedScreen), findsOneWidget);
    expect(find.byKey(const Key('approvals_workspace_scaffold')), findsNothing);
  });
}
