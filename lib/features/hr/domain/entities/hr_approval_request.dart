import 'hr_approval_status.dart';
import 'hr_approval_target.dart';
import 'hr_approval_workflow_type.dart';

/// Immutable domain entity representing an HR approval request.
///
/// Invariants:
/// - Stably identified by [id] (UUID or unique string).
/// - [requesterId] corresponds to a CRM user account ([CurrentUser.id]), NOT an employee ID.
/// - Associated with a specific [target] reference pointing to an underlying HR entity.
/// - Lifecycle begins in [HrApprovalStatus.pending].
/// - [createdAt] is normalized to UTC.
/// - Does not store raw sensitive compensation amounts or private PII payloads.
class HrApprovalRequest {
  final String id;
  final HrApprovalWorkflowType workflowType;
  final String requesterId;
  final HrApprovalTarget target;
  final HrApprovalStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? remarks;

  HrApprovalRequest({
    required this.id,
    required this.workflowType,
    required this.requesterId,
    required this.target,
    this.status = HrApprovalStatus.pending,
    required DateTime createdAt,
    this.updatedAt,
    this.remarks,
  }) : assert(id.trim().isNotEmpty, 'ApprovalRequest id cannot be empty'),
       assert(requesterId.trim().isNotEmpty, 'ApprovalRequest requesterId cannot be empty'),
       createdAt = DateTime.utc(
         createdAt.year,
         createdAt.month,
         createdAt.day,
         createdAt.hour,
         createdAt.minute,
         createdAt.second,
         createdAt.millisecond,
         createdAt.microsecond,
       );

  /// Whether this approval request is currently active and awaiting a decision.
  bool get isPending => status.isPending;

  /// Whether this approval request has reached a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Whether this approval request was approved.
  bool get isApproved => status.isApproved;

  /// Whether this approval request was rejected.
  bool get isRejected => status.isRejected;

  /// Whether this approval request was cancelled.
  bool get isCancelled => status.isCancelled;

  /// Creates a copy of this request with updated attributes.
  HrApprovalRequest copyWith({
    String? id,
    HrApprovalWorkflowType? workflowType,
    String? requesterId,
    HrApprovalTarget? target,
    HrApprovalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remarks,
    bool clearRemarks = false,
  }) {
    return HrApprovalRequest(
      id: id ?? this.id,
      workflowType: workflowType ?? this.workflowType,
      requesterId: requesterId ?? this.requesterId,
      target: target ?? this.target,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workflowType == other.workflowType &&
          requesterId == other.requesterId &&
          target == other.target &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          remarks == other.remarks;

  @override
  int get hashCode => Object.hash(
    id,
    workflowType,
    requesterId,
    target,
    status,
    createdAt,
    updatedAt,
    remarks,
  );

  @override
  String toString() =>
      'HrApprovalRequest(id: $id, type: ${workflowType.identifier}, requesterId: $requesterId, status: ${status.name}, target: $target)';
}
