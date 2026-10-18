/// Represents the urgency of an approval request.
enum ApprovalPriority {
  low,
  normal,
  high,
  urgent;

  /// Human-readable label for priority.
  String get displayName => switch (this) {
    ApprovalPriority.low => 'Low',
    ApprovalPriority.normal => 'Normal',
    ApprovalPriority.high => 'High',
    ApprovalPriority.urgent => 'Urgent',
  };
}
