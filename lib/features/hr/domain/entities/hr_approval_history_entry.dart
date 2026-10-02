import 'hr_approval_status.dart';

/// Immutable domain model representing an entry in the approval audit history trail.
///
/// Invariants:
/// - Stably associated with [requestId].
/// - [actorId] corresponds to a CRM user account ([CurrentUser.id]).
/// - [timestamp] is normalized to UTC.
/// - Defensive immutability: history entries cannot be modified after instantiation.
class HrApprovalHistoryEntry {
  final String id;
  final String requestId;
  final String actorId;
  final String action;
  final HrApprovalStatus? previousStatus;
  final HrApprovalStatus newStatus;
  final DateTime timestamp;
  final String? reason;

  HrApprovalHistoryEntry({
    required this.id,
    required this.requestId,
    required this.actorId,
    required this.action,
    this.previousStatus,
    required this.newStatus,
    required DateTime timestamp,
    this.reason,
  }) : assert(id.trim().isNotEmpty, 'HistoryEntry id cannot be empty'),
       assert(requestId.trim().isNotEmpty, 'HistoryEntry requestId cannot be empty'),
       assert(actorId.trim().isNotEmpty, 'HistoryEntry actorId cannot be empty'),
       timestamp = DateTime.utc(
         timestamp.year,
         timestamp.month,
         timestamp.day,
         timestamp.hour,
         timestamp.minute,
         timestamp.second,
         timestamp.millisecond,
         timestamp.microsecond,
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requestId == other.requestId &&
          actorId == other.actorId &&
          action == other.action &&
          previousStatus == other.previousStatus &&
          newStatus == other.newStatus &&
          timestamp == other.timestamp &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
    id,
    requestId,
    actorId,
    action,
    previousStatus,
    newStatus,
    timestamp,
    reason,
  );

  @override
  String toString() =>
      'HrApprovalHistoryEntry(id: $id, req: $requestId, actor: $actorId, action: $action, $previousStatus -> $newStatus)';
}
