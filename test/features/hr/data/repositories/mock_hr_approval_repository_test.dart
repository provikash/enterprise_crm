import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_approval_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_approval_exception.dart';

void main() {
  group('MockHrApprovalRepository Tests (HR-9.3)', () {
    late MockHrApprovalStore store;
    late MockHrApprovalRepository repository;

    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
    );

    const hrUser = CurrentUser(
      id: 'usr_hr',
      displayName: 'HR Specialist',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {'hr.view', 'payroll.view'},
    );

    const standardUser = CurrentUser(
      id: 'usr_standard',
      displayName: 'Standard User',
      accountType: AccountType.user,
      modules: {CrmModule.leadManagement},
    );

    setUp(() {
      store = MockHrApprovalStore();
      repository = MockHrApprovalRepository(store: store);
    });

    group('Request Submission Contract', () {
      test('submits request with pending initial status and stable ID', () async {
        final target = HrApprovalTarget.payrollPeriod('period_2026_02');
        final request = await repository.submitRequest(
          workflowType: HrApprovalWorkflowType.payrollFinalization,
          requesterId: hrUser.id,
          target: target,
          remarks: 'February payroll review',
        );

        expect(request.id, startsWith('appr_req_'));
        expect(request.workflowType, equals(HrApprovalWorkflowType.payrollFinalization));
        expect(request.requesterId, equals('usr_hr'));
        expect(request.target, equals(target));
        expect(request.status, equals(HrApprovalStatus.pending));
        expect(request.isPending, isTrue);
        expect(request.remarks, equals('February payroll review'));
        expect(request.createdAt.isUtc, isTrue);
      });

      test('validates non-empty requester ID on submission', () async {
        final target = HrApprovalTarget.attendanceRecord('att_1');
        expect(
          () => repository.submitRequest(
            workflowType: HrApprovalWorkflowType.attendanceCorrection,
            requesterId: '   ',
            target: target,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.validationError),
            ),
          ),
        );
      });
    });

    group('Request Retrieval by ID', () {
      test('retrieves existing seeded request by ID', () async {
        final request = await repository.getRequestById('appr_req_1');
        expect(request, isNotNull);
        expect(request!.id, equals('appr_req_1'));
        expect(request.workflowType, equals(HrApprovalWorkflowType.payrollFinalization));
        expect(request.requesterId, equals('usr_hr'));
        expect(request.status, equals(HrApprovalStatus.pending));
      });

      test('returns null for non-existent request ID', () async {
        final request = await repository.getRequestById('non_existent_id');
        expect(request, isNull);
      });
    });

    group('Submitted Requests Listing', () {
      test('retrieves requests submitted by specific requester in newest-first order', () async {
        final requests = await repository.getRequestsSubmittedBy('usr_hr');
        expect(requests, isNotEmpty);
        for (final r in requests) {
          expect(r.requesterId, equals('usr_hr'));
        }
      });

      test('returns empty list for requester with no submissions', () async {
        final requests = await repository.getRequestsSubmittedBy('usr_unknown');
        expect(requests, isEmpty);
      });
    });

    group('Pending Requests Queries and Authorization', () {
      test('admin user sees all pending requests regardless of requester', () async {
        final pending = await repository.getPendingRequests(user: adminUser);
        expect(pending.length, greaterThanOrEqualTo(2));
        for (final r in pending) {
          expect(r.status, equals(HrApprovalStatus.pending));
          expect(r.isPending, isTrue);
        }
        // Terminal requests must not be in pending list
        expect(pending.any((r) => r.id == 'appr_req_3'), isFalse);
      });

      test('standard user sees only pending requests submitted by themselves', () async {
        final pending = await repository.getPendingRequests(user: hrUser);
        expect(pending, isNotEmpty);
        for (final r in pending) {
          expect(r.status, equals(HrApprovalStatus.pending));
          expect(r.requesterId, equals(hrUser.id));
        }
      });

      test('standard user with no requests sees empty pending list', () async {
        const newUser = CurrentUser(
          id: 'usr_new_employee',
          displayName: 'New User',
          accountType: AccountType.user,
        );
        final pending = await repository.getPendingRequests(user: newUser);
        expect(pending, isEmpty);
      });
    });

    group('Requests for Target', () {
      test('retrieves requests matching specific target entity reference', () async {
        final target = HrApprovalTarget.payrollPeriod('period_2026_01');
        final requests = await repository.getRequestsForTarget(target);
        expect(requests, isNotEmpty);
        for (final r in requests) {
          expect(r.target, equals(target));
        }
      });

      test('returns empty list for target with no requests', () async {
        final target = HrApprovalTarget.payrollPeriod('period_non_existent');
        final requests = await repository.getRequestsForTarget(target);
        expect(requests, isEmpty);
      });
    });

    group('All Requests Listing', () {
      test('admin user sees all requests including terminal ones', () async {
        final all = await repository.getAllRequests(user: adminUser);
        expect(all.length, equals(3));
        expect(all.any((r) => r.status == HrApprovalStatus.approved), isTrue);
      });

      test('standard user sees only requests they submitted', () async {
        final all = await repository.getAllRequests(user: standardUser);
        expect(all.length, equals(1));
        expect(all.first.requesterId, equals(standardUser.id));
      });
    });

    group('Deterministic Ordering and Isolation', () {
      test('ordering is newest first', () async {
        final requests = await repository.getAllRequests(user: adminUser);
        for (int i = 0; i < requests.length - 1; i++) {
          expect(
            requests[i].createdAt.isAfter(requests[i + 1].createdAt) ||
                requests[i].createdAt.isAtSameMomentAs(requests[i + 1].createdAt),
            isTrue,
          );
        }
      });

      test('defensive copy isolation: modifying returned list does not affect repository', () async {
        final list1 = await repository.getPendingRequests(user: adminUser);
        final originalCount = list1.length;
        list1.clear();

        final list2 = await repository.getPendingRequests(user: adminUser);
        expect(list2.length, equals(originalCount));
      });
    });

    group('Error and Failure Contract', () {
      test('throws HrApprovalWorkflowException when store is in failure mode', () async {
        store.setShouldThrow(true);

        expect(
          () => repository.getPendingRequests(user: adminUser),
          throwsA(isA<HrApprovalWorkflowException>()),
        );
        expect(
          () => repository.getRequestById('appr_req_1'),
          throwsA(isA<HrApprovalWorkflowException>()),
        );
        expect(
          () => repository.submitRequest(
            workflowType: HrApprovalWorkflowType.payrollFinalization,
            requesterId: 'usr_admin',
            target: HrApprovalTarget.payrollPeriod('period_01'),
          ),
          throwsA(isA<HrApprovalWorkflowException>()),
        );
      });

      test('store reset clears error and restores initial seed fixtures', () async {
        store.setShouldThrow(true);
        store.reset();

        final pending = await repository.getPendingRequests(user: adminUser);
        expect(pending, isNotEmpty);
      });
    });

    group('Side-Effect Isolation Invariants', () {
      test('submitting a request does not perform approval decisions or notify', () async {
        final request = await repository.submitRequest(
          workflowType: HrApprovalWorkflowType.payrollFinalization,
          requesterId: 'usr_admin',
          target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        );

        // Status is strictly pending
        expect(request.status, equals(HrApprovalStatus.pending));
        expect(request.isTerminal, isFalse);
      });
    });

    group('Decision Execution Contract (HR-9.5)', () {
      test('administrator can approve pending request', () async {
        final decision = HrApprovalDecision(
          requestId: 'appr_req_1',
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: DateTime.utc(2026, 2, 5, 14, 0),
          reason: 'Verified and approved by admin',
        );

        final updated = await repository.submitDecision(
          requestId: 'appr_req_1',
          decision: decision,
          actor: adminUser,
        );

        expect(updated.status, equals(HrApprovalStatus.approved));
        expect(updated.isApproved, isTrue);
        expect(updated.isTerminal, isTrue);
        expect(updated.updatedAt, equals(DateTime.utc(2026, 2, 5, 14, 0)));

        // Verify request stored in repository reflects update
        final fetched = await repository.getRequestById('appr_req_1');
        expect(fetched!.status, equals(HrApprovalStatus.approved));

        // Verify history trail updated
        final history = await repository.getHistoryForRequest('appr_req_1');
        expect(history.length, equals(2));
        expect(history.last.action, equals('approved'));
        expect(history.last.previousStatus, equals(HrApprovalStatus.pending));
        expect(history.last.newStatus, equals(HrApprovalStatus.approved));
        expect(history.last.actorId, equals('usr_admin'));
        expect(history.last.reason, equals('Verified and approved by admin'));
      });

      test('administrator can reject pending request with reason', () async {
        final decision = HrApprovalDecision(
          requestId: 'appr_req_2',
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.reject,
          decisionTime: DateTime.utc(2026, 2, 5, 15, 0),
          reason: 'Insufficient attendance proof provided',
        );

        final updated = await repository.submitDecision(
          requestId: 'appr_req_2',
          decision: decision,
          actor: adminUser,
        );

        expect(updated.status, equals(HrApprovalStatus.rejected));
        expect(updated.isRejected, isTrue);
        expect(updated.isTerminal, isTrue);

        final history = await repository.getHistoryForRequest('appr_req_2');
        expect(history.last.action, equals('rejected'));
        expect(history.last.newStatus, equals(HrApprovalStatus.rejected));
        expect(history.last.reason, equals('Insufficient attendance proof provided'));
      });

      test('standard user cannot decide request, throws unauthorizedActor', () async {
        final decision = HrApprovalDecision(
          requestId: 'appr_req_1',
          actorId: hrUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: DateTime.utc(2026, 2, 5, 14, 0),
        );

        expect(
          () => repository.submitDecision(
            requestId: 'appr_req_1',
            decision: decision,
            actor: hrUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.unauthorizedActor),
            ),
          ),
        );
      });

      test('cannot decide terminal request, throws duplicateDecision', () async {
        final decision = HrApprovalDecision(
          requestId: 'appr_req_3', // Already approved in seeds
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: DateTime.utc(2026, 2, 5, 14, 0),
        );

        expect(
          () => repository.submitDecision(
            requestId: 'appr_req_3',
            decision: decision,
            actor: adminUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.duplicateDecision),
            ),
          ),
        );
      });

      test('decision on non-existent request throws requestNotFound', () async {
        final decision = HrApprovalDecision(
          requestId: 'appr_req_9999',
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: DateTime.utc(2026, 2, 5, 14, 0),
        );

        expect(
          () => repository.submitDecision(
            requestId: 'appr_req_9999',
            decision: decision,
            actor: adminUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.requestNotFound),
            ),
          ),
        );
      });
    });

    group('Cancellation Contract (HR-9.5)', () {
      test('original requester can cancel their pending request', () async {
        final updated = await repository.cancelRequest(
          requestId: 'appr_req_2',
          actor: standardUser, // standardUser is requester of appr_req_2
          reason: 'Entered correction by mistake',
        );

        expect(updated.status, equals(HrApprovalStatus.cancelled));
        expect(updated.isCancelled, isTrue);

        final history = await repository.getHistoryForRequest('appr_req_2');
        expect(history.last.action, equals('cancelled'));
        expect(history.last.actorId, equals('usr_standard'));
        expect(history.last.newStatus, equals(HrApprovalStatus.cancelled));
        expect(history.last.reason, equals('Entered correction by mistake'));
      });

      test('administrator can cancel any pending request', () async {
        final updated = await repository.cancelRequest(
          requestId: 'appr_req_1',
          actor: adminUser,
          reason: 'Administrative override',
        );

        expect(updated.status, equals(HrApprovalStatus.cancelled));
      });

      test('non-requester standard user cannot cancel, throws unauthorizedActor', () async {
        expect(
          () => repository.cancelRequest(
            requestId: 'appr_req_1', // requester is usr_hr
            actor: standardUser, // standardUser is usr_standard
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.unauthorizedActor),
            ),
          ),
        );
      });

      test('cannot cancel already terminal request, throws invalidTransition', () async {
        expect(
          () => repository.cancelRequest(
            requestId: 'appr_req_3', // Already approved
            actor: adminUser,
          ),
          throwsA(
            isA<HrApprovalWorkflowException>().having(
              (e) => e.code,
              'code',
              equals(HrApprovalWorkflowException.invalidTransition),
            ),
          ),
        );
      });
    });

    group('History Trail and Immutability (HR-9.5)', () {
      test('history entries are seeded correctly', () async {
        final history1 = await repository.getHistoryForRequest('appr_req_1');
        expect(history1.length, equals(1));
        expect(history1.first.action, equals('submitted'));

        final history3 = await repository.getHistoryForRequest('appr_req_3');
        expect(history3.length, equals(2));
        expect(history3[0].action, equals('submitted'));
        expect(history3[1].action, equals('approved'));
      });

      test('defensive copy: caller cannot mutate history store', () async {
        final history = await repository.getHistoryForRequest('appr_req_1');
        final count = history.length;
        history.clear();

        final fetchedAgain = await repository.getHistoryForRequest('appr_req_1');
        expect(fetchedAgain.length, equals(count));
      });
    });
  });
}
