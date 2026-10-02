import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/pending_approvals_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/pending_approvals_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHrApprovalRepository repository;
  late PendingApprovalsCubit cubit;

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
    cubit = PendingApprovalsCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('PendingApprovalsCubit', () {
    test('initial state is PendingApprovalsInitial with pending mode', () {
      expect(cubit.state, isA<PendingApprovalsInitial>());
      expect(cubit.state.mode, PendingApprovalsFilterMode.pending);
    });

    test('loadPendingApprovals emits loading then loaded for authorized admin', () async {
      final states = <PendingApprovalsState>[];
      cubit.stream.listen(states.add);

      await cubit.loadPendingApprovals(user: adminUser);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PendingApprovalsLoading>());
      expect(states[1], isA<PendingApprovalsLoaded>());

      final loaded = states[1] as PendingApprovalsLoaded;
      expect(loaded.mode, PendingApprovalsFilterMode.pending);
      expect(loaded.requests, isNotEmpty);
    });

    test('loadPendingApprovals fails for unauthorized user', () async {
      final states = <PendingApprovalsState>[];
      cubit.stream.listen(states.add);

      await cubit.loadPendingApprovals(user: unauthorizedUser);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 1);
      expect(states[0], isA<PendingApprovalsFailure>());
      final failure = states[0] as PendingApprovalsFailure;
      expect(failure.message, contains('Unauthorized'));
    });

    test('loadMyRequests retrieves requests submitted by current user', () async {
      // First submit a request by hrStandardUser
      await repository.submitRequest(
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_hr',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
      );

      final states = <PendingApprovalsState>[];
      cubit.stream.listen(states.add);

      await cubit.loadMyRequests(user: hrStandardUser);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PendingApprovalsLoading>());
      expect(states[1], isA<PendingApprovalsLoaded>());

      final loaded = states[1] as PendingApprovalsLoaded;
      expect(loaded.mode, PendingApprovalsFilterMode.myRequests);
      expect(loaded.requests.any((r) => r.requesterId == 'usr_hr'), isTrue);
    });

    test('switchMode toggles between pending and myRequests', () async {
      await cubit.loadPendingApprovals(user: adminUser);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mode, PendingApprovalsFilterMode.pending);

      await cubit.switchMode(PendingApprovalsFilterMode.myRequests, user: adminUser);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mode, PendingApprovalsFilterMode.myRequests);
    });

    test('clear purges state and resets to initial', () async {
      await cubit.loadPendingApprovals(user: adminUser);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<PendingApprovalsLoaded>());

      cubit.clear();
      expect(cubit.state, isA<PendingApprovalsInitial>());
    });

    test('stale async result protection ignores superseded responses', () async {
      final controlledRepo = _ControlledAsyncMockRepository();
      final testCubit = PendingApprovalsCubit(repository: controlledRepo);

      final states = <PendingApprovalsState>[];
      testCubit.stream.listen(states.add);

      // Trigger first query (will finish second)
      final future1 = testCubit.loadPendingApprovals(user: adminUser);

      // Trigger second query immediately (will finish first)
      final future2 = testCubit.loadMyRequests(user: adminUser);

      await future2;
      await future1;
      await Future<void>.delayed(Duration.zero);

      // The final state must be the second query (myRequests), never overwritten by late first query
      expect(testCubit.state.mode, PendingApprovalsFilterMode.myRequests);
      await testCubit.close();
    });

    test('repository exception produces PendingApprovalsFailure', () async {
      final failingRepo = _FailingReadMockRepository();
      final failingCubit = PendingApprovalsCubit(repository: failingRepo);

      final states = <PendingApprovalsState>[];
      failingCubit.stream.listen(states.add);

      await failingCubit.loadPendingApprovals(user: adminUser);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<PendingApprovalsLoading>());
      expect(states[1], isA<PendingApprovalsFailure>());

      await failingCubit.close();
    });
  });
}

class _ControlledAsyncMockRepository extends MockHrApprovalRepository {
  int _callCount = 0;

  @override
  Future<List<HrApprovalRequest>> getPendingRequests({CurrentUser? user}) async {
    _callCount++;
    if (_callCount == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    return super.getPendingRequests(user: user);
  }

  @override
  Future<List<HrApprovalRequest>> getRequestsSubmittedBy(String requesterId) async {
    _callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return super.getRequestsSubmittedBy(requesterId);
  }
}

class _FailingReadMockRepository extends MockHrApprovalRepository {
  @override
  Future<List<HrApprovalRequest>> getPendingRequests({CurrentUser? user}) async {
    throw Exception('Connection reset by peer');
  }
}
