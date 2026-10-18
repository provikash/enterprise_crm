import 'package:flutter/foundation.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../entities/approval_priority.dart';
import '../entities/approval_step.dart';

/// Data payload required to submit a new approval request.
@immutable
class CreateApprovalRequestInput {
  final CrmModule module;
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String requesterId;
  final String requesterName;
  final String? departmentId;
  final String? departmentName;
  final ApprovalPriority priority;
  final double? amount;
  final String? currencyCode;
  final List<ApprovalStep> steps;
  final Map<String, dynamic> metadata;

  const CreateApprovalRequestInput({
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.requesterId,
    required this.requesterName,
    this.departmentId,
    this.departmentName,
    this.priority = ApprovalPriority.normal,
    this.amount,
    this.currencyCode,
    this.steps = const [],
    this.metadata = const {},
  });
}
