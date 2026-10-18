import 'package:flutter/foundation.dart';
import 'approval_step_status.dart';

/// Defines an individual stage in a multi-tier approval workflow.
@immutable
class ApprovalStep {
  final String id;
  final int stepOrder;
  final String title;
  final String? assignedRole;
  final String? assignedUserId;
  final String? assignedUserName;
  final ApprovalStepStatus status;
  final DateTime? decidedAt;
  final String? decidedByUserId;
  final String? comments;

  const ApprovalStep({
    required this.id,
    required this.stepOrder,
    required this.title,
    this.assignedRole,
    this.assignedUserId,
    this.assignedUserName,
    this.status = ApprovalStepStatus.pending,
    this.decidedAt,
    this.decidedByUserId,
    this.comments,
  });

  ApprovalStep copyWith({
    String? id,
    int? stepOrder,
    String? title,
    String? assignedRole,
    String? assignedUserId,
    String? assignedUserName,
    ApprovalStepStatus? status,
    DateTime? decidedAt,
    String? decidedByUserId,
    String? comments,
  }) {
    return ApprovalStep(
      id: id ?? this.id,
      stepOrder: stepOrder ?? this.stepOrder,
      title: title ?? this.title,
      assignedRole: assignedRole ?? this.assignedRole,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      assignedUserName: assignedUserName ?? this.assignedUserName,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedByUserId: decidedByUserId ?? this.decidedByUserId,
      comments: comments ?? this.comments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stepOrder == other.stepOrder &&
          title == other.title &&
          assignedRole == other.assignedRole &&
          assignedUserId == other.assignedUserId &&
          assignedUserName == other.assignedUserName &&
          status == other.status &&
          decidedAt == other.decidedAt &&
          decidedByUserId == other.decidedByUserId &&
          comments == other.comments;

  @override
  int get hashCode => Object.hash(
    id,
    stepOrder,
    title,
    assignedRole,
    assignedUserId,
    assignedUserName,
    status,
    decidedAt,
    decidedByUserId,
    comments,
  );
}
