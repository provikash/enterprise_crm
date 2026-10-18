import 'package:flutter/foundation.dart';
import 'approval_action_type.dart';

/// Append-only immutable record of every mutation or decision in an approval request.
@immutable
class ApprovalActivity {
  final String id;
  final String approvalRequestId;
  final String actorUserId;
  final String actorUserName;
  final ApprovalActionType action;
  final String? comment;
  final DateTime timestamp;
  final Map<String, dynamic> snapshot;

  const ApprovalActivity({
    required this.id,
    required this.approvalRequestId,
    required this.actorUserId,
    required this.actorUserName,
    required this.action,
    this.comment,
    required this.timestamp,
    this.snapshot = const {},
  });

  ApprovalActivity copyWith({
    String? id,
    String? approvalRequestId,
    String? actorUserId,
    String? actorUserName,
    ApprovalActionType? action,
    String? comment,
    DateTime? timestamp,
    Map<String, dynamic>? snapshot,
  }) {
    return ApprovalActivity(
      id: id ?? this.id,
      approvalRequestId: approvalRequestId ?? this.approvalRequestId,
      actorUserId: actorUserId ?? this.actorUserId,
      actorUserName: actorUserName ?? this.actorUserName,
      action: action ?? this.action,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalActivity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          approvalRequestId == other.approvalRequestId &&
          actorUserId == other.actorUserId &&
          actorUserName == other.actorUserName &&
          action == other.action &&
          comment == other.comment &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
    id,
    approvalRequestId,
    actorUserId,
    actorUserName,
    action,
    comment,
    timestamp,
  );
}
