import 'package:flutter/foundation.dart';
import '../../domain/entities/hr_approval_history_entry.dart';
import '../../domain/entities/hr_approval_request.dart';

/// Base state for [HrApprovalDecisionCubit].
sealed class HrApprovalDecisionState {
  const HrApprovalDecisionState();
}

/// Initial state before loading request details or history.
final class HrApprovalDecisionInitial extends HrApprovalDecisionState {
  const HrApprovalDecisionInitial();
}

/// State while loading request details or audit history.
final class HrApprovalDecisionLoading extends HrApprovalDecisionState {
  const HrApprovalDecisionLoading();
}

/// State when request and history are loaded and ready.
final class HrApprovalDecisionReady extends HrApprovalDecisionState {
  final HrApprovalRequest request;
  final List<HrApprovalHistoryEntry> history;
  final bool canDecide;
  final bool canCancel;

  const HrApprovalDecisionReady({
    required this.request,
    required this.history,
    required this.canDecide,
    required this.canCancel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalDecisionReady &&
          runtimeType == other.runtimeType &&
          request == other.request &&
          listEquals(history, other.history) &&
          canDecide == other.canDecide &&
          canCancel == other.canCancel;

  @override
  int get hashCode => Object.hash(
    request,
    Object.hashAll(history),
    canDecide,
    canCancel,
  );
}

/// State while a decision or cancellation is in-flight.
final class HrApprovalDecisionSubmitting extends HrApprovalDecisionState {
  final String action;

  const HrApprovalDecisionSubmitting(this.action);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalDecisionSubmitting &&
          runtimeType == other.runtimeType &&
          action == other.action;

  @override
  int get hashCode => action.hashCode;
}

/// State when a decision or cancellation succeeds.
final class HrApprovalDecisionSuccess extends HrApprovalDecisionState {
  final HrApprovalRequest request;
  final List<HrApprovalHistoryEntry> history;
  final String message;

  const HrApprovalDecisionSuccess({
    required this.request,
    required this.history,
    required this.message,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalDecisionSuccess &&
          runtimeType == other.runtimeType &&
          request == other.request &&
          listEquals(history, other.history) &&
          message == other.message;

  @override
  int get hashCode => Object.hash(request, Object.hashAll(history), message);
}

/// State when an error occurs during load, decision, or cancellation.
final class HrApprovalDecisionFailure extends HrApprovalDecisionState {
  final String message;

  const HrApprovalDecisionFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalDecisionFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
