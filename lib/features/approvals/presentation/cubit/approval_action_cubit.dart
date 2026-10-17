import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/policies/approvals_access_policy.dart';
import '../../domain/repositories/approval_repository.dart';
import 'approval_action_state.dart';

/// Cubit executing workflow decision transitions (Approve, Reject, Revision Request, Cancel)
/// with access policy verification and strict input validation.
class ApprovalActionCubit extends Cubit<ApprovalActionState> {
  final ApprovalRepository _repository;

  ApprovalActionCubit(this._repository) : super(const ApprovalActionInitial());

  /// Resets state back to initial idle.
  void reset() {
    emit(const ApprovalActionInitial());
  }

  /// Executes approval of the current step or entire request.
  Future<void> approve({
    required String requestId,
    required CurrentUser actor,
    String? comment,
    ApprovalRequest? request,
  }) async {
    if (request != null && !ApprovalsAccessPolicy.canPerformDecision(actor, request)) {
      emit(
        const ApprovalActionFailure(
          'You do not have permission to approve this request.',
          action: ApprovalActionType.approved,
        ),
      );
      return;
    }

    emit(const ApprovalActionSubmitting(ApprovalActionType.approved));

    try {
      final updated = await _repository.approveRequest(
        requestId: requestId,
        actor: actor,
        comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      );

      if (isClosed) return;
      emit(
        ApprovalActionSuccess(
          action: ApprovalActionType.approved,
          updatedRequest: updated,
          message: 'Request approved successfully.',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        ApprovalActionFailure(
          'Failed to approve request: ${e.toString()}',
          action: ApprovalActionType.approved,
        ),
      );
    }
  }

  /// Rejects the approval request. Requires non-empty reason.
  Future<void> reject({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
    ApprovalRequest? request,
  }) async {
    final trimmedReason = rejectionReason.trim();
    if (trimmedReason.isEmpty) {
      emit(
        const ApprovalActionFailure(
          'Rejection reason cannot be empty.',
          action: ApprovalActionType.rejected,
        ),
      );
      return;
    }

    if (request != null && !ApprovalsAccessPolicy.canPerformDecision(actor, request)) {
      emit(
        const ApprovalActionFailure(
          'You do not have permission to reject this request.',
          action: ApprovalActionType.rejected,
        ),
      );
      return;
    }

    emit(const ApprovalActionSubmitting(ApprovalActionType.rejected));

    try {
      final updated = await _repository.rejectRequest(
        requestId: requestId,
        actor: actor,
        rejectionReason: trimmedReason,
      );

      if (isClosed) return;
      emit(
        ApprovalActionSuccess(
          action: ApprovalActionType.rejected,
          updatedRequest: updated,
          message: 'Request rejected.',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        ApprovalActionFailure(
          'Failed to reject request: ${e.toString()}',
          action: ApprovalActionType.rejected,
        ),
      );
    }
  }

  /// Sends request back to requester for corrections. Requires non-empty notes.
  Future<void> requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
    ApprovalRequest? request,
  }) async {
    final trimmedNotes = revisionNotes.trim();
    if (trimmedNotes.isEmpty) {
      emit(
        const ApprovalActionFailure(
          'Revision notes cannot be empty.',
          action: ApprovalActionType.revisionRequested,
        ),
      );
      return;
    }

    if (request != null && !ApprovalsAccessPolicy.canPerformDecision(actor, request)) {
      emit(
        const ApprovalActionFailure(
          'You do not have permission to request revision for this request.',
          action: ApprovalActionType.revisionRequested,
        ),
      );
      return;
    }

    emit(const ApprovalActionSubmitting(ApprovalActionType.revisionRequested));

    try {
      final updated = await _repository.requestRevision(
        requestId: requestId,
        actor: actor,
        revisionNotes: trimmedNotes,
      );

      if (isClosed) return;
      emit(
        ApprovalActionSuccess(
          action: ApprovalActionType.revisionRequested,
          updatedRequest: updated,
          message: 'Revision requested.',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        ApprovalActionFailure(
          'Failed to request revision: ${e.toString()}',
          action: ApprovalActionType.revisionRequested,
        ),
      );
    }
  }

  /// Cancels / recalls the approval request.
  Future<void> cancel({
    required String requestId,
    required CurrentUser actor,
    String? reason,
    ApprovalRequest? request,
  }) async {
    if (request != null && !ApprovalsAccessPolicy.canCancelRequest(actor, request)) {
      emit(
        const ApprovalActionFailure(
          'You do not have permission to cancel this request.',
          action: ApprovalActionType.cancelled,
        ),
      );
      return;
    }

    emit(const ApprovalActionSubmitting(ApprovalActionType.cancelled));

    try {
      final updated = await _repository.cancelRequest(
        requestId: requestId,
        actor: actor,
        reason: reason?.trim().isNotEmpty == true ? reason!.trim() : null,
      );

      if (isClosed) return;
      emit(
        ApprovalActionSuccess(
          action: ApprovalActionType.cancelled,
          updatedRequest: updated,
          message: 'Request cancelled successfully.',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        ApprovalActionFailure(
          'Failed to cancel request: ${e.toString()}',
          action: ApprovalActionType.cancelled,
        ),
      );
    }
  }
}
