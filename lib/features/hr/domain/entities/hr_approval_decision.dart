/// Represents the type of approval decision rendered by an authorized actor.
enum HrApprovalDecisionType {
  approve('approve', 'Approve'),
  reject('reject', 'Reject');

  final String value;
  final String label;

  const HrApprovalDecisionType(this.value, this.label);
}

/// Immutable domain representation of a formal decision on an HR approval request.
///
/// Invariants:
/// - Stably linked to [requestId].
/// - [actorId] corresponds to the deciding CRM user account ([CurrentUser.id]).
/// - [decisionTime] is normalized to UTC.
/// - Does not allow retroactive tampering once created.
class HrApprovalDecision {
  final String requestId;
  final String actorId;
  final HrApprovalDecisionType decisionType;
  final DateTime decisionTime;
  final String? reason;

  HrApprovalDecision({
    required this.requestId,
    required this.actorId,
    required this.decisionType,
    required DateTime decisionTime,
    this.reason,
  }) : assert(requestId.trim().isNotEmpty, 'Decision requestId cannot be empty'),
       assert(actorId.trim().isNotEmpty, 'Decision actorId cannot be empty'),
       decisionTime = DateTime.utc(
         decisionTime.year,
         decisionTime.month,
         decisionTime.day,
         decisionTime.hour,
         decisionTime.minute,
         decisionTime.second,
         decisionTime.millisecond,
         decisionTime.microsecond,
       );

  /// Whether this decision approved the request.
  bool get isApproved => decisionType == HrApprovalDecisionType.approve;

  /// Whether this decision rejected the request.
  bool get isRejected => decisionType == HrApprovalDecisionType.reject;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalDecision &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          actorId == other.actorId &&
          decisionType == other.decisionType &&
          decisionTime == other.decisionTime &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
    requestId,
    actorId,
    decisionType,
    decisionTime,
    reason,
  );

  @override
  String toString() =>
      'HrApprovalDecision(requestId: $requestId, actor: $actorId, type: ${decisionType.value}, time: $decisionTime)';
}
