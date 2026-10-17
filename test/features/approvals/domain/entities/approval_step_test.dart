import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalStep Domain Entity', () {
    const step = ApprovalStep(
      id: 'step-1',
      stepOrder: 1,
      title: 'Department Head Review',
      assignedRole: 'Sales Manager',
      assignedUserId: 'usr-10',
      assignedUserName: 'Sarah Manager',
      status: ApprovalStepStatus.pending,
    );

    test('instantiates with expected attributes', () {
      expect(step.id, 'step-1');
      expect(step.stepOrder, 1);
      expect(step.title, 'Department Head Review');
      expect(step.assignedUserId, 'usr-10');
      expect(step.status, ApprovalStepStatus.pending);
      expect(step.decidedAt, isNull);
    });

    test('copyWith creates updated step correctly', () {
      final now = DateTime.utc(2026, 10, 16, 14, 0);
      final approved = step.copyWith(
        status: ApprovalStepStatus.approved,
        decidedAt: now,
        decidedByUserId: 'usr-10',
        comments: 'Verified against Q4 budget',
      );

      expect(approved.id, step.id);
      expect(approved.status, ApprovalStepStatus.approved);
      expect(approved.decidedAt, now);
      expect(approved.comments, 'Verified against Q4 budget');
    });

    test('equality and hashCode evaluate based on step attributes', () {
      const duplicate = ApprovalStep(
        id: 'step-1',
        stepOrder: 1,
        title: 'Department Head Review',
        assignedRole: 'Sales Manager',
        assignedUserId: 'usr-10',
        assignedUserName: 'Sarah Manager',
        status: ApprovalStepStatus.pending,
      );

      expect(step == duplicate, isTrue);
      expect(step.hashCode, duplicate.hashCode);
    });
  });

  group('ApprovalStepStatus Enum', () {
    test('provides clean display labels', () {
      expect(ApprovalStepStatus.pending.label, 'Pending');
      expect(ApprovalStepStatus.approved.label, 'Approved');
      expect(ApprovalStepStatus.rejected.label, 'Rejected');
      expect(ApprovalStepStatus.skipped.label, 'Skipped');
    });
  });
}
