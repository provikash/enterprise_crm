import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/approval_activity.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/entities/approval_step.dart';
import '../../domain/entities/approval_step_status.dart';
import '../../domain/inputs/create_approval_request_input.dart';

/// Thread-safe in-memory store for approval requests seeded with realistic enterprise records.
class MockApprovalStore {
  final List<ApprovalRequest> _items = [];
  int _counter = 100;

  MockApprovalStore() {
    reset();
  }

  /// Resets store state to deterministic initial seed data.
  void reset() {
    _items.clear();
    _counter = 100;

    final t0 = DateTime.utc(2026, 10, 15, 9, 0);
    final t1 = DateTime.utc(2026, 10, 15, 11, 30);
    final t2 = DateTime.utc(2026, 10, 15, 14, 15);
    final t3 = DateTime.utc(2026, 10, 15, 16, 0);

    _items.addAll([
      ApprovalRequest(
        id: 'appr-001',
        requestNumber: 'REQ-2026-0001',
        module: CrmModule.purchase,
        entityType: 'purchase_order',
        entityId: 'po-9821',
        entityTitle: 'Purchase Order #PO-9821 (ACME Steel)',
        requesterId: 'usr_buyer',
        requesterName: 'Bob Buyer',
        departmentId: 'dept_procurement',
        departmentName: 'Procurement',
        status: ApprovalStatus.pending,
        priority: ApprovalPriority.urgent,
        amount: 14500.0,
        currencyCode: 'USD',
        submittedAt: t0,
        currentStepIndex: 1,
        steps: [
          ApprovalStep(
            id: 'step-001-1',
            stepOrder: 1,
            title: 'Procurement Lead Review',
            assignedRole: 'Procurement Lead',
            assignedUserId: 'usr_lead',
            assignedUserName: 'Paula Procurement',
            status: ApprovalStepStatus.approved,
            decidedAt: t1,
            decidedByUserId: 'usr_lead',
            comments: 'Vendor quotation verified against rate card',
          ),
          const ApprovalStep(
            id: 'step-001-2',
            stepOrder: 2,
            title: 'Finance Director Sign-off',
            assignedRole: 'Finance Director',
            status: ApprovalStepStatus.pending,
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-001-1',
            approvalRequestId: 'appr-001',
            actorUserId: 'usr_buyer',
            actorUserName: 'Bob Buyer',
            action: ApprovalActionType.submitted,
            comment: 'Urgent steel delivery for Q4 production schedule',
            timestamp: t0,
          ),
          ApprovalActivity(
            id: 'act-001-2',
            approvalRequestId: 'appr-001',
            actorUserId: 'usr_lead',
            actorUserName: 'Paula Procurement',
            action: ApprovalActionType.approved,
            comment: 'Passed initial procurement review',
            timestamp: t1,
          ),
        ],
        metadata: const {
          'poNumber': 'PO-2026-003',
          'po_number': 'PO-9821',
          'linkedPoId': 'po_003',
          'vendorId': 'vnd_acme',
          'vendorName': 'ACME Steel',
        },
      ),
      ApprovalRequest(
        id: 'appr-002',
        requestNumber: 'REQ-2026-0002',
        module: CrmModule.hrPayroll,
        entityType: 'attendance_correction',
        entityId: 'att-501',
        entityTitle: 'Attendance Correction — John Doe (2026-10-12)',
        requesterId: 'usr_jdoe',
        requesterName: 'John Doe',
        departmentId: 'dept_sales',
        departmentName: 'Sales',
        status: ApprovalStatus.pending,
        priority: ApprovalPriority.normal,
        submittedAt: t1,
        currentStepIndex: 0,
        steps: const [
          ApprovalStep(
            id: 'step-002-1',
            stepOrder: 1,
            title: 'Line Manager Verification',
            assignedRole: 'Sales Manager',
            status: ApprovalStepStatus.pending,
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-002-1',
            approvalRequestId: 'appr-002',
            actorUserId: 'usr_jdoe',
            actorUserName: 'John Doe',
            action: ApprovalActionType.submitted,
            comment: 'Biometric reader device malfunction on morning check-in',
            timestamp: t1,
          ),
        ],
        metadata: const {'checkInTime': '09:02 UTC', 'badgeId': 'EMP-104'},
      ),
      ApprovalRequest(
        id: 'appr-003',
        requestNumber: 'REQ-2026-0003',
        module: CrmModule.vendorManagement,
        entityType: 'vendor_kyc',
        entityId: 'vnd-882',
        entityTitle: 'Vendor KYC Approval — Global Logistics Ltd',
        requesterId: 'usr_onboarding',
        requesterName: 'Olivia Onboarding',
        departmentId: 'dept_procurement',
        departmentName: 'Procurement',
        status: ApprovalStatus.pending,
        priority: ApprovalPriority.high,
        submittedAt: t2,
        currentStepIndex: 0,
        steps: const [
          ApprovalStep(
            id: 'step-003-1',
            stepOrder: 1,
            title: 'Compliance & AML Verification',
            assignedRole: 'Compliance Officer',
            status: ApprovalStepStatus.pending,
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-003-1',
            approvalRequestId: 'appr-003',
            actorUserId: 'usr_onboarding',
            actorUserName: 'Olivia Onboarding',
            action: ApprovalActionType.submitted,
            comment: 'Tax certificate and bank authorization letter uploaded',
            timestamp: t2,
          ),
        ],
        metadata: const {'registrationNumber': 'GB-99218274'},
      ),
      ApprovalRequest(
        id: 'appr-004',
        requestNumber: 'REQ-2026-0004',
        module: CrmModule.inventory,
        entityType: 'stock_adjustment',
        entityId: 'itm-titanium-01',
        entityTitle: 'Stock Write-off (-25 units Titanium Rods)',
        requesterId: 'usr_wh_lead',
        requesterName: 'Walter Warehouse',
        departmentId: 'dept_warehouse',
        departmentName: 'Warehouse',
        status: ApprovalStatus.approved,
        priority: ApprovalPriority.normal,
        amount: 3250.0,
        currencyCode: 'USD',
        submittedAt: t1,
        decidedAt: t2,
        decidedByUserId: 'usr_admin',
        decidedByUserName: 'Administrator',
        decisionNotes: 'Damaged in transit; insurance claim logged',
        currentStepIndex: 0,
        steps: [
          ApprovalStep(
            id: 'step-004-1',
            stepOrder: 1,
            title: 'Warehouse Director Sign-off',
            status: ApprovalStepStatus.approved,
            decidedAt: t2,
            decidedByUserId: 'usr_admin',
            comments: 'Approved write-off',
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-004-1',
            approvalRequestId: 'appr-004',
            actorUserId: 'usr_wh_lead',
            actorUserName: 'Walter Warehouse',
            action: ApprovalActionType.submitted,
            comment: 'Water damage during severe storm',
            timestamp: t1,
          ),
          ApprovalActivity(
            id: 'act-004-2',
            approvalRequestId: 'appr-004',
            actorUserId: 'usr_admin',
            actorUserName: 'Administrator',
            action: ApprovalActionType.approved,
            comment: 'Damaged in transit; insurance claim logged',
            timestamp: t2,
          ),
        ],
      ),
      ApprovalRequest(
        id: 'appr-005',
        requestNumber: 'REQ-2026-0005',
        module: CrmModule.hrPayroll,
        entityType: 'payroll_run',
        entityId: 'pay-2026-09',
        entityTitle: 'September 2026 Monthly Payroll Run Finalization',
        requesterId: 'usr_hr_lead',
        requesterName: 'Helen HR',
        departmentId: 'dept_hr',
        departmentName: 'Human Resources',
        status: ApprovalStatus.approved,
        priority: ApprovalPriority.high,
        amount: 84200.0,
        currencyCode: 'USD',
        submittedAt: t0,
        decidedAt: t3,
        decidedByUserId: 'usr_admin',
        decidedByUserName: 'Administrator',
        decisionNotes: 'All attendance deductions reconciled',
        currentStepIndex: 0,
        steps: [
          ApprovalStep(
            id: 'step-005-1',
            stepOrder: 1,
            title: 'Executive Financial Clearance',
            status: ApprovalStepStatus.approved,
            decidedAt: t3,
            decidedByUserId: 'usr_admin',
            comments: 'Cleared for bank disbursement',
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-005-1',
            approvalRequestId: 'appr-005',
            actorUserId: 'usr_hr_lead',
            actorUserName: 'Helen HR',
            action: ApprovalActionType.submitted,
            comment: 'Includes overtime adjustments for operations team',
            timestamp: t0,
          ),
          ApprovalActivity(
            id: 'act-005-2',
            approvalRequestId: 'appr-005',
            actorUserId: 'usr_admin',
            actorUserName: 'Administrator',
            action: ApprovalActionType.approved,
            comment: 'All attendance deductions reconciled',
            timestamp: t3,
          ),
        ],
      ),
      ApprovalRequest(
        id: 'appr-006',
        requestNumber: 'REQ-2026-0006',
        module: CrmModule.purchase,
        entityType: 'purchase_order',
        entityId: 'po-9825',
        entityTitle: 'Purchase Order #PO-9825 (Office Ergonomics)',
        requesterId: 'usr_admin_assistant',
        requesterName: 'Arthur Assistant',
        departmentId: 'dept_admin',
        departmentName: 'Administration',
        status: ApprovalStatus.rejected,
        priority: ApprovalPriority.low,
        amount: 450.0,
        currencyCode: 'USD',
        submittedAt: t1,
        decidedAt: t2,
        decidedByUserId: 'usr_finance',
        decidedByUserName: 'Frank Finance',
        decisionNotes: 'Quarterly office supply budget limit reached. Defer to next quarter.',
        currentStepIndex: 0,
        steps: [
          ApprovalStep(
            id: 'step-006-1',
            stepOrder: 1,
            title: 'Budget Clearance',
            status: ApprovalStepStatus.rejected,
            decidedAt: t2,
            decidedByUserId: 'usr_finance',
            comments: 'Quarterly office supply budget limit reached. Defer to next quarter.',
          ),
        ],
        auditTrail: [
          ApprovalActivity(
            id: 'act-006-1',
            approvalRequestId: 'appr-006',
            actorUserId: 'usr_admin_assistant',
            actorUserName: 'Arthur Assistant',
            action: ApprovalActionType.submitted,
            comment: 'Ergonomic mouse pads and monitors risers',
            timestamp: t1,
          ),
          ApprovalActivity(
            id: 'act-006-2',
            approvalRequestId: 'appr-006',
            actorUserId: 'usr_finance',
            actorUserName: 'Frank Finance',
            action: ApprovalActionType.rejected,
            comment: 'Quarterly office supply budget limit reached. Defer to next quarter.',
            timestamp: t2,
          ),
        ],
      ),
    ]);
  }

  /// Queries approval requests matching optional filter parameters.
  List<ApprovalRequest> getApprovals({
    ApprovalStatus? status,
    CrmModule? module,
    ApprovalPriority? priority,
    String? requesterId,
    String? search,
  }) {
    return _items.where((item) {
      if (status != null && item.status != status) return false;
      if (module != null && item.module != module) return false;
      if (priority != null && item.priority != priority) return false;
      if (requesterId != null && item.requesterId != requesterId) return false;
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final matchesNum = item.requestNumber.toLowerCase().contains(query);
        final matchesTitle = item.entityTitle.toLowerCase().contains(query);
        final matchesRequester =
            item.requesterName.toLowerCase().contains(query);
        if (!matchesNum && !matchesTitle && !matchesRequester) return false;
      }
      return true;
    }).toList();
  }

  /// Finds a single approval request by its ID.
  ApprovalRequest? getApprovalById(String id) {
    try {
      return _items.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Submits a new approval request into the store.
  ApprovalRequest submitRequest(CreateApprovalRequestInput input) {
    _counter++;
    final id = 'appr-$_counter';
    final requestNumber = 'REQ-2026-$_counter';
    final now = DateTime.now().toUtc();

    final steps = input.steps.isNotEmpty
        ? input.steps
        : [
            const ApprovalStep(
              id: 'step-default',
              stepOrder: 1,
              title: 'Standard Review',
            ),
          ];

    final initialActivity = ApprovalActivity(
      id: 'act-$id-1',
      approvalRequestId: id,
      actorUserId: input.requesterId,
      actorUserName: input.requesterName,
      action: ApprovalActionType.submitted,
      comment: 'Initial submission',
      timestamp: now,
    );

    final request = ApprovalRequest(
      id: id,
      requestNumber: requestNumber,
      module: input.module,
      entityType: input.entityType,
      entityId: input.entityId,
      entityTitle: input.entityTitle,
      requesterId: input.requesterId,
      requesterName: input.requesterName,
      departmentId: input.departmentId,
      departmentName: input.departmentName,
      status: ApprovalStatus.pending,
      priority: input.priority,
      amount: input.amount,
      currencyCode: input.currencyCode,
      submittedAt: now,
      currentStepIndex: 0,
      steps: steps,
      auditTrail: [initialActivity],
      metadata: input.metadata,
    );

    _items.insert(0, request);
    return request;
  }

  /// Approves the current step. If all steps are complete, marks request approved.
  ApprovalRequest approveRequest({
    required String requestId,
    required CurrentUser actor,
    String? comment,
  }) {
    final index = _items.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw StateError('Approval request $requestId not found.');
    }

    final current = _items[index];
    if (!current.isActionable) {
      throw StateError('Cannot approve non-actionable request.');
    }

    final now = DateTime.now().toUtc();
    final updatedSteps = List<ApprovalStep>.from(current.steps);
    var nextStepIndex = current.currentStepIndex;
    var newStatus = current.status;

    if (current.currentStepIndex < updatedSteps.length) {
      final activeStep = updatedSteps[current.currentStepIndex];
      updatedSteps[current.currentStepIndex] = activeStep.copyWith(
        status: ApprovalStepStatus.approved,
        decidedAt: now,
        decidedByUserId: actor.id,
        comments: comment,
      );

      if (current.currentStepIndex + 1 < updatedSteps.length) {
        nextStepIndex = current.currentStepIndex + 1;
      } else {
        newStatus = ApprovalStatus.approved;
      }
    } else {
      newStatus = ApprovalStatus.approved;
    }

    final newActivity = ApprovalActivity(
      id: 'act-$requestId-${current.auditTrail.length + 1}',
      approvalRequestId: requestId,
      actorUserId: actor.id,
      actorUserName: actor.displayName,
      action: ApprovalActionType.approved,
      comment: comment,
      timestamp: now,
    );

    final updated = current.copyWith(
      status: newStatus,
      currentStepIndex: nextStepIndex,
      steps: updatedSteps,
      decidedAt: newStatus == ApprovalStatus.approved ? now : current.decidedAt,
      decidedByUserId: newStatus == ApprovalStatus.approved ? actor.id : current.decidedByUserId,
      decidedByUserName: newStatus == ApprovalStatus.approved ? actor.displayName : current.decidedByUserName,
      decisionNotes: comment ?? current.decisionNotes,
      auditTrail: [...current.auditTrail, newActivity],
    );

    _items[index] = updated;
    return updated;
  }

  /// Rejects the approval request.
  ApprovalRequest rejectRequest({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
  }) {
    final index = _items.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw StateError('Approval request $requestId not found.');
    }

    final current = _items[index];
    if (!current.isActionable) {
      throw StateError('Cannot reject non-actionable request.');
    }

    final now = DateTime.now().toUtc();
    final updatedSteps = List<ApprovalStep>.from(current.steps);
    if (current.currentStepIndex < updatedSteps.length) {
      final activeStep = updatedSteps[current.currentStepIndex];
      updatedSteps[current.currentStepIndex] = activeStep.copyWith(
        status: ApprovalStepStatus.rejected,
        decidedAt: now,
        decidedByUserId: actor.id,
        comments: rejectionReason,
      );
    }

    final newActivity = ApprovalActivity(
      id: 'act-$requestId-${current.auditTrail.length + 1}',
      approvalRequestId: requestId,
      actorUserId: actor.id,
      actorUserName: actor.displayName,
      action: ApprovalActionType.rejected,
      comment: rejectionReason,
      timestamp: now,
    );

    final updated = current.copyWith(
      status: ApprovalStatus.rejected,
      decidedAt: now,
      decidedByUserId: actor.id,
      decidedByUserName: actor.displayName,
      decisionNotes: rejectionReason,
      steps: updatedSteps,
      auditTrail: [...current.auditTrail, newActivity],
    );

    _items[index] = updated;
    return updated;
  }

  /// Returns the request for revisions.
  ApprovalRequest requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
  }) {
    final index = _items.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw StateError('Approval request $requestId not found.');
    }

    final current = _items[index];
    if (!current.isActionable) {
      throw StateError('Cannot request revision on non-actionable request.');
    }

    final now = DateTime.now().toUtc();
    final newActivity = ApprovalActivity(
      id: 'act-$requestId-${current.auditTrail.length + 1}',
      approvalRequestId: requestId,
      actorUserId: actor.id,
      actorUserName: actor.displayName,
      action: ApprovalActionType.revisionRequested,
      comment: revisionNotes,
      timestamp: now,
    );

    final updated = current.copyWith(
      status: ApprovalStatus.revisionRequested,
      decisionNotes: revisionNotes,
      auditTrail: [...current.auditTrail, newActivity],
    );

    _items[index] = updated;
    return updated;
  }

  /// Cancels/recalls the approval request.
  ApprovalRequest cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  }) {
    final index = _items.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw StateError('Approval request $requestId not found.');
    }

    final current = _items[index];
    if (!current.isActionable) {
      throw StateError('Cannot cancel non-actionable request.');
    }

    final now = DateTime.now().toUtc();
    final newActivity = ApprovalActivity(
      id: 'act-$requestId-${current.auditTrail.length + 1}',
      approvalRequestId: requestId,
      actorUserId: actor.id,
      actorUserName: actor.displayName,
      action: ApprovalActionType.cancelled,
      comment: reason ?? 'Cancelled by user',
      timestamp: now,
    );

    final updated = current.copyWith(
      status: ApprovalStatus.cancelled,
      decidedAt: now,
      decisionNotes: reason ?? 'Cancelled by user',
      auditTrail: [...current.auditTrail, newActivity],
    );

    _items[index] = updated;
    return updated;
  }
}
