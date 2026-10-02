import 'package:flutter/foundation.dart';
import '../../domain/entities/hr_approval_request.dart';

/// Filter mode for viewing approvals.
enum PendingApprovalsFilterMode {
  /// Viewing active pending requests visible to the authorized user.
  pending('Pending Approvals'),

  /// Viewing requests submitted by the current user.
  myRequests('My Requests');

  final String label;
  const PendingApprovalsFilterMode(this.label);
}

/// Base state for [PendingApprovalsCubit].
sealed class PendingApprovalsState {
  final PendingApprovalsFilterMode mode;

  const PendingApprovalsState(this.mode);
}

/// Initial state before any query execution.
final class PendingApprovalsInitial extends PendingApprovalsState {
  const PendingApprovalsInitial() : super(PendingApprovalsFilterMode.pending);
}

/// State while an approvals query is loading.
final class PendingApprovalsLoading extends PendingApprovalsState {
  const PendingApprovalsLoading(super.mode);
}

/// State when approval requests were successfully retrieved.
final class PendingApprovalsLoaded extends PendingApprovalsState {
  final List<HrApprovalRequest> requests;

  const PendingApprovalsLoaded({
    required this.requests,
    required PendingApprovalsFilterMode mode,
  }) : super(mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingApprovalsLoaded &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          listEquals(requests, other.requests);

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(requests));
}

/// State when a query executed successfully but returned 0 requests.
final class PendingApprovalsEmpty extends PendingApprovalsState {
  const PendingApprovalsEmpty(super.mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingApprovalsEmpty &&
          runtimeType == other.runtimeType &&
          mode == other.mode;

  @override
  int get hashCode => mode.hashCode;
}

/// State when approval requests retrieval fails.
final class PendingApprovalsFailure extends PendingApprovalsState {
  final String message;

  const PendingApprovalsFailure({
    required this.message,
    required PendingApprovalsFilterMode mode,
  }) : super(mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingApprovalsFailure &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          message == other.message;

  @override
  int get hashCode => Object.hash(mode, message);
}
