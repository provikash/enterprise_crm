import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/hr_approval_request.dart';
import '../entities/hr_approval_target.dart';
import '../entities/hr_approval_workflow_type.dart';

/// Abstract domain repository interface for HR approval request workflows.
///
/// Follows repository patterns established across the Enterprise CRM.
/// Cubits and future UI screens depend exclusively on this abstraction.
///
/// Scope Boundaries (HR-9.3):
/// - Request submission.
/// - Request retrieval by unique ID.
/// - Retrieval of requests submitted by a specific CRM user.
/// - Querying pending approval requests visible to the current authorized actor.
/// - Querying approval requests associated with an HR target reference.
/// - Strictly read & request-submission only: decision mutations (approve/reject)
///   are excluded from HR-9.3 and belong to HR-9.5.
abstract interface class HrApprovalRepository {
  /// Submits a new approval request for an HR workflow.
  ///
  /// Initial status must be [HrApprovalStatus.pending].
  /// Throws [HrApprovalWorkflowException] if validation fails or persistence errors occur.
  Future<HrApprovalRequest> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
  });

  /// Retrieves an approval request by its unique stable [id], or `null` if not found.
  Future<HrApprovalRequest?> getRequestById(String id);

  /// Retrieves all approval requests submitted by [requesterId], sorted deterministically.
  Future<List<HrApprovalRequest>> getRequestsSubmittedBy(String requesterId);

  /// Retrieves all active pending approval requests visible to [user].
  ///
  /// If [user] is an administrator, all pending requests are returned.
  /// If [user] is a standard user, only requests visible within their authorized scope
  /// or submitted by them are returned.
  Future<List<HrApprovalRequest>> getPendingRequests({CurrentUser? user});

  /// Retrieves all approval requests associated with the specified [target].
  Future<List<HrApprovalRequest>> getRequestsForTarget(HrApprovalTarget target);

  /// Retrieves all approval requests visible to [user] regardless of status.
  Future<List<HrApprovalRequest>> getAllRequests({CurrentUser? user});
}
