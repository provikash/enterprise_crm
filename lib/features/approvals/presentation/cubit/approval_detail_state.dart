import 'package:flutter/foundation.dart';
import '../../domain/entities/approval_activity.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_step.dart';

/// Sealed hierarchy of states for the Approval Detail view.
sealed class ApprovalDetailState {
  const ApprovalDetailState();
}

/// Initial uninitialized state.
final class ApprovalDetailInitial extends ApprovalDetailState {
  const ApprovalDetailInitial();
}

/// Loading state indicating detail retrieval in progress.
final class ApprovalDetailLoading extends ApprovalDetailState {
  const ApprovalDetailLoading();
}

/// Loaded state containing request data and full audit trail.
@immutable
final class ApprovalDetailLoaded extends ApprovalDetailState {
  final ApprovalRequest request;
  final List<ApprovalActivity> auditTrail;

  const ApprovalDetailLoaded({
    required this.request,
    required this.auditTrail,
  });

  /// Convenience accessor for workflow steps.
  List<ApprovalStep> get steps => request.steps;

  /// Creates a copy of this state with specified parameters overridden.
  ApprovalDetailLoaded copyWith({
    ApprovalRequest? request,
    List<ApprovalActivity>? auditTrail,
  }) {
    return ApprovalDetailLoaded(
      request: request ?? this.request,
      auditTrail: auditTrail ?? this.auditTrail,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalDetailLoaded &&
        other.request == request &&
        listEquals(other.auditTrail, auditTrail);
  }

  @override
  int get hashCode => Object.hash(request, Object.hashAll(auditTrail));
}

/// State emitted when detail loading fails or request is not found.
final class ApprovalDetailFailure extends ApprovalDetailState {
  final String message;

  const ApprovalDetailFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalDetailFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
