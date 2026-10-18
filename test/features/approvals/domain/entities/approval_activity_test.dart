import 'package:enterprise_crm/features/approvals/domain/entities/approval_action_type.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalActivity Domain Entity', () {
    final timestamp = DateTime.utc(2026, 10, 16, 11, 45);

    final activity = ApprovalActivity(
      id: 'act-001',
      approvalRequestId: 'appr-100',
      actorUserId: 'usr-bob',
      actorUserName: 'Bob Finance',
      action: ApprovalActionType.approved,
      comment: 'Financial verification completed successfully',
      timestamp: timestamp,
      snapshot: const {'step': 1, 'decision': 'approved'},
    );

    test('instantiates with expected attributes', () {
      expect(activity.id, 'act-001');
      expect(activity.approvalRequestId, 'appr-100');
      expect(activity.actorUserId, 'usr-bob');
      expect(activity.actorUserName, 'Bob Finance');
      expect(activity.action, ApprovalActionType.approved);
      expect(
        activity.comment,
        'Financial verification completed successfully',
      );
      expect(activity.timestamp, timestamp);
      expect(activity.snapshot['step'], 1);
    });

    test('copyWith updates fields correctly', () {
      final updated = activity.copyWith(
        comment: 'Updated remarks',
      );

      expect(updated.id, activity.id);
      expect(updated.comment, 'Updated remarks');
      expect(updated.action, activity.action);
    });

    test('equality and hashCode evaluate properly', () {
      final duplicate = ApprovalActivity(
        id: 'act-001',
        approvalRequestId: 'appr-100',
        actorUserId: 'usr-bob',
        actorUserName: 'Bob Finance',
        action: ApprovalActionType.approved,
        comment: 'Financial verification completed successfully',
        timestamp: timestamp,
      );

      expect(activity == duplicate, isTrue);
      expect(activity.hashCode, duplicate.hashCode);
    });
  });

  group('ApprovalActionType Enum', () {
    test('displays clean human labels', () {
      expect(ApprovalActionType.submitted.label, 'Submitted');
      expect(ApprovalActionType.approved.label, 'Approved');
      expect(ApprovalActionType.rejected.label, 'Rejected');
      expect(ApprovalActionType.revisionRequested.label, 'Revision Requested');
      expect(ApprovalActionType.reassigned.label, 'Reassigned');
      expect(ApprovalActionType.cancelled.label, 'Cancelled');
      expect(ApprovalActionType.commentAdded.label, 'Comment Added');
    });
  });
}
