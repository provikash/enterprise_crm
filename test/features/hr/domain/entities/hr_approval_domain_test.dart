import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_decision.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_history_entry.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_request.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_target.dart';
import 'package:enterprise_crm/features/hr/domain/entities/hr_approval_workflow_type.dart';
import 'package:enterprise_crm/features/hr/domain/exceptions/hr_approval_exception.dart';

void main() {
  group('HrApprovalStatus Domain Tests', () {
    test('status definitions and flags behave correctly', () {
      expect(HrApprovalStatus.pending.isPending, isTrue);
      expect(HrApprovalStatus.pending.isTerminal, isFalse);

      expect(HrApprovalStatus.approved.isApproved, isTrue);
      expect(HrApprovalStatus.approved.isTerminal, isTrue);

      expect(HrApprovalStatus.rejected.isRejected, isTrue);
      expect(HrApprovalStatus.rejected.isTerminal, isTrue);

      expect(HrApprovalStatus.cancelled.isCancelled, isTrue);
      expect(HrApprovalStatus.cancelled.isTerminal, isTrue);
    });

    test('canTransitionTo permits valid transitions from pending only', () {
      expect(HrApprovalStatus.pending.canTransitionTo(HrApprovalStatus.approved), isTrue);
      expect(HrApprovalStatus.pending.canTransitionTo(HrApprovalStatus.rejected), isTrue);
      expect(HrApprovalStatus.pending.canTransitionTo(HrApprovalStatus.cancelled), isTrue);
      expect(HrApprovalStatus.pending.canTransitionTo(HrApprovalStatus.pending), isFalse);

      // Terminal states cannot transition
      expect(HrApprovalStatus.approved.canTransitionTo(HrApprovalStatus.pending), isFalse);
      expect(HrApprovalStatus.approved.canTransitionTo(HrApprovalStatus.rejected), isFalse);
      expect(HrApprovalStatus.rejected.canTransitionTo(HrApprovalStatus.approved), isFalse);
      expect(HrApprovalStatus.cancelled.canTransitionTo(HrApprovalStatus.pending), isFalse);
    });

    test('fromValue resolves string values correctly', () {
      expect(HrApprovalStatus.fromValue('pending'), equals(HrApprovalStatus.pending));
      expect(HrApprovalStatus.fromValue('APPROVED'), equals(HrApprovalStatus.approved));
      expect(HrApprovalStatus.fromValue(' Rejected '), equals(HrApprovalStatus.rejected));
      expect(HrApprovalStatus.fromValue('cancelled'), equals(HrApprovalStatus.cancelled));
      expect(HrApprovalStatus.fromValue('unknown'), isNull);
      expect(HrApprovalStatus.fromValue(null), isNull);
    });
  });

  group('HrApprovalTarget Domain Tests', () {
    test('preserves target identity and equality', () {
      final target1 = HrApprovalTarget(
        targetModule: CrmModule.hrPayroll,
        targetEntityType: 'payroll_period',
        targetEntityId: 'period_2026_01',
      );
      final target2 = HrApprovalTarget.payrollPeriod('period_2026_01');

      expect(target1, equals(target2));
      expect(target1.hashCode, equals(target2.hashCode));
      expect(target1.targetModule, equals(CrmModule.hrPayroll));
      expect(target1.targetEntityType, equals('payroll_period'));
      expect(target1.targetEntityId, equals('period_2026_01'));
    });

    test('factory constructors create expected entity types', () {
      final attendanceTarget = HrApprovalTarget.attendanceRecord('att_99');
      expect(attendanceTarget.targetEntityType, equals('attendance_record'));
      expect(attendanceTarget.targetEntityId, equals('att_99'));

      final documentTarget = HrApprovalTarget.employeeDocument('doc_123');
      expect(documentTarget.targetEntityType, equals('employee_document'));
      expect(documentTarget.targetEntityId, equals('doc_123'));
    });

    test('copyWith updates properties correctly', () {
      final target = HrApprovalTarget.payrollPeriod('period_01');
      final updated = target.copyWith(targetEntityId: 'period_02');

      expect(updated.targetEntityId, equals('period_02'));
      expect(updated.targetEntityType, equals('payroll_period'));
      expect(target.targetEntityId, equals('period_01'));
    });

    test('asserts on empty entityId or entityType', () {
      expect(
        () => HrApprovalTarget(
          targetModule: CrmModule.hrPayroll,
          targetEntityType: '',
          targetEntityId: 'id_1',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => HrApprovalTarget(
          targetModule: CrmModule.hrPayroll,
          targetEntityType: 'type',
          targetEntityId: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('HrApprovalWorkflowType Domain Tests', () {
    test('contains confirmed and candidate workflow identifiers', () {
      expect(
        HrApprovalWorkflowType.payrollFinalization.identifier,
        equals('hr.payroll_finalization'),
      );
      expect(
        HrApprovalWorkflowType.attendanceCorrection.identifier,
        equals('hr.attendance_correction'),
      );
      expect(
        HrApprovalWorkflowType.documentVerification.identifier,
        equals('hr.document_verification'),
      );
    });

    test('fromIdentifier parses valid identifiers and rejects unknown', () {
      expect(
        HrApprovalWorkflowType.fromIdentifier('hr.payroll_finalization'),
        equals(HrApprovalWorkflowType.payrollFinalization),
      );
      expect(
        HrApprovalWorkflowType.fromIdentifier('HR.ATTENDANCE_CORRECTION'),
        equals(HrApprovalWorkflowType.attendanceCorrection),
      );
      expect(HrApprovalWorkflowType.fromIdentifier('unknown.workflow'), isNull);
      expect(HrApprovalWorkflowType.fromIdentifier(null), isNull);
    });
  });

  group('HrApprovalRequest Domain Tests', () {
    final now = DateTime.utc(2026, 10, 1, 10, 30);
    final target = HrApprovalTarget.payrollPeriod('period_2026_01');

    test('instantiates with valid values and normalizes createdAt to UTC', () {
      final localTime = DateTime(2026, 10, 1, 15, 0);
      final request = HrApprovalRequest(
        id: 'appr_001',
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_admin',
        target: target,
        createdAt: localTime,
      );

      expect(request.id, equals('appr_001'));
      expect(request.workflowType, equals(HrApprovalWorkflowType.payrollFinalization));
      expect(request.requesterId, equals('usr_admin'));
      expect(request.target, equals(target));
      expect(request.status, equals(HrApprovalStatus.pending));
      expect(request.isPending, isTrue);
      expect(request.isTerminal, isFalse);
      expect(request.createdAt.isUtc, isTrue);
    });

    test('identity boundary: requesterId is CRM User ID, not Employee ID', () {
      final request = HrApprovalRequest(
        id: 'appr_002',
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        requesterId: 'usr_hr_specialist', // CRM ManagedUser ID
        target: HrApprovalTarget.attendanceRecord('att_456'), // points to attendance entity
        createdAt: now,
      );

      // Verify no confusion between CRM user and employee
      expect(request.requesterId.startsWith('usr_'), isTrue);
      expect(request.target.targetEntityId.startsWith('att_'), isTrue);
    });

    test('immutability and value equality', () {
      final req1 = HrApprovalRequest(
        id: 'appr_001',
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_admin',
        target: target,
        createdAt: now,
      );
      final req2 = HrApprovalRequest(
        id: 'appr_001',
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_admin',
        target: target,
        createdAt: now,
      );

      expect(req1, equals(req2));
      expect(req1.hashCode, equals(req2.hashCode));
    });

    test('copyWith produces expected updated instances', () {
      final request = HrApprovalRequest(
        id: 'appr_001',
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_admin',
        target: target,
        createdAt: now,
        remarks: 'Initial notes',
      );

      final updated = request.copyWith(
        status: HrApprovalStatus.approved,
        clearRemarks: true,
      );

      expect(updated.id, equals('appr_001'));
      expect(updated.status, equals(HrApprovalStatus.approved));
      expect(updated.remarks, isNull);
      expect(request.status, equals(HrApprovalStatus.pending));
      expect(request.remarks, equals('Initial notes'));
    });

    test('asserts on empty id or requesterId', () {
      expect(
        () => HrApprovalRequest(
          id: '',
          workflowType: HrApprovalWorkflowType.payrollFinalization,
          requesterId: 'usr_admin',
          target: target,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => HrApprovalRequest(
          id: 'appr_001',
          workflowType: HrApprovalWorkflowType.payrollFinalization,
          requesterId: '  ',
          target: target,
          createdAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('HrApprovalDecision Domain Tests', () {
    final decisionTime = DateTime.utc(2026, 10, 1, 12, 0);

    test('instantiates with valid properties and normalizes time to UTC', () {
      final decision = HrApprovalDecision(
        requestId: 'appr_001',
        actorId: 'usr_admin',
        decisionType: HrApprovalDecisionType.approve,
        decisionTime: decisionTime,
        reason: 'All attendance records verified',
      );

      expect(decision.requestId, equals('appr_001'));
      expect(decision.actorId, equals('usr_admin'));
      expect(decision.isApproved, isTrue);
      expect(decision.isRejected, isFalse);
      expect(decision.reason, equals('All attendance records verified'));
      expect(decision.decisionTime.isUtc, isTrue);
    });

    test('equality and hashCode support', () {
      final d1 = HrApprovalDecision(
        requestId: 'appr_001',
        actorId: 'usr_admin',
        decisionType: HrApprovalDecisionType.reject,
        decisionTime: decisionTime,
        reason: 'Mismatch in tax calculation',
      );
      final d2 = HrApprovalDecision(
        requestId: 'appr_001',
        actorId: 'usr_admin',
        decisionType: HrApprovalDecisionType.reject,
        decisionTime: decisionTime,
        reason: 'Mismatch in tax calculation',
      );

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('asserts on empty requestId or actorId', () {
      expect(
        () => HrApprovalDecision(
          requestId: '',
          actorId: 'usr_admin',
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => HrApprovalDecision(
          requestId: 'appr_001',
          actorId: '  ',
          decisionType: HrApprovalDecisionType.approve,
          decisionTime: decisionTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('HrApprovalHistoryEntry Domain Tests', () {
    final timestamp = DateTime.utc(2026, 10, 1, 12, 15);

    test('creates immutable audit entry with UTC timestamp', () {
      final entry = HrApprovalHistoryEntry(
        id: 'hist_001',
        requestId: 'appr_001',
        actorId: 'usr_admin',
        action: 'approved',
        previousStatus: HrApprovalStatus.pending,
        newStatus: HrApprovalStatus.approved,
        timestamp: timestamp,
        reason: 'Payroll approved for period',
      );

      expect(entry.id, equals('hist_001'));
      expect(entry.requestId, equals('appr_001'));
      expect(entry.actorId, equals('usr_admin'));
      expect(entry.previousStatus, equals(HrApprovalStatus.pending));
      expect(entry.newStatus, equals(HrApprovalStatus.approved));
      expect(entry.timestamp.isUtc, isTrue);
      expect(entry.reason, equals('Payroll approved for period'));
    });

    test('equality and hashCode support', () {
      final e1 = HrApprovalHistoryEntry(
        id: 'hist_001',
        requestId: 'appr_001',
        actorId: 'usr_admin',
        action: 'submitted',
        newStatus: HrApprovalStatus.pending,
        timestamp: timestamp,
      );
      final e2 = HrApprovalHistoryEntry(
        id: 'hist_001',
        requestId: 'appr_001',
        actorId: 'usr_admin',
        action: 'submitted',
        newStatus: HrApprovalStatus.pending,
        timestamp: timestamp,
      );

      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
    });
  });

  group('HrApprovalWorkflowException Tests', () {
    test('formats error string and retains error code', () {
      const ex = HrApprovalWorkflowException(
        'Invalid status transition',
        code: HrApprovalWorkflowException.invalidTransition,
      );

      expect(ex.message, equals('Invalid status transition'));
      expect(ex.code, equals('INVALID_TRANSITION'));
      expect(ex.toString(), contains('INVALID_TRANSITION'));
    });
  });
}
