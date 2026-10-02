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

  const otherUser = CurrentUser(
    id: 'usr_other',
    displayName: 'Other User',
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

  group('HrApprovalRequestDetailsScreen Tests (HR-9.5)', () {
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

    testWidgets('non-admin user on pending request does not see Approve/Reject buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: otherUser,
          requestId: 'appr_req_1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_approval_approve_button')), findsNothing);
      expect(find.byKey(const Key('hr_approval_reject_button')), findsNothing);
      expect(find.text('Finalize'), findsNothing);
      expect(find.text('Pay'), findsNothing);
    });

    testWidgets('admin user on pending request sees Approve and Reject buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: 'appr_req_1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_approval_approve_button')), findsOneWidget);
      expect(find.byKey(const Key('hr_approval_reject_button')), findsOneWidget);
      expect(find.text('Finalize'), findsNothing);
      expect(find.text('Pay'), findsNothing);
    });

    testWidgets('admin approving pending request transitions status to Approved', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: 'appr_req_1',
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Approve button and tap
      await tester.scrollUntilVisible(find.byKey(const Key('hr_approval_approve_button')), 200);
      await tester.tap(find.byKey(const Key('hr_approval_approve_button')));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Approve Request'), findsOneWidget);
      expect(find.byKey(const Key('hr_approval_decision_reason_field')), findsOneWidget);

      // Enter optional reason
      await tester.enterText(
        find.byKey(const Key('hr_approval_decision_reason_field')),
        'Approved by administrator',
      );

      // Confirm
      await tester.tap(find.byKey(const Key('hr_approval_confirm_decision_button')));
      await tester.pumpAndSettle();

      // Status badge updates to Approved
      expect(find.text('Approved'), findsWidgets);
      // Approve/Reject buttons disappear
      expect(find.byKey(const Key('hr_approval_approve_button')), findsNothing);
      expect(find.byKey(const Key('hr_approval_reject_button')), findsNothing);
    });

    testWidgets('admin rejecting pending request transitions status to Rejected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: 'appr_req_2',
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Reject button and tap
      await tester.scrollUntilVisible(find.byKey(const Key('hr_approval_reject_button')), 200);
      await tester.tap(find.byKey(const Key('hr_approval_reject_button')));
      await tester.pumpAndSettle();

      expect(find.text('Reject Request'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('hr_approval_decision_reason_field')),
        'Attendance record is invalid',
      );

      await tester.tap(find.byKey(const Key('hr_approval_confirm_decision_button')));
      await tester.pumpAndSettle();

      expect(find.text('Rejected'), findsWidgets);
      expect(find.byKey(const Key('hr_approval_approve_button')), findsNothing);
    });

    testWidgets('requester can cancel their pending request', (tester) async {
      // appr_req_2 requester is usr_standard
      const requesterUser = CurrentUser(
        id: 'usr_standard',
        displayName: 'Requester User',
        accountType: AccountType.user,
        modules: {CrmModule.hrPayroll},
        permissions: {},
      );

      await tester.pumpWidget(
        buildTestWidget(
          user: requesterUser,
          requestId: 'appr_req_2',
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Cancel button and tap
      await tester.scrollUntilVisible(find.byKey(const Key('hr_approval_cancel_button')), 200);
      expect(find.byKey(const Key('hr_approval_cancel_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hr_approval_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Approval Request'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hr_approval_confirm_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cancelled'), findsWidgets);
    });

    testWidgets('audit history entries are rendered', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          requestId: 'appr_req_3', // Has 2 history entries in seed
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byKey(const Key('hr_approval_details_history_card')), 200);
      expect(find.byKey(const Key('hr_approval_details_history_card')), findsOneWidget);
      expect(find.text('SUBMITTED by usr_admin'), findsOneWidget);
      expect(find.text('APPROVED by usr_admin'), findsOneWidget);
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

    testWidgets('responsive layout on mobile and desktop without overflow', (tester) async {
      const viewports = [
        Size(320, 568),
        Size(360, 640),
        Size(768, 1024),
        Size(1200, 800),
      ];

      for (final size in viewports) {
        await tester.pumpWidget(
          buildTestWidget(
            user: adminUser,
            requestId: 'appr_req_1',
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('hr_approval_details_header_card')), findsOneWidget);
      }
    });
  });
}
