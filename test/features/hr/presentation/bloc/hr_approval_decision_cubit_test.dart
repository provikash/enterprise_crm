import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_decision_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_approval_decision_state.dart';

void main() {
  group('HrApprovalDecisionCubit Tests (HR-9.5)', () {
    late MockHrApprovalRepository repository;

    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: {},
      permissions: {},
    );

    const standardUser = CurrentUser(
      id: 'usr_standard',
      displayName: 'Standard User',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {},
    );

    setUp(() {
      repository = MockHrApprovalRepository();
    });

    test('initial state is HrApprovalDecisionInitial', () {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'appr_req_1',
      );

      expect(cubit.state, isA<HrApprovalDecisionInitial>());
      cubit.close();
    });

    test('loadDetails emits [Loading, Ready] with canDecide=true for admin on pending request', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'appr_req_1',
      );

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.loadDetails();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<HrApprovalDecisionLoading>());
      expect(states[1], isA<HrApprovalDecisionReady>());

      final ready = states[1] as HrApprovalDecisionReady;
      expect(ready.request.id, equals('appr_req_1'));
      expect(ready.canDecide, isTrue);
      expect(ready.canCancel, isTrue);
      expect(ready.history.isNotEmpty, isTrue);

      cubit.close();
    });

    test('loadDetails emits [Loading, Ready] with canDecide=false for standard user', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: standardUser,
        requestId: 'appr_req_1', // requester is usr_hr
      );

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.loadDetails();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      final ready = states[1] as HrApprovalDecisionReady;
      expect(ready.canDecide, isFalse);
      expect(ready.canCancel, isFalse); // not admin and not requester

      cubit.close();
    });

    test('loadDetails emits [Loading, Failure] when request is not found', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'non_existent_req',
      );

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.loadDetails();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<HrApprovalDecisionLoading>());
      expect(states[1], isA<HrApprovalDecisionFailure>());
      expect((states[1] as HrApprovalDecisionFailure).message, contains('not found'));

      cubit.close();
    });

    test('approve decision emits [Submitting, Success] and marks status approved', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'appr_req_1',
      );

      await cubit.loadDetails();

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.approve(reason: 'Approved for processing');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<HrApprovalDecisionSubmitting>());
      expect(states[1], isA<HrApprovalDecisionSuccess>());

      final success = states[1] as HrApprovalDecisionSuccess;
      expect(success.request.status, equals(HrApprovalStatus.approved));
      expect(success.history.last.action, equals('approved'));
      expect(success.history.last.reason, equals('Approved for processing'));

      cubit.close();
    });

    test('reject decision emits [Submitting, Success] and marks status rejected', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'appr_req_2',
      );

      await cubit.loadDetails();

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.reject(reason: 'Rejected due to missing docs');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<HrApprovalDecisionSubmitting>());
      expect(states[1], isA<HrApprovalDecisionSuccess>());

      final success = states[1] as HrApprovalDecisionSuccess;
      expect(success.request.status, equals(HrApprovalStatus.rejected));
      expect(success.history.last.action, equals('rejected'));

      cubit.close();
    });

    test('cancel request emits [Submitting, Success] and marks status cancelled', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: standardUser, // requester of appr_req_2
        requestId: 'appr_req_2',
      );

      await cubit.loadDetails();

      final states = <HrApprovalDecisionState>[];
      cubit.stream.listen(states.add);

      await cubit.cancel(reason: 'User withdrawal');
      await Future<void>.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<HrApprovalDecisionSubmitting>());
      expect(states[1], isA<HrApprovalDecisionSuccess>());

      final success = states[1] as HrApprovalDecisionSuccess;
      expect(success.request.status, equals(HrApprovalStatus.cancelled));

      cubit.close();
    });

    test('reset clears currentRequest and emits Initial', () async {
      final cubit = HrApprovalDecisionCubit(
        repository: repository,
        actor: adminUser,
        requestId: 'appr_req_1',
      );

      await cubit.loadDetails();
      expect(cubit.currentRequest, isNotNull);

      cubit.reset();
      expect(cubit.state, isA<HrApprovalDecisionInitial>());
      expect(cubit.currentRequest, isNull);

      cubit.close();
    });
  });
}
