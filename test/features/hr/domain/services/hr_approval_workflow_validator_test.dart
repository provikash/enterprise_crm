import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_approval_exception.dart';
import 'package:enterprise_crm/features/hr/domain/services/hr_approval_workflow_validator.dart';

void main() {
  group('HrApprovalWorkflowValidator Tests', () {
    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
    );

    const standardUser = CurrentUser(
      id: 'usr_hr_staff',
      displayName: 'HR Staff',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {'hr.view', 'payroll.view'},
    );

    const otherUser = CurrentUser(
      id: 'usr_other',
      displayName: 'Other User',
      accountType: AccountType.user,
      modules: {CrmModule.leadManagement},
    );

    final baseTime = DateTime.utc(2026, 10, 1, 9, 0);
    final decisionTime = DateTime.utc(2026, 10, 1, 14, 0);

    HrApprovalRequest createPendingRequest({
      String id = 'appr_001',
      String requesterId = 'usr_hr_staff',
    }) {
      return HrApprovalRequest(
        id: id,
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: requesterId,
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        createdAt: baseTime,
      );
    }

    group('validateTransition', () {
      test('permits valid transitions from pending to approved, rejected, cancelled', () {
        final pending = createPendingRequest();

        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: pending,
            nextStatus: HrApprovalStatus.approved,
          ),
          returnsNormally,
        );
        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: pending,
            nextStatus: HrApprovalStatus.rejected,
          ),
          returnsNormally,
        );
        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: pending,
            nextStatus: HrApprovalStatus.cancelled,
          ),
          returnsNormally,
        );
      });

      test('prohibits self-transition from pending to pending', () {
        final pending = createPendingRequest();

        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: pending,
            nextStatus: HrApprovalStatus.pending,
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

      test('prohibits any transition out of terminal state approved', () {
        final approved = createPendingRequest().copyWith(
          status: HrApprovalStatus.approved,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: approved,
            nextStatus: HrApprovalStatus.pending,
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

      test('prohibits any transition out of terminal state rejected', () {
        final rejected = createPendingRequest().copyWith(
          status: HrApprovalStatus.rejected,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: rejected,
            nextStatus: HrApprovalStatus.approved,
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

      test('prohibits any transition out of terminal state cancelled', () {
        final cancelled = createPendingRequest().copyWith(
          status: HrApprovalStatus.cancelled,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateTransition(
            request: cancelled,
            nextStatus: HrApprovalStatus.pending,
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

    group('validateDecision', () {
      test('admin user successfully validates decision on pending request', () {
        final request = createPendingRequest();
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateDecision(
            request: request,
            decision: decision,
            actor: adminUser,
          ),
          returnsNormally,
        );
      });

      test('non-admin user is rejected with unauthorizedActor', () {
        final request = createPendingRequest();
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: standardUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateDecision(
            request: request,
            decision: decision,
            actor: standardUser,
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

      test('decision on already terminal request throws duplicateDecision', () {
        final request = createPendingRequest().copyWith(
          status: HrApprovalStatus.approved,
        );
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateDecision(
            request: request,
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

      test('mismatched requestId throws validationError', () {
        final request = createPendingRequest(id: 'req_A');
        final decision = HrApprovalDecision(
          requestId: 'req_B',
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateDecision(
            request: request,
            decision: decision,
            actor: adminUser,
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

      test('mismatched actorId throws validationError', () {
        final request = createPendingRequest();
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: 'usr_different',
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateDecision(
            request: request,
            decision: decision,
            actor: adminUser,
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

    group('validateCancellation', () {
      test('original requester can cancel pending request', () {
        final request = createPendingRequest(requesterId: standardUser.id);

        expect(
          () => HrApprovalWorkflowValidator.validateCancellation(
            request: request,
            actor: standardUser,
          ),
          returnsNormally,
        );
      });

      test('administrator can cancel any pending request', () {
        final request = createPendingRequest(requesterId: standardUser.id);

        expect(
          () => HrApprovalWorkflowValidator.validateCancellation(
            request: request,
            actor: adminUser,
          ),
          returnsNormally,
        );
      });

      test('unrelated non-admin user cannot cancel request', () {
        final request = createPendingRequest(requesterId: standardUser.id);

        expect(
          () => HrApprovalWorkflowValidator.validateCancellation(
            request: request,
            actor: otherUser,
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

      test('cancellation on terminal request throws invalidTransition', () {
        final request = createPendingRequest().copyWith(
          status: HrApprovalStatus.rejected,
        );

        expect(
          () => HrApprovalWorkflowValidator.validateCancellation(
            request: request,
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

    group('applyDecision', () {
      test('applies approval decision and returns updated request', () {
        final request = createPendingRequest();
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
          reason: 'Reviewed and approved',
        );

        final updated = HrApprovalWorkflowValidator.applyDecision(
          request: request,
          decision: decision,
          actor: adminUser,
        );

        expect(updated.id, equals(request.id));
        expect(updated.status, equals(HrApprovalStatus.approved));
        expect(updated.isApproved, isTrue);
        expect(updated.isPending, isFalse);
        expect(updated.updatedAt, equals(decisionTime));
        // Source request is unchanged
        expect(request.status, equals(HrApprovalStatus.pending));
      });

      test('applies rejection decision and returns updated request', () {
        final request = createPendingRequest();
        final decision = HrApprovalDecision(
          requestId: request.id,
          actorId: adminUser.id,
          decisionType: HrApprovalDecisionType.reject,
          decisionTime: decisionTime,
          reason: 'Correction required in dates',
        );

        final updated = HrApprovalWorkflowValidator.applyDecision(
          request: request,
          decision: decision,
          actor: adminUser,
        );

        expect(updated.status, equals(HrApprovalStatus.rejected));
        expect(updated.isRejected, isTrue);
        expect(updated.updatedAt, equals(decisionTime));
      });
    });

    group('applyCancellation', () {
      test('applies cancellation and returns updated request', () {
        final request = createPendingRequest(requesterId: standardUser.id);
        final cancelTime = DateTime.utc(2026, 10, 1, 11, 0);

        final updated = HrApprovalWorkflowValidator.applyCancellation(
          request: request,
          actor: standardUser,
          cancellationTime: cancelTime,
          reason: 'Submitted by mistake',
        );

        expect(updated.status, equals(HrApprovalStatus.cancelled));
        expect(updated.isCancelled, isTrue);
        expect(updated.updatedAt, equals(cancelTime));
        expect(updated.remarks, equals('Submitted by mistake'));
      });
    });

    group('Privacy and Data Protection Invariants', () {
      test('exceptions and debug output do not leak sensitive compensation figures', () {
        try {
          HrApprovalWorkflowValidator.validateDecision(
            request: createPendingRequest(),
            decision: HrApprovalDecision(
              requestId: 'appr_001',
              actorId: standardUser.id,
              decisionType: HrApprovalDecisionType.approve,
              decisionTime: decisionTime,
            ),
            actor: standardUser,
          );
          fail('Expected exception');
        } on HrApprovalWorkflowException catch (e) {
          expect(e.message, isNot(contains('salary')));
          expect(e.message, isNot(contains('₹')));
          expect(e.message, isNot(contains('gross')));
          expect(e.message, isNot(contains('net')));
        }
      });
    });
  });
}
