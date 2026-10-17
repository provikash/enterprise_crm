import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/approval_activity.dart';
import '../entities/approval_priority.dart';
import '../entities/approval_request.dart';
import '../entities/approval_status.dart';
import '../inputs/create_approval_request_input.dart';

/// Abstract contract governing approval requests, decision workflows, and audit history.
abstract interface class ApprovalRepository {
  /// Fetches a list of approval requests matching optional filter criteria.
  Future<List<ApprovalRequest>> getApprovals({
    ApprovalStatus? status,
    CrmModule? module,
    ApprovalPriority? priority,
    String? requesterId,
    String? search,
  });

  /// Fetches an approval request by its unique identifier.
  Future<ApprovalRequest?> getApprovalById(String id);

  /// Submits a new workflow request.
  Future<ApprovalRequest> submitRequest(CreateApprovalRequestInput input);

  /// Approves the current step (or finalizes the request).
  Future<ApprovalRequest> approveRequest({
    required String requestId,
    required CurrentUser actor,
    String? comment,
  });

  /// Rejects the request with a mandatory rejection reason.
  Future<ApprovalRequest> rejectRequest({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
  });

  /// Sends the request back to the requester for revisions.
  Future<ApprovalRequest> requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
  });

  /// Cancels a pending request (accessible to requester or administrator).
  Future<ApprovalRequest> cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  });

  /// Retrieves the chronological audit activity trail for a specific request.
  Future<List<ApprovalActivity>> getAuditTrail(String requestId);
}
