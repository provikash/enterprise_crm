import 'package:flutter/foundation.dart';

@immutable
class ApprovalTimelineEntry {
  final String label;
  final String actorName;
  final DateTime? occurredAt;
  final String? comment;
  final bool isCurrent;

  const ApprovalTimelineEntry({
    required this.label,
    required this.actorName,
    this.occurredAt,
    this.comment,
    this.isCurrent = false,
  });
}

@immutable
class AuditChange {
  final String fieldLabel;
  final String? before;
  final String? after;
  final bool sensitive;

  const AuditChange({
    required this.fieldLabel,
    this.before,
    this.after,
    this.sensitive = false,
  });
}

@immutable
class AuditTimelineEntry {
  final String action;
  final String actorName;
  final DateTime occurredAt;
  final List<AuditChange> changes;
  final String? reason;

  const AuditTimelineEntry({
    required this.action,
    required this.actorName,
    required this.occurredAt,
    this.changes = const [],
    this.reason,
  });
}
