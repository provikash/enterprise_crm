import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_approval_request_details_screen.dart';
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

  final testRequest = HrApprovalRequest(
    id: 'req_test_001',
    workflowType: HrApprovalWorkflowType.payrollFinalization,
    requesterId: 'usr_hr',
    target: HrApprovalTarget.payrollPeriod('period_2026_01'),
    status: HrApprovalStatus.pending,
    createdAt: DateTime.utc(2026, 1, 15, 10, 30),
    remarks: 'Monthly lock request for payroll',
  );

  Widget buildTestWidget({
    required CurrentUser user,
    required String requestId,
    HrApprovalRequest? initialRequest,
    Size size = const Size(800, 1000),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: HrApprovalRequestDetailsScreen(
          requestId: requestId,
          user: user,
          repository: repository,
          initialRequest: initialRequest,
        ),
      ),
    );
  }

  group('HrApprovalRequestDetailsScreen', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: unauthorizedUser,
          requestId: testRequest.id,
          initialRequest: testRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('authorized user sees all approved domain metadata', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: hrStandardUser,
          requestId: testRequest.id,
          initialRequest: testRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request req_test_001'), findsOneWidget);
      expect(find.text('req_test_001'), findsWidgets);
      expect(find.text('Payroll Period Finalization'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('payroll_period'), findsOneWidget);
      expect(find.text('period_2026_01'), findsOneWidget);
      expect(find.text('usr_hr'), findsOneWidget);
      expect(find.text('Monthly lock request for payroll'), findsOneWidget);
    });

    testWidgets('strictly zero approve/reject decision buttons are rendered', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: testRequest.id,
          initialRequest: testRequest,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Finalize'), findsNothing);
      expect(find.text('Pay'), findsNothing);
    });

    testWidgets('unknown request ID displays error view', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: 'req_non_existent',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_approval_details_not_found')), findsOneWidget);
      expect(find.text('Approval request not found.'), findsOneWidget);
    });
  });
}
