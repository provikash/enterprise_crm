import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_approval_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/pending_approvals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHrApprovalRepository repository;

  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrStandardUser = CurrentUser(
    id: 'usr_hr',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_sales',
    displayName: 'Sales User',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {},
  );

  setUp(() {
    repository = MockHrApprovalRepository();
  });

  Widget buildTestWidget({
    required CurrentUser user,
    MockHrApprovalRepository? repo,
    Size size = const Size(1000, 800),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: PendingApprovalsScreen(
          user: user,
          repository: repo ?? repository,
        ),
      ),
    );
  }

  group('PendingApprovalsScreen', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsNothing);
    });

    testWidgets('authorized admin user sees list of pending approval cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
      expect(find.text('Approvals & Requests'), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_new_request_button')), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_list')), findsOneWidget);

      // Verify no decision buttons (Approve / Reject) are rendered in HR-9.4
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('cards render workflow displayName, target context, and status', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      // Check fixture items exist
      expect(find.text('Payroll Period Finalization'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);
    });

    testWidgets('switching to My Requests filters by requester', (tester) async {
      // Create request submitted by hrStandardUser
      await repository.submitRequest(
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        requesterId: 'usr_hr',
        target: HrApprovalTarget.attendanceRecord('att_001'),
        remarks: 'Correcting punch time',
      );

      await tester.pumpWidget(buildTestWidget(user: hrStandardUser));
      await tester.pumpAndSettle();

      // Switch to My Requests segment
      await tester.tap(find.text('My Requests'));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Correction'), findsOneWidget);
      expect(find.text('Requester: usr_hr'), findsWidgets);
    });

    testWidgets('empty state displays when no requests match', (tester) async {
      final emptyRepo = MockHrApprovalRepository(
        store: MockHrApprovalStore(seedInitialData: false),
      );

      await tester.pumpWidget(buildTestWidget(user: adminUser, repo: emptyRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pending_approvals_empty_view')), findsOneWidget);
      expect(find.text('No Pending Approval Requests'), findsOneWidget);
    });

    testWidgets('error state displays on repository failure with retry button', (tester) async {
      final failingRepo = _FailingPendingRepository();

      await tester.pumpWidget(buildTestWidget(user: adminUser, repo: failingRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pending_approvals_error_view')), findsOneWidget);
      expect(find.text('Failed to Load Requests'), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_retry_button')), findsOneWidget);
    });
  });
}

class _FailingPendingRepository extends MockHrApprovalRepository {
  @override
  Future<List<HrApprovalRequest>> getPendingRequests({CurrentUser? user}) async {
    throw Exception('Simulated database connection failure');
  }
}
