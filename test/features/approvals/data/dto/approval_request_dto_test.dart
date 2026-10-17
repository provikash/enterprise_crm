import 'package:enterprise_crm/features/approvals/data/dto/approval_request_dto.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step_status.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalRequestDto Unit Tests', () {
    test('fromJson and toJson round-trip preserves all fields', () {
      final json = {
        'id': 'appr-101',
        'request_number': 'REQ-101',
        'module': 'purchase',
        'entity_type': 'PurchaseOrder',
        'entity_id': 'PO-9821',
        'entity_title': 'Steel Beam Order',
        'requester_id': 'usr-001',
        'requester_name': 'Alice Smith',
        'department_id': 'dept-01',
        'department_name': 'Procurement',
        'status': 'pending',
        'priority': 'urgent',
        'amount': 15000.75,
        'currency_code': 'USD',
        'submitted_at': '2026-10-15T09:30:00.000Z',
        'decided_at': '2026-10-15T11:00:00.000Z',
        'decided_by_user_id': 'usr-admin',
        'decided_by_user_name': 'Admin User',
        'decision_notes': 'All good',
        'current_step_index': 1,
        'steps': [
          {
            'id': 'step-1',
            'step_order': 1,
            'title': 'Dept Head Review',
            'status': 'approved',
            'assigned_role': 'Manager',
          },
        ],
        'audit_trail': [
          {
            'id': 'act-1',
            'approval_request_id': 'appr-101',
            'actor_user_id': 'usr-001',
            'actor_user_name': 'Alice',
            'action': 'submitted',
            'timestamp': '2026-10-15T09:30:00.000Z',
          },
        ],
        'metadata': {'po_number': 'PO-9821'},
      };

      final dto = ApprovalRequestDto.fromJson(json);
      expect(dto.id, 'appr-101');
      expect(dto.requestNumber, 'REQ-101');
      expect(dto.module, 'purchase');
      expect(dto.amount, 15000.75);
      expect(dto.steps.length, 1);
      expect(dto.steps.first.title, 'Dept Head Review');
      expect(dto.auditTrail.length, 1);
      expect(dto.auditTrail.first.action, 'submitted');

      final serialized = dto.toJson();
      expect(serialized['id'], 'appr-101');
      expect(serialized['steps'], isA<List>());
      expect(serialized['metadata']['po_number'], 'PO-9821');
    });

    test('toDomain maps DTO fields accurately to domain entity', () {
      const dto = ApprovalRequestDto(
        id: 'appr-202',
        requestNumber: 'REQ-202',
        module: 'hrPayroll',
        entityType: 'AttendanceCorrection',
        entityId: 'att-12',
        entityTitle: 'Swipe-in Correction',
        requesterId: 'usr-002',
        requesterName: 'Bob Builder',
        status: 'approved',
        priority: 'high',
        amount: 250.0,
        currencyCode: 'USD',
        submittedAt: '2026-10-16T08:00:00.000Z',
        currentStepIndex: 0,
        steps: [
          ApprovalStepDto(
            id: 'step-10',
            stepOrder: 1,
            title: 'HR Approval',
            status: 'approved',
          ),
        ],
      );

      final domain = dto.toDomain();
      expect(domain.id, 'appr-202');
      expect(domain.module, CrmModule.hrPayroll);
      expect(domain.status, ApprovalStatus.approved);
      expect(domain.priority, ApprovalPriority.high);
      expect(domain.steps.length, 1);
      expect(domain.steps.first.status, ApprovalStepStatus.approved);
    });

    test('fromDomain converts domain entity into DTO', () {
      final domain = ApprovalRequest(
        id: 'appr-303',
        requestNumber: 'REQ-303',
        module: CrmModule.vendorManagement,
        entityType: 'VendorKyc',
        entityId: 'vnd-99',
        entityTitle: 'KYC Review',
        requesterId: 'usr-003',
        requesterName: 'Vendor Lead',
        submittedAt: DateTime.utc(2026, 10, 16, 14, 0),
        status: ApprovalStatus.revisionRequested,
        priority: ApprovalPriority.urgent,
        steps: const [
          ApprovalStep(
            id: 'step-30',
            stepOrder: 1,
            title: 'Compliance Check',
            status: ApprovalStepStatus.rejected,
          ),
        ],
      );

      final dto = ApprovalRequestDto.fromDomain(domain);
      expect(dto.id, 'appr-303');
      expect(dto.module, 'vendorManagement');
      expect(dto.status, 'revisionRequested');
      expect(dto.priority, 'urgent');
      expect(dto.steps.first.status, 'rejected');
    });
  });
}
