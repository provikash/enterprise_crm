import 'package:enterprise_crm/features/approvals/data/mock/mock_approval_store.dart';
import 'package:enterprise_crm/features/approvals/data/repositories/mock_approval_repository.dart';
import 'package:enterprise_crm/features/approvals/data/services/default_approval_bridge.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_status.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/services/notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  late MockApprovalStore approvalStore;
  late MockApprovalRepository approvalRepository;
  late MockNotificationStore notificationStore;
  late MockNotificationRepository notificationRepository;
  late NotificationDispatcher notificationDispatcher;
  late DefaultApprovalBridge bridge;

  setUp(() {
    approvalStore = MockApprovalStore();
    notificationStore = MockNotificationStore();
    notificationRepository = MockNotificationRepository(notificationStore);
    notificationDispatcher = DefaultNotificationDispatcher(notificationRepository);
    approvalRepository = MockApprovalRepository(approvalStore, notificationDispatcher);
    bridge = DefaultApprovalBridge(
      repository: approvalRepository,
      notificationDispatcher: notificationDispatcher,
    );
  });

  group('DefaultApprovalBridge Tests (Phase AN-7)', () {
    test('submitForApproval creates request and dispatches alert to approver', () async {
      final initialNotifs = await notificationRepository.getNotifications(
        recipientUserId: 'usr_admin',
      );
      final initialCount = initialNotifs.length;

      final request = await bridge.submitForApproval(
        module: CrmModule.purchase,
        entityType: 'purchase_order',
        entityId: 'PO-9999',
        entityTitle: 'New Office Server Purchase',
        requester: MockAuthTestFixtures.standardUser,
        priority: ApprovalPriority.high,
        amount: 8500.0,
        currencyCode: 'USD',
      );

      expect(request.id, isNotEmpty);
      expect(request.entityId, 'PO-9999');
      expect(request.status, ApprovalStatus.pending);
      expect(request.requesterId, MockAuthTestFixtures.standardUser.id);

      // Verify notification dispatched to approver
      final updatedNotifs = await notificationRepository.getNotifications(
        recipientUserId: 'usr_admin',
      );
      expect(updatedNotifs.length, initialCount + 1);
      final latest = updatedNotifs.first;
      expect(latest.title, contains('Approval Required'));
      expect(latest.body, contains('New Office Server Purchase'));
    });

    test('getApprovalForEntity retrieves matching request or returns null', () async {
      // Seed item appr-001 has entityType 'purchase_order' and entityId 'po-9821'
      final found = await bridge.getApprovalForEntity(
        entityType: 'purchase_order',
        entityId: 'po-9821',
      );

      expect(found, isNotNull);
      expect(found!.id, 'appr-001');

      final notFound = await bridge.getApprovalForEntity(
        entityType: 'purchase_order',
        entityId: 'non-existent-po',
      );
      expect(notFound, isNull);
    });

    test('getApprovalsForModule filters requests by CRM business module', () async {
      final hrApprovals = await bridge.getApprovalsForModule(CrmModule.hrPayroll);
      expect(hrApprovals.every((r) => r.module == CrmModule.hrPayroll), isTrue);
      expect(hrApprovals.length, greaterThanOrEqualTo(2));
    });

    test('submitPurchaseOrderApproval helper creates purchase approval', () async {
      final request = await bridge.submitPurchaseOrderApproval(
        poNumber: 'PO-2026-X1',
        vendorName: 'Global Supplies Co',
        totalAmount: 12400.50,
        requester: MockAuthTestFixtures.standardUser,
        priority: ApprovalPriority.urgent,
        additionalDetails: {'line_items_count': 12},
      );

      expect(request.module, CrmModule.purchase);
      expect(request.entityType, 'purchase_order');
      expect(request.amount, 12400.50);
      expect(request.priority, ApprovalPriority.urgent);
      expect(request.metadata['vendor_name'], 'Global Supplies Co');
      expect(request.metadata['line_items_count'], 12);
    });

    test('submitAttendanceCorrectionApproval helper creates HR approval', () async {
      final targetDate = DateTime.utc(2026, 10, 10);
      final request = await bridge.submitAttendanceCorrectionApproval(
        employeeId: 'emp-502',
        employeeName: 'Jane Smith',
        targetDate: targetDate,
        correctionReason: 'Biometric fingerprint scanner malfunction',
        requester: MockAuthTestFixtures.standardUser,
      );

      expect(request.module, CrmModule.hrPayroll);
      expect(request.entityType, 'attendance_correction');
      expect(request.entityId, 'att-emp-502-2026-10-10');
      expect(request.metadata['reason'], 'Biometric fingerprint scanner malfunction');
    });

    test('submitVendorKycApproval helper creates vendor compliance approval', () async {
      final request = await bridge.submitVendorKycApproval(
        vendorId: 'vnd-778',
        vendorName: 'Apex Logistics Inc',
        requester: MockAuthTestFixtures.standardUser,
        kycDocuments: {'tax_id_verified': true, 'gst_certificate': 'uploaded'},
      );

      expect(request.module, CrmModule.vendorManagement);
      expect(request.entityType, 'vendor_kyc');
      expect(request.priority, ApprovalPriority.high);
      expect(request.metadata['vendor_name'], 'Apex Logistics Inc');
    });

    test('submitInventoryAdjustmentApproval helper creates stock approval', () async {
      final request = await bridge.submitInventoryAdjustmentApproval(
        sku: 'SKU-TITAN-100',
        itemName: 'Titanium Fastener M8',
        quantityDelta: -50,
        reason: 'Damaged in transit inspection',
        requester: MockAuthTestFixtures.standardUser,
      );

      expect(request.module, CrmModule.inventory);
      expect(request.entityType, 'stock_adjustment');
      expect(request.entityId, 'SKU-TITAN-100');
      expect(request.metadata['quantity_delta'], -50);
    });
  });
}
