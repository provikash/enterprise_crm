import '../../domain/entities/hr_approval_request.dart';

/// Base state for [HrApprovalRequestCubit].
sealed class HrApprovalRequestState {
  const HrApprovalRequestState();
}

/// Initial state before any submission attempt.
final class HrApprovalRequestInitial extends HrApprovalRequestState {
  const HrApprovalRequestInitial();
}

/// State while an approval request submission is in-flight.
final class HrApprovalRequestSubmitting extends HrApprovalRequestState {
  const HrApprovalRequestSubmitting();
}

/// State after an approval request was successfully confirmed and stored by the repository.
final class HrApprovalRequestSuccess extends HrApprovalRequestState {
  final HrApprovalRequest request;

  const HrApprovalRequestSuccess(this.request);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalRequestSuccess &&
          runtimeType == other.runtimeType &&
          request == other.request;

  @override
  int get hashCode => request.hashCode;
}

/// State when approval request submission fails.
final class HrApprovalRequestFailure extends HrApprovalRequestState {
  final String message;

  const HrApprovalRequestFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalRequestFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
