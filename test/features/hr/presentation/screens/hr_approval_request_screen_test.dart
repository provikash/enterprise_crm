import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_approval_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHrApprovalRepository repository;

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
    String? initialTargetId,
    Size size = const Size(800, 1000),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: HrApprovalRequestScreen(
          user: user,
          repository: repository,
          initialTargetId: initialTargetId,
        ),
      ),
    );
  }

  group('HrApprovalRequestScreen', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('hr_approval_request_scaffold')), findsNothing);
    });

    testWidgets('authorized user sees form with required fields', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: hrStandardUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_approval_request_scaffold')), findsOneWidget);
      expect(find.text('New Approval Request'), findsOneWidget);
      expect(find.byKey(const Key('approval_request_workflow_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_target_type_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_target_id_field')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_remarks_field')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_submit_button')), findsOneWidget);
    });

    testWidgets('empty target ID triggers form validation error', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: hrStandardUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('approval_request_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Target Entity ID is required'), findsOneWidget);
      expect(find.byKey(const Key('approval_request_success_view')), findsNothing);
    });

    testWidgets('successful submission displays confirmed request state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(user: hrStandardUser, initialTargetId: 'period_2026_01'),
      );
      await tester.pumpAndSettle();

      // Enter remarks
      await tester.enterText(
        find.byKey(const Key('approval_request_remarks_field')),
        'Finalizing January 2026 payroll',
      );

      // Submit
      await tester.tap(find.byKey(const Key('approval_request_submit_button')));
      await tester.pumpAndSettle();

      // Verify success confirmation view
      expect(find.byKey(const Key('approval_request_success_view')), findsOneWidget);
      expect(find.text('Approval Request Submitted'), findsOneWidget);
      expect(find.byKey(const Key('approval_request_success_id')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_success_status')), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byKey(const Key('approval_request_done_button')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_view_details_button')), findsOneWidget);
    });

    testWidgets('displays error banner if repository throws', (tester) async {
      final failingRepo = _FailingSubmissionRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: HrApprovalRequestScreen(
            user: hrStandardUser,
            repository: failingRepo,
            initialTargetId: 'period_2026_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('approval_request_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('approval_request_error_banner')), findsOneWidget);
      expect(find.byKey(const Key('approval_request_success_view')), findsNothing);
    });
  });
}

class _FailingSubmissionRepository extends MockHrApprovalRepository {
  @override
  Future<HrApprovalRequest> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
  }) async {
    throw Exception('Simulated network failure on submission');
  }
}
