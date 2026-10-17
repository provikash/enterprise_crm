import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_action_type.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_action_cubit.dart';
import 'package:enterprise_crm/features/approvals/presentation/cubit/approval_action_state.dart';

void main() {
  group('ApprovalActionCubit', () {
    late MockApprovalStore store;
    late MockApprovalRepository repository;
    late ApprovalActionCubit cubit;

    final adminUser = const CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
    );

    final standardApprover = const CurrentUser(
      id: 'usr_lead',
      displayName: 'Paula Lead',
      accountType: AccountType.user,
      modules: {CrmModule.approvalsNotifications},
      permissions: {CrmPermissions.approvalsAction, CrmPermissions.approvalsView},
    );

    final requesterUser = const CurrentUser(
      id: 'usr_buyer',
      displayName: 'Bob Buyer',
      accountType: AccountType.user,
      modules: {CrmModule.approvalsNotifications},
      permissions: {CrmPermissions.approvalsAction, CrmPermissions.approvalsView},
    );

    setUp(() {
      store = MockApprovalStore();
      repository = MockApprovalRepository(store);
      cubit = ApprovalActionCubit(repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ApprovalActionInitial', () {
      expect(cubit.state, const ApprovalActionInitial());
    });

    test('approve succeeds for authorized approver', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ApprovalActionSubmitting(ApprovalActionType.approved),
          isA<ApprovalActionSuccess>(),
        ]),
      );

      await cubit.approve(
        requestId: 'appr-001',
        actor: adminUser,
        comment: 'Executive sign-off',
      );
      await expectation;

      final success = cubit.state as ApprovalActionSuccess;
      expect(success.action, ApprovalActionType.approved);
      expect(success.updatedRequest.status, ApprovalStatus.approved);
    });

    test('approve enforces Maker-Checker when request is provided', () async {
      final request = (await repository.getApprovalById('appr-001'))!;
      // requesterUser has id 'usr_buyer' which matches request.requesterId
      await cubit.approve(
        requestId: 'appr-001',
        actor: requesterUser,
        request: request,
      );

      expect(cubit.state, isA<ApprovalActionFailure>());
      final failure = cubit.state as ApprovalActionFailure;
      expect(failure.message, contains('permission'));
    });

    test('reject strictly requires non-empty reason', () async {
      await cubit.reject(
        requestId: 'appr-002',
        actor: adminUser,
        rejectionReason: '   ',
      );

      expect(cubit.state, isA<ApprovalActionFailure>());
      final failure = cubit.state as ApprovalActionFailure;
      expect(failure.message, 'Rejection reason cannot be empty.');
    });

    test('reject succeeds with valid reason', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ApprovalActionSubmitting(ApprovalActionType.rejected),
          isA<ApprovalActionSuccess>(),
        ]),
      );

      await cubit.reject(
        requestId: 'appr-002',
        actor: adminUser,
        rejectionReason: 'Exceeds maximum allowable allowance limit.',
      );
      await expectation;

      final success = cubit.state as ApprovalActionSuccess;
      expect(success.action, ApprovalActionType.rejected);
      expect(success.updatedRequest.status, ApprovalStatus.rejected);
    });

    test('requestRevision strictly requires non-empty notes', () async {
      await cubit.requestRevision(
        requestId: 'appr-003',
        actor: adminUser,
        revisionNotes: '',
      );

      expect(cubit.state, isA<ApprovalActionFailure>());
      final failure = cubit.state as ApprovalActionFailure;
      expect(failure.message, 'Revision notes cannot be empty.');
    });

    test('requestRevision succeeds with valid revision notes', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ApprovalActionSubmitting(ApprovalActionType.revisionRequested),
          isA<ApprovalActionSuccess>(),
        ]),
      );

      await cubit.requestRevision(
        requestId: 'appr-003',
        actor: adminUser,
        revisionNotes: 'Please upload certificate of incorporation with apostille.',
      );
      await expectation;

      final success = cubit.state as ApprovalActionSuccess;
      expect(success.action, ApprovalActionType.revisionRequested);
      expect(success.updatedRequest.status, ApprovalStatus.revisionRequested);
    });

    test('cancel succeeds for the requester', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ApprovalActionSubmitting(ApprovalActionType.cancelled),
          isA<ApprovalActionSuccess>(),
        ]),
      );

      final request = (await repository.getApprovalById('appr-001'))!;
      await cubit.cancel(
        requestId: 'appr-001',
        actor: requesterUser,
        reason: 'Order cancelled by supplier',
        request: request,
      );
      await expectation;

      final success = cubit.state as ApprovalActionSuccess;
      expect(success.action, ApprovalActionType.cancelled);
      expect(success.updatedRequest.status, ApprovalStatus.cancelled);
    });

    test('cancel fails for unauthorized non-requester non-admin', () async {
      final states = <ApprovalActionState>[];
      cubit.stream.listen(states.add);

      final request = (await repository.getApprovalById('appr-001'))!;
      // standardApprover is NOT admin and NOT requester ('usr_buyer')
      await cubit.cancel(
        requestId: 'appr-001',
        actor: standardApprover,
        request: request,
      );

      expect(states.length, 1);
      expect(states[0], isA<ApprovalActionFailure>());
      final failure = states[0] as ApprovalActionFailure;
      expect(failure.message, contains('permission'));
    });

    test('reset resets state to initial', () async {
      await cubit.reject(
        requestId: 'appr-002',
        actor: adminUser,
        rejectionReason: '',
      );
      expect(cubit.state, isA<ApprovalActionFailure>());

      cubit.reset();
      expect(cubit.state, const ApprovalActionInitial());
    });
  });
}
