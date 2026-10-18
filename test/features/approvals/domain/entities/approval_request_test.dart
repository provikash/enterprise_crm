import 'package:enterprise_crm/features/approvals/domain/entities/approval_activity.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_action_type.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalRequest Domain Entity', () {
    final now = DateTime.utc(2026, 10, 16, 10, 30);

    final request = ApprovalRequest(
      id: 'appr-001',
      requestNumber: 'REQ-2026-0001',
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: 'po-101',
      entityTitle: 'Purchase Order #PO-101',
      requesterId: 'usr-1',
      requesterName: 'Alice',
      departmentId: 'dept-sales',
      departmentName: 'Sales Department',
      status: ApprovalStatus.pending,
      priority: ApprovalPriority.high,
      amount: 15000.0,
      currencyCode: 'USD',
      submittedAt: now,
      currentStepIndex: 0,
      steps: const [
        ApprovalStep(
          id: 'step-1',
          stepOrder: 1,
          title: 'Manager Approval',
          status: ApprovalStepStatus.pending,
        ),
      ],
      auditTrail: [
        ApprovalActivity(
          id: 'act-1',
          approvalRequestId: 'appr-001',
          actorUserId: 'usr-1',
          actorUserName: 'Alice',
          action: ApprovalActionType.submitted,
          timestamp: now,
        ),
      ],
      metadata: const {'source': 'manual'},
    );

    test('instantiates with expected properties', () {
      expect(request.id, 'appr-001');
      expect(request.requestNumber, 'REQ-2026-0001');
      expect(request.module, CrmModule.purchase);
      expect(request.entityType, 'purchase_order');
      expect(request.amount, 15000.0);
      expect(request.isPending, isTrue);
      expect(request.isApproved, isFalse);
      expect(request.isActionable, isTrue);
      expect(request.isTerminal, isFalse);
      expect(request.currentStep?.title, 'Manager Approval');
    });

    test('defensively exposes unmodifiable collections', () {
      expect(
        () => (request.steps as dynamic).add(
          const ApprovalStep(
            id: 's2',
            stepOrder: 2,
            title: 'Test',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (request.auditTrail as dynamic).add(
          ApprovalActivity(
            id: 'a2',
            approvalRequestId: 'appr-001',
            actorUserId: 'u2',
            actorUserName: 'User',
            action: ApprovalActionType.commentAdded,
            timestamp: now,
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (request.metadata as dynamic)['key'] = 'val',
        throwsUnsupportedError,
      );
    });

    test('copyWith produces updated instance with preserved identity', () {
      final updated = request.copyWith(
        status: ApprovalStatus.approved,
        decidedAt: now.add(const Duration(hours: 2)),
        decidedByUserId: 'usr-mgr',
        decidedByUserName: 'Manager Bob',
      );

      expect(updated.id, request.id);
      expect(updated.status, ApprovalStatus.approved);
      expect(updated.isApproved, isTrue);
      expect(updated.isTerminal, isTrue);
      expect(updated.isActionable, isFalse);
      expect(updated.decidedByUserName, 'Manager Bob');
    });

    test('equality and hashCode evaluate correctly', () {
      final duplicate = ApprovalRequest(
        id: 'appr-001',
        requestNumber: 'REQ-2026-0001',
        module: CrmModule.purchase,
        entityType: 'purchase_order',
        entityId: 'po-101',
        entityTitle: 'Purchase Order #PO-101',
        requesterId: 'usr-1',
        requesterName: 'Alice',
        status: ApprovalStatus.pending,
        priority: ApprovalPriority.high,
        submittedAt: now,
      );

      expect(request == duplicate, isTrue);
      expect(request.hashCode, duplicate.hashCode);
    });
  });

  group('ApprovalStatus Enum', () {
    test('lifecycle checks behave consistently', () {
      expect(ApprovalStatus.pending.isActionable, isTrue);
      expect(ApprovalStatus.pending.isTerminal, isFalse);

      expect(ApprovalStatus.revisionRequested.isActionable, isTrue);
      expect(ApprovalStatus.revisionRequested.isTerminal, isFalse);

      expect(ApprovalStatus.approved.isTerminal, isTrue);
      expect(ApprovalStatus.approved.isActionable, isFalse);

      expect(ApprovalStatus.rejected.isTerminal, isTrue);
      expect(ApprovalStatus.cancelled.isTerminal, isTrue);
    });
  });

  group('ApprovalPriority Enum', () {
    test('displays correct labels', () {
      expect(ApprovalPriority.low.displayName, 'Low');
      expect(ApprovalPriority.normal.displayName, 'Normal');
      expect(ApprovalPriority.high.displayName, 'High');
      expect(ApprovalPriority.urgent.displayName, 'Urgent');
    });
  });
}
