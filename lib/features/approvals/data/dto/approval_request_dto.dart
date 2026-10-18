import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_activity.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/entities/approval_step.dart';
import '../../domain/entities/approval_step_status.dart';

/// Data Transfer Object representing individual workflow step instances.
class ApprovalStepDto {
  final String id;
  final int stepOrder;
  final String title;
  final String? assignedRole;
  final String? assignedUserId;
  final String? assignedUserName;
  final String status;
  final String? decidedAt;
  final String? decidedByUserId;
  final String? comments;

  const ApprovalStepDto({
    required this.id,
    required this.stepOrder,
    required this.title,
    this.assignedRole,
    this.assignedUserId,
    this.assignedUserName,
    this.status = 'pending',
    this.decidedAt,
    this.decidedByUserId,
    this.comments,
  });

  factory ApprovalStepDto.fromJson(Map<String, dynamic> json) {
    return ApprovalStepDto(
      id: json['id'] as String? ?? '',
      stepOrder: (json['step_order'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      assignedRole: json['assigned_role'] as String?,
      assignedUserId: json['assigned_user_id'] as String?,
      assignedUserName: json['assigned_user_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      decidedAt: json['decided_at'] as String?,
      decidedByUserId: json['decided_by_user_id'] as String?,
      comments: json['comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step_order': stepOrder,
      'title': title,
      if (assignedRole != null) 'assigned_role': assignedRole,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (assignedUserName != null) 'assigned_user_name': assignedUserName,
      'status': status,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (decidedByUserId != null) 'decided_by_user_id': decidedByUserId,
      if (comments != null) 'comments': comments,
    };
  }

  ApprovalStep toDomain() {
    return ApprovalStep(
      id: id,
      stepOrder: stepOrder,
      title: title,
      assignedRole: assignedRole,
      assignedUserId: assignedUserId,
      assignedUserName: assignedUserName,
      status: ApprovalStepStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ApprovalStepStatus.pending,
      ),
      decidedAt: decidedAt != null ? DateTime.tryParse(decidedAt!) : null,
      decidedByUserId: decidedByUserId,
      comments: comments,
    );
  }

  factory ApprovalStepDto.fromDomain(ApprovalStep step) {
    return ApprovalStepDto(
      id: step.id,
      stepOrder: step.stepOrder,
      title: step.title,
      assignedRole: step.assignedRole,
      assignedUserId: step.assignedUserId,
      assignedUserName: step.assignedUserName,
      status: step.status.name,
      decidedAt: step.decidedAt?.toIso8601String(),
      decidedByUserId: step.decidedByUserId,
      comments: step.comments,
    );
  }
}

/// Data Transfer Object representing audit timeline items.
class ApprovalActivityDto {
  final String id;
  final String approvalRequestId;
  final String actorUserId;
  final String actorUserName;
  final String action;
  final String? comment;
  final String timestamp;
  final Map<String, dynamic> snapshot;

  const ApprovalActivityDto({
    required this.id,
    required this.approvalRequestId,
    required this.actorUserId,
    required this.actorUserName,
    required this.action,
    this.comment,
    required this.timestamp,
    this.snapshot = const {},
  });

  factory ApprovalActivityDto.fromJson(Map<String, dynamic> json) {
    return ApprovalActivityDto(
      id: json['id'] as String? ?? '',
      approvalRequestId: json['approval_request_id'] as String? ?? '',
      actorUserId: json['actor_user_id'] as String? ?? '',
      actorUserName: json['actor_user_name'] as String? ?? '',
      action: json['action'] as String? ?? 'submitted',
      comment: json['comment'] as String?,
      timestamp:
          json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      snapshot: (json['snapshot'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approval_request_id': approvalRequestId,
      'actor_user_id': actorUserId,
      'actor_user_name': actorUserName,
      'action': action,
      if (comment != null) 'comment': comment,
      'timestamp': timestamp,
      if (snapshot.isNotEmpty) 'snapshot': snapshot,
    };
  }

  ApprovalActivity toDomain() {
    return ApprovalActivity(
      id: id,
      approvalRequestId: approvalRequestId,
      actorUserId: actorUserId,
      actorUserName: actorUserName,
      action: ApprovalActionType.values.firstWhere(
        (a) => a.name.toLowerCase() == action.toLowerCase(),
        orElse: () => ApprovalActionType.submitted,
      ),
      comment: comment,
      timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
      snapshot: snapshot,
    );
  }

  factory ApprovalActivityDto.fromDomain(ApprovalActivity activity) {
    return ApprovalActivityDto(
      id: activity.id,
      approvalRequestId: activity.approvalRequestId,
      actorUserId: activity.actorUserId,
      actorUserName: activity.actorUserName,
      action: activity.action.name,
      comment: activity.comment,
      timestamp: activity.timestamp.toIso8601String(),
      snapshot: activity.snapshot,
    );
  }
}

/// Authoritative DTO representing an approval request received from backend REST API.
class ApprovalRequestDto {
  final String id;
  final String requestNumber;
  final String module;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String requesterId;
  final String requesterName;
  final String? departmentId;
  final String? departmentName;
  final String status;
  final String priority;
  final double? amount;
  final String? currencyCode;
  final String submittedAt;
  final String? decidedAt;
  final String? decidedByUserId;
  final String? decidedByUserName;
  final String? decisionNotes;
  final int currentStepIndex;
  final List<ApprovalStepDto> steps;
  final List<ApprovalActivityDto> auditTrail;
  final Map<String, dynamic> metadata;

  const ApprovalRequestDto({
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
    this.status = 'pending',
    this.priority = 'normal',
    this.amount,
    this.currencyCode,
    required this.submittedAt,
    this.decidedAt,
    this.decidedByUserId,
    this.decidedByUserName,
    this.decisionNotes,
    this.currentStepIndex = 0,
    this.steps = const [],
    this.auditTrail = const [],
    this.metadata = const {},
  });

  factory ApprovalRequestDto.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    final rawAudit = json['audit_trail'] as List<dynamic>? ?? const [];

    return ApprovalRequestDto(
      id: json['id'] as String? ?? '',
      requestNumber: json['request_number'] as String? ?? '',
      module: json['module'] as String? ?? 'purchase',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      entityTitle: json['entity_title'] as String? ?? '',
      requesterId: json['requested_by'] as String? ??
          json['requester_id'] as String? ??
          '',
      requesterName: json['requester_name'] as String? ?? '',
      departmentId: json['department_id'] as String?,
      departmentName: json['department_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'normal',
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currency_code'] as String?,
      submittedAt: json['created_at'] as String? ??
          json['submitted_at'] as String? ??
          DateTime.now().toIso8601String(),
      decidedAt: json['decided_at'] as String?,
      decidedByUserId: json['decided_by_user_id'] as String? ??
          json['decided_by'] as String?,
      decidedByUserName: json['decided_by_user_name'] as String?,
      decisionNotes: json['decision_notes'] as String? ??
          json['comments'] as String?,
      currentStepIndex: (json['current_step_index'] as num?)?.toInt() ?? 0,
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(ApprovalStepDto.fromJson)
          .toList(),
      auditTrail: rawAudit
          .whereType<Map<String, dynamic>>()
          .map(ApprovalActivityDto.fromJson)
          .toList(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_number': requestNumber,
      'module': module,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_title': entityTitle,
      'requester_id': requesterId,
      'requester_name': requesterName,
      if (departmentId != null) 'department_id': departmentId,
      if (departmentName != null) 'department_name': departmentName,
      'status': status,
      'priority': priority,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      'submitted_at': submittedAt,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (decidedByUserId != null) 'decided_by_user_id': decidedByUserId,
      if (decidedByUserName != null)
        'decided_by_user_name': decidedByUserName,
      if (decisionNotes != null) 'decision_notes': decisionNotes,
      'current_step_index': currentStepIndex,
      if (steps.isNotEmpty)
        'steps': steps.map((s) => s.toJson()).toList(),
      if (auditTrail.isNotEmpty)
        'audit_trail': auditTrail.map((a) => a.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  ApprovalRequest toDomain() {
    return ApprovalRequest(
      id: id,
      requestNumber: requestNumber,
      module: CrmModule.values.firstWhere(
        (m) => m.name.toLowerCase() == module.toLowerCase(),
        orElse: () => CrmModule.purchase,
      ),
      entityType: entityType,
      entityId: entityId,
      entityTitle: entityTitle,
      requesterId: requesterId,
      requesterName: requesterName,
      departmentId: departmentId,
      departmentName: departmentName,
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => ApprovalStatus.pending,
      ),
      priority: ApprovalPriority.values.firstWhere(
        (p) => p.name.toLowerCase() == priority.toLowerCase(),
        orElse: () => ApprovalPriority.normal,
      ),
      amount: amount,
      currencyCode: currencyCode,
      submittedAt: DateTime.tryParse(submittedAt) ?? DateTime.now(),
      decidedAt: decidedAt != null ? DateTime.tryParse(decidedAt!) : null,
      decidedByUserId: decidedByUserId,
      decidedByUserName: decidedByUserName,
      decisionNotes: decisionNotes,
      currentStepIndex: currentStepIndex,
      steps: steps.map((s) => s.toDomain()).toList(),
      auditTrail: auditTrail.map((a) => a.toDomain()).toList(),
      metadata: metadata,
    );
  }

  factory ApprovalRequestDto.fromDomain(ApprovalRequest request) {
    return ApprovalRequestDto(
      id: request.id,
      requestNumber: request.requestNumber,
      module: request.module.name,
      entityType: request.entityType,
      entityId: request.entityId,
      entityTitle: request.entityTitle,
      requesterId: request.requesterId,
      requesterName: request.requesterName,
      departmentId: request.departmentId,
      departmentName: request.departmentName,
      status: request.status.name,
      priority: request.priority.name,
      amount: request.amount,
      currencyCode: request.currencyCode,
      submittedAt: request.submittedAt.toIso8601String(),
      decidedAt: request.decidedAt?.toIso8601String(),
      decidedByUserId: request.decidedByUserId,
      decidedByUserName: request.decidedByUserName,
      decisionNotes: request.decisionNotes,
      currentStepIndex: request.currentStepIndex,
      steps: request.steps.map(ApprovalStepDto.fromDomain).toList(),
      auditTrail:
          request.auditTrail.map(ApprovalActivityDto.fromDomain).toList(),
      metadata: request.metadata,
    );
  }
}
