import 'package:flutter/foundation.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_request.dart';

/// Sealed hierarchy of states for approval decision actions.
sealed class ApprovalActionState {
  const ApprovalActionState();
}

/// Idle unsubmitted state.
final class ApprovalActionInitial extends ApprovalActionState {
  const ApprovalActionInitial();
}

/// Action execution in progress.
final class ApprovalActionSubmitting extends ApprovalActionState {
  final ApprovalActionType action;

  const ApprovalActionSubmitting(this.action);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalActionSubmitting && other.action == action;

  @override
  int get hashCode => action.hashCode;
}

/// Successful decision execution state.
@immutable
final class ApprovalActionSuccess extends ApprovalActionState {
  final ApprovalActionType action;
  final ApprovalRequest updatedRequest;
  final String message;

  const ApprovalActionSuccess({
    required this.action,
    required this.updatedRequest,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalActionSuccess &&
          other.action == action &&
          other.updatedRequest == updatedRequest &&
          other.message == message;

  @override
  int get hashCode => Object.hash(action, updatedRequest, message);
}

/// State emitted when a decision action fails validation or execution.
@immutable
final class ApprovalActionFailure extends ApprovalActionState {
  final String message;
  final ApprovalActionType? action;

  const ApprovalActionFailure(this.message, {this.action});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalActionFailure &&
          other.message == message &&
          other.action == action;

  @override
  int get hashCode => Object.hash(message, action);
}
