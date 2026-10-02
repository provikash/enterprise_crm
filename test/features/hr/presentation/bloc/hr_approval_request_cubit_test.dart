import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_request_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_request_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHrApprovalRepository repository;
  late HrApprovalRequestCubit cubit;

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
    cubit = HrApprovalRequestCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('HrApprovalRequestCubit', () {
    test('initial state is HrApprovalRequestInitial', () {
      expect(cubit.state, isA<HrApprovalRequestInitial>());
    });

    test('successful submission emits submitting then success with pending status', () async {
      final states = <HrApprovalRequestState>[];
      cubit.stream.listen(states.add);

      final target = HrApprovalTarget.payrollPeriod('period_2026_01');
      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        target: target,
        requester: hrStandardUser,
        remarks: 'Please finalize January 2026 payroll',
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<HrApprovalRequestSubmitting>());
      expect(states[1], isA<HrApprovalRequestSuccess>());

      final successState = states[1] as HrApprovalRequestSuccess;
      expect(successState.request.workflowType, HrApprovalWorkflowType.payrollFinalization);
      expect(successState.request.requesterId, 'usr_hr');
      expect(successState.request.target.targetEntityId, 'period_2026_01');
      expect(successState.request.status, HrApprovalStatus.pending);
      expect(successState.request.remarks, 'Please finalize January 2026 payroll');
    });

    test('admin submission succeeds as authorized', () async {
      final states = <HrApprovalRequestState>[];
      cubit.stream.listen(states.add);

      final target = HrApprovalTarget.attendanceRecord('att_001');
      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        target: target,
        requester: adminUser,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<HrApprovalRequestSubmitting>());
      expect(states[1], isA<HrApprovalRequestSuccess>());
    });

    test('unauthorized user emission produces HrApprovalRequestFailure', () async {
      final states = <HrApprovalRequestState>[];
      cubit.stream.listen(states.add);

      final target = HrApprovalTarget.attendanceRecord('att_001');
      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        target: target,
        requester: unauthorizedUser,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states[0], isA<HrApprovalRequestFailure>());
      final failure = states[0] as HrApprovalRequestFailure;
      expect(failure.message, contains('Unauthorized'));
    });

    test('empty target entity ID fails validation', () async {
      final states = <HrApprovalRequestState>[];
      cubit.stream.listen(states.add);

      final target = const HrApprovalTarget(
        targetModule: CrmModule.hrPayroll,
        targetEntityType: 'attendance_record',
        targetEntityId: '   ',
      );

      await cubit.submitRequest(
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        target: target,
        requester: hrStandardUser,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states[0], isA<HrApprovalRequestFailure>());
      final failure = states[0] as HrApprovalRequestFailure;
      expect(failure.message, contains('Target entity ID is required'));
    });

    test('double submission while in flight is ignored', () async {
      final delayedRepo = _DelayedMockHrApprovalRepository();
      final delayedCubit = HrApprovalRequestCubit(repository: delayedRepo);

      final target = HrApprovalTarget.employeeDocument('doc_001');

      final future1 = delayedCubit.submitRequest(
        workflowType: HrApprovalWorkflowType.documentVerification,
        target: target,
        requester: hrStandardUser,
      );

      // Immediately attempt second submission
      final future2 = delayedCubit.submitRequest(
        workflowType: HrApprovalWorkflowType.documentVerification,
        target: target,
        requester: hrStandardUser,
      );

      await Future.wait([future1, future2]);

      expect(delayedRepo.submitCalls, 1);
      await delayedCubit.close();
    });

    test('repository failure emits sanitized HrApprovalRequestFailure', () async {
      final failingRepo = _FailingMockHrApprovalRepository();
      final failingCubit = HrApprovalRequestCubit(repository: failingRepo);

      final states = <HrApprovalRequestState>[];
      failingCubit.stream.listen(states.add);

      final target = HrApprovalTarget.payrollPeriod('period_fail');
      await failingCubit.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        target: target,
        requester: hrStandardUser,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<HrApprovalRequestSubmitting>());
      expect(states[1], isA<HrApprovalRequestFailure>());
      final failure = states[1] as HrApprovalRequestFailure;
      expect(failure.message, isNotEmpty);

      await failingCubit.close();
    });
  });
}

class _DelayedMockHrApprovalRepository extends MockHrApprovalRepository {
  int submitCalls = 0;

  @override
  Future<HrApprovalRequest> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
  }) async {
    submitCalls++;
    await Future.delayed(const Duration(milliseconds: 50));
    return super.submitRequest(
      workflowType: workflowType,
      requesterId: requesterId,
      target: target,
      remarks: remarks,
    );
  }
}

class _FailingMockHrApprovalRepository extends MockHrApprovalRepository {
  @override
  Future<HrApprovalRequest> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
  }) async {
    throw Exception('Simulated database write error');
  }
}
