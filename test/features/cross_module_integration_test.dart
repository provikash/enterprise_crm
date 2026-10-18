import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/approvals/domain/entities/approval_priority.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_request.dart';
import 'package:enterprise_crm/features/approvals/domain/entities/approval_step.dart';
import 'package:enterprise_crm/features/approvals/domain/services/approval_bridge.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/domain/entities/dispatch_item.dart';
import 'package:enterprise_crm/features/dispatch/domain/inputs/create_dispatch_input.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/create_dispatch_cubit.dart';
import 'package:enterprise_crm/features/dispatch/presentation/bloc/create_dispatch_state.dart';
import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead.dart';
import 'package:enterprise_crm/features/leads/presentation/bloc/lead_assignment_cubit.dart';
import 'package:enterprise_crm/features/leads/presentation/bloc/lead_assignment_state.dart';
import 'package:enterprise_crm/features/leads/presentation/bloc/lead_reassignment_cubit.dart';
import 'package:enterprise_crm/features/leads/presentation/bloc/lead_reassignment_state.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/domain/inputs/create_notification_input.dart';
import 'package:enterprise_crm/features/notifications/domain/services/notification_dispatcher.dart';
import 'package:enterprise_crm/features/payroll/operations/domain/payroll_operations.dart';
import 'package:enterprise_crm/features/payroll/operations/domain/payroll_operations_repository.dart';
import 'package:enterprise_crm/features/payroll/operations/presentation/bloc/payroll_operations_cubit.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/money.dart';
import 'package:enterprise_crm/features/purchase/data/repositories/mock_purchase_repository.dart';
import 'package:enterprise_crm/features/purchase/domain/entities/purchase_order_item.dart';
import 'package:enterprise_crm/features/purchase/domain/inputs/create_purchase_order_input.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/create_purchase_order_cubit.dart';
import 'package:enterprise_crm/features/purchase/presentation/bloc/create_purchase_order_state.dart';

class MockApprovalBridgeSpy implements ApprovalBridge {
  final List<Map<String, dynamic>> submitCalls = [];

  @override
  Future<ApprovalRequest> submitForApproval({
    required CrmModule module,
    required String entityType,
    required String entityId,
    required String entityTitle,
    required CurrentUser requester,
    ApprovalPriority priority = ApprovalPriority.normal,
    double? amount,
    String? currencyCode,
    String? departmentId,
    String? departmentName,
    List<ApprovalStep> customSteps = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    submitCalls.add({
      'module': module,
      'entityType': entityType,
      'entityId': entityId,
      'entityTitle': entityTitle,
      'requester': requester,
      'amount': amount,
      'priority': priority,
      'metadata': metadata,
    });

    return ApprovalRequest(
      id: 'appr-spy-01',
      requestNumber: 'REQ-SPY',
      module: module,
      entityType: entityType,
      entityId: entityId,
      entityTitle: entityTitle,
      requesterId: requester.id,
      requesterName: requester.displayName,
      priority: priority,
      amount: amount,
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<ApprovalRequest?> getApprovalForEntity({
    required String entityType,
    required String entityId,
  }) async => null;

  @override
  Future<List<ApprovalRequest>> getApprovalsForModule(CrmModule module) async => [];
}

class MockNotificationDispatcherSpy implements NotificationDispatcher {
  final List<Map<String, dynamic>> alerts = [];

  @override
  Future<CrmNotification> dispatch(CreateNotificationInput input) async {
    return CrmNotification(
      id: 'notif-spy-01',
      recipientUserId: input.recipientUserId,
      title: input.title,
      body: input.body,
      category: input.category,
      priority: input.priority,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CrmNotification> notifyApprovalRequested({
    required ApprovalRequest request,
    required String approverUserId,
  }) async => dispatch(CreateNotificationInput(
        recipientUserId: approverUserId,
        title: 'Approval Required',
        body: request.entityTitle,
        category: NotificationCategory.approvalRequest,
      ));

  @override
  Future<CrmNotification> notifyApprovalDecision({
    required ApprovalRequest request,
    required String decision,
    String? notes,
  }) async => dispatch(CreateNotificationInput(
        recipientUserId: request.requesterId,
        title: 'Decision',
        body: decision,
        category: NotificationCategory.approvalDecision,
      ));

  @override
  Future<CrmNotification> notifySystemAlert({
    required String recipientUserId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.info,
    CrmModule? module,
  }) async {
    alerts.add({
      'recipientUserId': recipientUserId,
      'title': title,
      'message': message,
      'priority': priority,
      'module': module,
    });

    return CrmNotification(
      id: 'notif-alert-01',
      recipientUserId: recipientUserId,
      title: title,
      body: message,
      category: NotificationCategory.systemAlert,
      priority: priority,
      referenceModule: module,
      createdAt: DateTime.now(),
    );
  }
}

class FakePayrollOperationsRepo implements PayrollOperationsRepository {
  String? lastSubmittedRunId;
  String? lastReleasedBatchId;

  @override
  Future<PayrollOperationsSnapshot> load() async => const PayrollOperationsSnapshot(
        runs: [],
        inputs: [],
        payments: [],
        employees: [],
        payslips: [],
      );

  @override
  Future<PayRun> submitRun(String runId, String actor) async {
    lastSubmittedRunId = runId;
    return PayRun(
      id: runId,
      periodLabel: '2026-10',
      status: PayRunStatus.underReview,
      preparedBy: actor,
      lines: const [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PaymentBatch> releasePayment(String batchId, String actor) async {
    lastReleasedBatchId = batchId;
    return PaymentBatch(
      id: batchId,
      runId: 'run-1',
      periodLabel: '2026-10',
      reference: 'BATCH-001',
      amount: const Money(800000),
      employeeCount: 5,
      status: PaymentBatchStatus.released,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = CurrentUser(
    id: 'usr-purchaser-1',
    displayName: 'Lead Buyer',
    accountType: AccountType.admin,
  );

  group('Phase 2 Cross-Module Integration Tests', () {
    test('Purchase: High-value order (>= 5000) automatically submits to ApprovalBridge and notifies', () async {
      final repo = MockPurchaseRepository();
      final bridgeSpy = MockApprovalBridgeSpy();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = CreatePurchaseOrderCubit(
        repo,
        approvalBridge: bridgeSpy,
        notificationDispatcher: notifSpy,
        currentUser: testUser,
      );

      final input = CreatePurchaseOrderInput(
        vendorName: 'Acme Steel Inc.',
        items: const [
          PurchaseOrderItem(
            id: 'item-1',
            itemName: 'Industrial Turbine',
            sku: 'TRB-900',
            orderedQuantity: 2,
            unitPriceInr: 3000.0,
          ),
        ],
        notes: 'Urgent machinery replacement',
        paymentTerms: 'Net 30',
        shippingAddress: 'Plant 4',
      );

      await cubit.submit(input);

      expect(cubit.state, isA<CreatePurchaseOrderSuccess>());
      expect(bridgeSpy.submitCalls.length, 1);
      expect(bridgeSpy.submitCalls.first['module'], CrmModule.purchase);
      expect(bridgeSpy.submitCalls.first['requester'], testUser);

      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], testUser.id);
      expect(notifSpy.alerts.first['module'], CrmModule.purchase);
    });

    test('Purchase: Standard order (< 5000) does not submit to ApprovalBridge but still notifies user', () async {
      final repo = MockPurchaseRepository();
      final bridgeSpy = MockApprovalBridgeSpy();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = CreatePurchaseOrderCubit(
        repo,
        approvalBridge: bridgeSpy,
        notificationDispatcher: notifSpy,
        currentUser: testUser,
      );

      final input = CreatePurchaseOrderInput(
        vendorName: 'Office Essentials Ltd.',
        items: const [
          PurchaseOrderItem(
            id: 'item-2',
            itemName: 'Office Chairs',
            sku: 'CHR-100',
            orderedQuantity: 4,
            unitPriceInr: 200.0, // 800 subtotal + 18% tax < 5000
          ),
        ],
        notes: 'Standard furniture order',
        paymentTerms: 'Net 30',
        shippingAddress: 'HQ Office',
      );

      await cubit.submit(input);

      expect(cubit.state, isA<CreatePurchaseOrderSuccess>());
      expect(bridgeSpy.submitCalls.isEmpty, isTrue); // Not submitted for approval
      expect(notifSpy.alerts.length, 1); // Notified of creation
      expect(notifSpy.alerts.first['recipientUserId'], testUser.id);
    });

    test('Leads: Assign lead dispatches notification alert to assigned agent', () async {
      final repo = MockLeadRepository();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = LeadAssignmentCubit(
        repo,
        notificationDispatcher: notifSpy,
      );

      await cubit.loadAssignableUsers();
      expect(cubit.state.assignees, isNotEmpty);
      final agent = cubit.state.assignees.first;
      cubit.selectAssignee(agent);

      const unassignedLead = Lead(
        id: 'cross-lead-1',
        name: 'Sarah Connor',
      );

      await cubit.assignLead(lead: unassignedLead);

      expect(cubit.state.submissionStatus, AssignmentSubmissionStatus.success);
      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], agent.id);
      expect(notifSpy.alerts.first['module'], CrmModule.leadManagement);
      expect(notifSpy.alerts.first['title'], contains('Sarah Connor'));
    });

    test('Leads: Reassign lead dispatches notification alert to replacement agent', () async {
      final repo = MockLeadRepository();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = LeadReassignmentCubit(
        repo,
        notificationDispatcher: notifSpy,
      );

      await cubit.loadAssignableUsers();
      expect(cubit.state.assignees.length, greaterThanOrEqualTo(2));
      final originalAgent = cubit.state.assignees[0];
      final replacementAgent = cubit.state.assignees[1];

      cubit.selectAssignee(replacementAgent);

      final assignedLead = Lead(
        id: 'cross-lead-reassign',
        name: 'John Connor',
        assignedUserId: originalAgent.id,
      );

      await cubit.reassignLead(lead: assignedLead, reason: 'Workload balancing');

      expect(cubit.state.submissionStatus, ReassignmentSubmissionStatus.success);
      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], replacementAgent.id);
      expect(notifSpy.alerts.first['module'], CrmModule.leadManagement);
      expect(notifSpy.alerts.first['message'], contains('Workload balancing'));
    });

    test('Dispatch: Creating a dispatch order notifies creator', () async {
      final repo = MockDispatchRepository();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = CreateDispatchCubit(
        repo,
        notificationDispatcher: notifSpy,
        currentUser: testUser,
      );

      final input = CreateDispatchInput(
        orderNumber: 'ORD-991',
        customerName: 'Tech Corp',
        customerPhone: '+1-555-0199',
        deliveryAddress: '42 Silicon Way',
        invoiceNumber: 'INV-991',
        invoiceDate: DateTime.now(),
        invoiceAmount: 12500.0,
        transporterName: 'FedEx Express',
        vehicleNumber: 'TRK-9812',
        driverName: 'Bob Miller',
        driverPhone: '+1-555-0122',
        builtyNumber: 'BL-991',
        builtyDate: DateTime.now(),
        items: const [
          DispatchItem(
            id: 'disp-item-1',
            name: 'Solar Inverter 5kW',
            sku: 'INV-5000',
            quantity: 10.0,
          ),
        ],
      );

      await cubit.submit(input);

      expect(cubit.state, isA<CreateDispatchSuccess>());
      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], testUser.id);
      expect(notifSpy.alerts.first['module'], CrmModule.dispatch);
    });

    test('Payroll: Submitting a pay run triggers ApprovalBridge and NotificationDispatcher', () async {
      final repo = FakePayrollOperationsRepo();
      final bridgeSpy = MockApprovalBridgeSpy();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = PayrollOperationsCubit(
        repo,
        approvalBridge: bridgeSpy,
        notificationDispatcher: notifSpy,
      );

      await cubit.load();
      await cubit.submit('run-2026-10', 'usr_finance_admin');

      expect(repo.lastSubmittedRunId, 'run-2026-10');
      expect(bridgeSpy.submitCalls.length, 1);
      expect(bridgeSpy.submitCalls.first['module'], CrmModule.hrPayroll);
      expect(bridgeSpy.submitCalls.first['entityType'], 'payroll_run');
      expect(bridgeSpy.submitCalls.first['entityId'], 'run-2026-10');

      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], 'usr_finance_admin');
      expect(notifSpy.alerts.first['module'], CrmModule.hrPayroll);
    });

    test('Payroll: Releasing payment dispatches notification alert', () async {
      final repo = FakePayrollOperationsRepo();
      final notifSpy = MockNotificationDispatcherSpy();

      final cubit = PayrollOperationsCubit(
        repo,
        notificationDispatcher: notifSpy,
      );

      await cubit.load();
      await cubit.releasePayment('batch-771', 'usr_finance_admin');

      expect(repo.lastReleasedBatchId, 'batch-771');
      expect(notifSpy.alerts.length, 1);
      expect(notifSpy.alerts.first['recipientUserId'], 'usr_finance_admin');
      expect(notifSpy.alerts.first['priority'], NotificationPriority.success);
    });
  });
}
