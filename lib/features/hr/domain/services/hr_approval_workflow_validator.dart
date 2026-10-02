import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/hr_approval_decision.dart';
import '../entities/hr_approval_request.dart';
import '../entities/hr_approval_status.dart';
import '../exceptions/hr_approval_exception.dart';

/// Pure domain service enforcing validation, authorization, and state transitions
/// for HR approval workflows.
///
/// Invariants:
/// - Only requests in [HrApprovalStatus.pending] can undergo transitions.
/// - Terminal states ([HrApprovalStatus.approved], [HrApprovalStatus.rejected], [HrApprovalStatus.cancelled])
///   are immutable and can never transition again.
/// - Approval and Rejection decisions require administrative authority ([CurrentUser.isAdmin]),
///   as confirmed in HR-9.1 requirements audit.
/// - Cancellation is restricted to the original requester ([HrApprovalRequest.requesterId])
///   or a global administrator.
abstract final class HrApprovalWorkflowValidator {
  /// Validates whether [request] can legally transition to [nextStatus].
  ///
  /// Throws [HrApprovalWorkflowException] with [HrApprovalWorkflowException.invalidTransition]
  /// if the transition is prohibited.
  static void validateTransition({
    required HrApprovalRequest request,
    required HrApprovalStatus nextStatus,
  }) {
    if (request.status.isTerminal) {
      throw HrApprovalWorkflowException(
        'Cannot transition request "${request.id}" from terminal status "${request.status.value}" to "${nextStatus.value}".',
        code: HrApprovalWorkflowException.invalidTransition,
      );
    }

    if (!request.status.canTransitionTo(nextStatus)) {
      throw HrApprovalWorkflowException(
        'Illegal state transition from "${request.status.value}" to "${nextStatus.value}" for request "${request.id}".',
        code: HrApprovalWorkflowException.invalidTransition,
      );
    }
  }

  /// Validates whether [actor] is authorized to render [decision] on [request].
  ///
  /// Throws [HrApprovalWorkflowException] on validation or authorization failure.
  static void validateDecision({
    required HrApprovalRequest request,
    required HrApprovalDecision decision,
    required CurrentUser actor,
  }) {
    if (decision.requestId != request.id) {
      throw HrApprovalWorkflowException(
        'Decision requestId "${decision.requestId}" does not match target request ID "${request.id}".',
        code: HrApprovalWorkflowException.validationError,
      );
    }

    if (decision.actorId != actor.id) {
      throw HrApprovalWorkflowException(
        'Decision actorId "${decision.actorId}" does not match authenticated user ID "${actor.id}".',
        code: HrApprovalWorkflowException.validationError,
      );
    }

    if (request.status.isTerminal) {
      throw HrApprovalWorkflowException(
        'Cannot decide request "${request.id}" because it is already in terminal status "${request.status.value}".',
        code: HrApprovalWorkflowException.duplicateDecision,
      );
    }

    // Authorization check: Only Administrators currently hold confirmed decision authority.
    if (!actor.isAdmin) {
      throw HrApprovalWorkflowException(
        'User "${actor.id}" lacks administrative authorization to make approval decisions on HR workflows.',
        code: HrApprovalWorkflowException.unauthorizedActor,
      );
    }
  }

  /// Validates whether [actor] is authorized to cancel [request].
  ///
  /// Throws [HrApprovalWorkflowException] if [request] is terminal or [actor] is unauthorized.
  static void validateCancellation({
    required HrApprovalRequest request,
    required CurrentUser actor,
  }) {
    if (request.status.isTerminal) {
      throw HrApprovalWorkflowException(
        'Cannot cancel request "${request.id}" because it is already in terminal status "${request.status.value}".',
        code: HrApprovalWorkflowException.invalidTransition,
      );
    }

    // Cancellation allowed only by original requester or administrator.
    final isRequester = actor.id == request.requesterId;
    if (!isRequester && !actor.isAdmin) {
      throw HrApprovalWorkflowException(
        'User "${actor.id}" is neither the original requester nor an administrator; cancellation denied.',
        code: HrApprovalWorkflowException.unauthorizedActor,
      );
    }
  }

  /// Pure transition helper that applies an authorized [decision] to [request].
  ///
  /// Returns a new immutable [HrApprovalRequest] reflecting the updated status.
  static HrApprovalRequest applyDecision({
    required HrApprovalRequest request,
    required HrApprovalDecision decision,
    required CurrentUser actor,
  }) {
    validateDecision(request: request, decision: decision, actor: actor);

    final nextStatus = decision.isApproved
        ? HrApprovalStatus.approved
        : HrApprovalStatus.rejected;

    validateTransition(request: request, nextStatus: nextStatus);

    return request.copyWith(
      status: nextStatus,
      updatedAt: decision.decisionTime,
    );
  }

  /// Pure transition helper that applies an authorized cancellation to [request].
  ///
  /// Returns a new immutable [HrApprovalRequest] reflecting the cancelled status.
  static HrApprovalRequest applyCancellation({
    required HrApprovalRequest request,
    required CurrentUser actor,
    required DateTime cancellationTime,
    String? reason,
  }) {
    validateCancellation(request: request, actor: actor);
    validateTransition(request: request, nextStatus: HrApprovalStatus.cancelled);

    return request.copyWith(
      status: HrApprovalStatus.cancelled,
      updatedAt: DateTime.utc(
        cancellationTime.year,
        cancellationTime.month,
        cancellationTime.day,
        cancellationTime.hour,
        cancellationTime.minute,
        cancellationTime.second,
      ),
      remarks: reason ?? request.remarks,
    );
  }
}
