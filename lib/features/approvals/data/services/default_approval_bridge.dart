import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_step.dart';
import '../../domain/inputs/create_approval_request_input.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../domain/services/approval_bridge.dart';

/// Default production-ready implementation of [ApprovalBridge].
///
/// Coordinates request creation through [ApprovalRepository] and automatic
/// alert dispatching via [NotificationDispatcher].
class DefaultApprovalBridge implements ApprovalBridge {
  final ApprovalRepository _repository;
  final NotificationDispatcher? _notificationDispatcher;

  const DefaultApprovalBridge({
    required ApprovalRepository repository,
    NotificationDispatcher? notificationDispatcher,
  })  : _repository = repository,
        _notificationDispatcher = notificationDispatcher;

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
    final input = CreateApprovalRequestInput(
      module: module,
      entityType: entityType,
      entityId: entityId,
      entityTitle: entityTitle,
      requesterId: requester.id,
      requesterName: requester.displayName,
      departmentId: departmentId,
      departmentName: departmentName,
      priority: priority,
      amount: amount,
      currencyCode: currencyCode,
      steps: customSteps,
      metadata: metadata,
    );

    final request = await _repository.submitRequest(input);

    // Automatically notify relevant approvers
    if (_notificationDispatcher != null) {
      final approverId = request.currentStep?.assignedUserId ?? 'usr_admin';
      await _notificationDispatcher.notifyApprovalRequested(
        request: request,
        approverUserId: approverId,
      );
    }

    return request;
  }

  @override
  Future<ApprovalRequest?> getApprovalForEntity({
    required String entityType,
    required String entityId,
  }) async {
    final requests = await _repository.getApprovals();
    try {
      return requests.firstWhere(
        (r) => r.entityType == entityType && r.entityId == entityId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ApprovalRequest>> getApprovalsForModule(CrmModule module) {
    return _repository.getApprovals(module: module);
  }

  // ---------------------------------------------------------------------------
  // Specialized Domain Helper Adapters for Cross-Module Integration
  // ---------------------------------------------------------------------------

  /// Helper to submit a Purchase Order for managerial approval.
  Future<ApprovalRequest> submitPurchaseOrderApproval({
    required String poNumber,
    required String vendorName,
    required double totalAmount,
    required CurrentUser requester,
    String currencyCode = 'USD',
    ApprovalPriority priority = ApprovalPriority.normal,
    Map<String, dynamic> additionalDetails = const {},
  }) {
    return submitForApproval(
      module: CrmModule.purchase,
      entityType: 'purchase_order',
      entityId: poNumber,
      entityTitle: 'Purchase Order #$poNumber - $vendorName',
      requester: requester,
      priority: priority,
      amount: totalAmount,
      currencyCode: currencyCode,
      metadata: {
        'po_number': poNumber,
        'vendor_name': vendorName,
        'total_amount': totalAmount,
        ...additionalDetails,
      },
    );
  }

  /// Helper to submit an Employee Attendance Correction for manager review.
  Future<ApprovalRequest> submitAttendanceCorrectionApproval({
    required String employeeId,
    required String employeeName,
    required DateTime targetDate,
    required String correctionReason,
    required CurrentUser requester,
    ApprovalPriority priority = ApprovalPriority.normal,
  }) {
    final formattedDate =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    return submitForApproval(
      module: CrmModule.hrPayroll,
      entityType: 'attendance_correction',
      entityId: 'att-$employeeId-$formattedDate',
      entityTitle: 'Attendance Correction: $employeeName ($formattedDate)',
      requester: requester,
      priority: priority,
      metadata: {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'target_date': formattedDate,
        'reason': correctionReason,
      },
    );
  }

  /// Helper to submit a Vendor KYC verification for compliance sign-off.
  Future<ApprovalRequest> submitVendorKycApproval({
    required String vendorId,
    required String vendorName,
    required CurrentUser requester,
    ApprovalPriority priority = ApprovalPriority.high,
    Map<String, dynamic> kycDocuments = const {},
  }) {
    return submitForApproval(
      module: CrmModule.vendorManagement,
      entityType: 'vendor_kyc',
      entityId: vendorId,
      entityTitle: 'Vendor KYC Verification: $vendorName',
      requester: requester,
      priority: priority,
      metadata: {
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'documents': kycDocuments,
      },
    );
  }

  /// Helper to submit an Inventory Stock Adjustment for supervisor sign-off.
  Future<ApprovalRequest> submitInventoryAdjustmentApproval({
    required String sku,
    required String itemName,
    required int quantityDelta,
    required String reason,
    required CurrentUser requester,
    ApprovalPriority priority = ApprovalPriority.normal,
  }) {
    return submitForApproval(
      module: CrmModule.inventory,
      entityType: 'stock_adjustment',
      entityId: sku,
      entityTitle: 'Stock Adjustment ($quantityDelta): $itemName ($sku)',
      requester: requester,
      priority: priority,
      metadata: {
        'sku': sku,
        'item_name': itemName,
        'quantity_delta': quantityDelta,
        'reason': reason,
      },
    );
  }
}
