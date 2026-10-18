import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/inputs/create_approval_request_input.dart';
import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';

void main() {
  group('MockApprovalRepository', () {
    late MockApprovalStore store;
    late MockApprovalRepository repository;

    final testAdmin = const CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
    );

    setUp(() {
      store = MockApprovalStore();
      repository = MockApprovalRepository(store);
    });

    test('getApprovals returns initial seeded approvals', () async {
      final all = await repository.getApprovals();
      expect(all.length, greaterThanOrEqualTo(6));
    });

    test('getApprovals filters by status', () async {
      final pending = await repository.getApprovals(status: ApprovalStatus.pending);
      expect(pending.every((r) => r.status == ApprovalStatus.pending), isTrue);
      expect(pending.isNotEmpty, isTrue);
    });

    test('getApprovals filters by module and priority', () async {
      final purchaseUrgent = await repository.getApprovals(
        module: CrmModule.purchase,
        priority: ApprovalPriority.urgent,
      );
      expect(purchaseUrgent.length, 1);
      expect(purchaseUrgent.first.id, 'appr-001');
    });

    test('getApprovals filters by search text', () async {
      final searchResults = await repository.getApprovals(search: 'Titanium');
      expect(searchResults.length, 1);
      expect(searchResults.first.id, 'appr-004');
    });

    test('getApprovalById returns matched request or null', () async {
      final found = await repository.getApprovalById('appr-001');
      expect(found, isNotNull);
      expect(found!.id, 'appr-001');

      final notFound = await repository.getApprovalById('non-existent');
      expect(notFound, isNull);
    });

    test('submitRequest inserts a new pending approval', () async {
      final input = CreateApprovalRequestInput(
        module: CrmModule.inventory,
        entityType: 'stock_transfer',
        entityId: 'trans-999',
        entityTitle: 'Warehouse Transfer to Branch B',
        requesterId: 'usr_wh_lead',
        requesterName: 'Walter Warehouse',
        amount: 5000.0,
      );

      final created = await repository.submitRequest(input);
      expect(created.id, startsWith('appr-'));
      expect(created.status, ApprovalStatus.pending);
      expect(created.auditTrail.length, 1);

      final fetched = await repository.getApprovalById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.entityTitle, 'Warehouse Transfer to Branch B');
    });

    test('approveRequest completes approval step and status', () async {
      // appr-001 is on step 1 of 2
      final updated = await repository.approveRequest(
        requestId: 'appr-001',
        actor: testAdmin,
        comment: 'Final executive clearance',
      );

      expect(updated.status, ApprovalStatus.approved);
      expect(updated.decidedByUserId, testAdmin.id);
      expect(updated.auditTrail.last.comment, 'Final executive clearance');
    });

    test('rejectRequest sets rejected status with reason', () async {
      final rejected = await repository.rejectRequest(
        requestId: 'appr-002',
        actor: testAdmin,
        rejectionReason: 'Missing medical certificate attachment',
      );

      expect(rejected.status, ApprovalStatus.rejected);
      expect(rejected.decisionNotes, 'Missing medical certificate attachment');
    });

    test('requestRevision sets revisionRequested status', () async {
      final revision = await repository.requestRevision(
        requestId: 'appr-003',
        actor: testAdmin,
        revisionNotes: 'Please attach latest VAT registration doc',
      );

      expect(revision.status, ApprovalStatus.revisionRequested);
      expect(revision.decisionNotes, 'Please attach latest VAT registration doc');
    });

    test('cancelRequest cancels pending request', () async {
      final cancelled = await repository.cancelRequest(
        requestId: 'appr-002',
        actor: testAdmin,
        reason: 'Employee no longer requesting correction',
      );

      expect(cancelled.status, ApprovalStatus.cancelled);
      expect(cancelled.decisionNotes, 'Employee no longer requesting correction');
    });

    test('getAuditTrail returns full activity trail', () async {
      final trail = await repository.getAuditTrail('appr-001');
      expect(trail.length, 2);
      expect(trail.first.action.name, 'submitted');
    });
  });
}
