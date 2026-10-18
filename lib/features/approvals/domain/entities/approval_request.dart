import 'package:flutter/foundation.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import 'approval_activity.dart';
import 'approval_priority.dart';
import 'approval_status.dart';
import 'approval_step.dart';

/// The authoritative entity representing an approval transaction across any CRM module.
@immutable
class ApprovalRequest {
  final String id;
  final String requestNumber;
  final CrmModule module;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String requesterId;
  final String requesterName;
  final String? departmentId;
  final String? departmentName;
  final ApprovalStatus status;
  final ApprovalPriority priority;
  final double? amount;
  final String? currencyCode;
  final DateTime submittedAt;
  final DateTime? decidedAt;
  final String? decidedByUserId;
  final String? decidedByUserName;
  final String? decisionNotes;
  final int currentStepIndex;
  final List<ApprovalStep> steps;
  final List<ApprovalActivity> auditTrail;
  final Map<String, dynamic> metadata;

  ApprovalRequest({
    required this.id,
    required this.requestNumber,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.requesterId,
    required this.requesterName,
    this.departmentId,
    this.departmentName,
    this.status = ApprovalStatus.pending,
    this.priority = ApprovalPriority.normal,
    this.amount,
    this.currencyCode,
    required this.submittedAt,
    this.decidedAt,
    this.decidedByUserId,
    this.decidedByUserName,
    this.decisionNotes,
    this.currentStepIndex = 0,
    List<ApprovalStep> steps = const [],
    List<ApprovalActivity> auditTrail = const [],
    Map<String, dynamic> metadata = const {},
  })  : steps = List.unmodifiable(steps),
        auditTrail = List.unmodifiable(auditTrail),
        metadata = Map.unmodifiable(metadata);

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;
  bool get isTerminal => status.isTerminal;
  bool get isActionable => status.isActionable;

  /// Returns the active step, or null if beyond the steps list.
  ApprovalStep? get currentStep =>
      (currentStepIndex >= 0 && currentStepIndex < steps.length)
          ? steps[currentStepIndex]
          : null;

  ApprovalRequest copyWith({
    String? id,
    String? requestNumber,
    CrmModule? module,
    String? entityType,
    String? entityId,
    String? entityTitle,
    String? requesterId,
    String? requesterName,
    String? departmentId,
    String? departmentName,
    ApprovalStatus? status,
    ApprovalPriority? priority,
    double? amount,
    String? currencyCode,
    DateTime? submittedAt,
    DateTime? decidedAt,
    String? decidedByUserId,
    String? decidedByUserName,
    String? decisionNotes,
    int? currentStepIndex,
    List<ApprovalStep>? steps,
    List<ApprovalActivity>? auditTrail,
    Map<String, dynamic>? metadata,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      requestNumber: requestNumber ?? this.requestNumber,
      module: module ?? this.module,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityTitle: entityTitle ?? this.entityTitle,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      submittedAt: submittedAt ?? this.submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
      decidedByUserId: decidedByUserId ?? this.decidedByUserId,
      decidedByUserName: decidedByUserName ?? this.decidedByUserName,
      decisionNotes: decisionNotes ?? this.decisionNotes,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      auditTrail: auditTrail ?? this.auditTrail,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalRequest &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          requestNumber == other.requestNumber &&
          module == other.module &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          requesterId == other.requesterId &&
          status == other.status &&
          priority == other.priority &&
          currentStepIndex == other.currentStepIndex;

  @override
  int get hashCode => Object.hash(
    id,
    requestNumber,
    module,
    entityType,
    entityId,
    requesterId,
    status,
    priority,
    currentStepIndex,
  );
}
