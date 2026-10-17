import 'package:enterprise_crm/features/approvals/domain/entities/approval_action_type.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_activity.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/approvals/domain/services/approval_export_service.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalExportService Unit Tests', () {
    test('escapeCsvCell correctly escapes commas, quotes, and newlines', () {
      expect(ApprovalExportService.escapeCsvCell(null), '');
      expect(ApprovalExportService.escapeCsvCell('simple'), 'simple');
      expect(
        ApprovalExportService.escapeCsvCell('hello, world'),
        '"hello, world"',
      );
      expect(
        ApprovalExportService.escapeCsvCell('say "hello"'),
        '"say ""hello"""',
      );
      expect(
        ApprovalExportService.escapeCsvCell('line 1\nline 2'),
        '"line 1\nline 2"',
      );
      expect(
        ApprovalExportService.escapeCsvCell('line 1\r\nline 2'),
        '"line 1\r\nline 2"',
      );
      expect(
        ApprovalExportService.escapeCsvCell('complex, "name"\nwith note'),
        '"complex, ""name""\nwith note"',
      );
    });

    test('exportApprovalsToCsv returns header row when list is empty', () {
      final csv = ApprovalExportService.exportApprovalsToCsv([]);
      expect(
        csv.trim(),
        'Request ID,Request Number,Module,Entity Type,Entity ID,Entity Title,Requester ID,Requester Name,Department,Status,Priority,Amount,Currency,Current Step,Submitted At,Decided At,Decided By,Decision Notes',
      );
    });

    test('exportApprovalsToCsv formats approval records with RFC-4180 compliance', () {
      final testTime = DateTime.utc(2026, 10, 15, 10, 30);
      final decidedTime = DateTime.utc(2026, 10, 15, 11, 45);

      final requests = [
        ApprovalRequest(
          id: 'appr-001',
          requestNumber: 'REQ-1001',
          module: CrmModule.purchase,
          entityType: 'PurchaseOrder',
          entityId: 'PO-991',
          entityTitle: 'Steel, "Grade A", 500 Tons',
          requesterId: 'usr-1',
          requesterName: 'Alice Smith',
          departmentName: 'Procurement, Operations',
          status: ApprovalStatus.approved,
          priority: ApprovalPriority.urgent,
          amount: 25000.50,
          currencyCode: 'USD',
          submittedAt: testTime,
          decidedAt: decidedTime,
          decidedByUserName: 'Bob Admin',
          decisionNotes: 'Approved unconditionally.\nBudget verified.',
        ),
        ApprovalRequest(
          id: 'appr-002',
          requestNumber: 'REQ-1002',
          module: CrmModule.hrPayroll,
          entityType: 'LeaveRequest',
          entityId: 'LR-12',
          entityTitle: 'Sick Leave',
          requesterId: 'usr-2',
          requesterName: 'Charlie',
          status: ApprovalStatus.pending,
          priority: ApprovalPriority.normal,
          submittedAt: testTime,
        ),
      ];

      final csv = ApprovalExportService.exportApprovalsToCsv(requests);
      final lines = csv.trim().split('\n');

      expect(lines.length >= 3, isTrue);
      expect(lines[0].startsWith('Request ID,Request Number'), isTrue);

      // Verify row 1 contains escaped quotes and commas
      expect(csv.contains('"Steel, ""Grade A"", 500 Tons"'), isTrue);
      expect(csv.contains('"Procurement, Operations"'), isTrue);
      expect(csv.contains('"Approved unconditionally.\nBudget verified."'), isTrue);
      expect(csv.contains('25000.50'), isTrue);
      expect(csv.contains('USD'), isTrue);

      // Verify row 2 with null optional fields
      expect(csv.contains('appr-002'), isTrue);
      expect(csv.contains('REQ-1002'), isTrue);
      expect(csv.contains('Sick Leave'), isTrue);
    });

    test('exportAuditTrailToCsv formats activity timeline correctly', () {
      final testTime = DateTime.utc(2026, 10, 16, 9, 0);
      final request = ApprovalRequest(
        id: 'appr-003',
        requestNumber: 'REQ-1003',
        module: CrmModule.vendorManagement,
        entityType: 'VendorKyc',
        entityId: 'V-55',
        entityTitle: 'KYC Verification',
        requesterId: 'usr-1',
        requesterName: 'Alice',
        submittedAt: testTime,
      );

      final auditTrail = [
        ApprovalActivity(
          id: 'act-001',
          approvalRequestId: 'appr-003',
          actorUserId: 'usr-1',
          actorUserName: 'Alice',
          action: ApprovalActionType.submitted,
          comment: 'Initial submission for "Acme Corp, LLC"',
          timestamp: testTime,
        ),
        ApprovalActivity(
          id: 'act-002',
          approvalRequestId: 'appr-003',
          actorUserId: 'usr-admin',
          actorUserName: 'Admin Lead',
          action: ApprovalActionType.approved,
          comment: 'Verified documents, approved.',
          timestamp: testTime.add(const Duration(hours: 2)),
        ),
      ];

      final csv = ApprovalExportService.exportAuditTrailToCsv(request, auditTrail);
      expect(
        csv.contains('Activity ID,Request Number,Action,Actor User ID,Actor User Name,Comment,Timestamp'),
        isTrue,
      );
      expect(csv.contains('"Initial submission for ""Acme Corp, LLC"""'), isTrue);
      expect(csv.contains('Verified documents, approved.'), isTrue);
    });
  });
}
