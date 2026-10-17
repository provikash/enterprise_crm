import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/approval_priority.dart';
import '../entities/approval_request.dart';
import '../entities/approval_step.dart';

/// Decoupled cross-module integration bridge allowing external CRM business modules
/// (Purchase, HR, Vendor, Inventory, Dispatch) to submit and inspect approval workflows
/// without circular dependencies or direct table mutations.
abstract interface class ApprovalBridge {
  /// Submits an entity for approval from any calling CRM module.
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
  });

  /// Queries the active approval request for a specific entity reference.
  Future<ApprovalRequest?> getApprovalForEntity({
    required String entityType,
    required String entityId,
  });

  /// Retrieves all approval requests originated by a specific CRM module.
  Future<List<ApprovalRequest>> getApprovalsForModule(CrmModule module);
}
