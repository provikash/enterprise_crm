/// Individual step status within a multi-tier approval workflow.
enum ApprovalStepStatus {
  pending,
  approved,
  rejected,
  skipped;

  /// Human-readable label for step status.
  String get label => switch (this) {
    ApprovalStepStatus.pending => 'Pending',
    ApprovalStepStatus.approved => 'Approved',
    ApprovalStepStatus.rejected => 'Rejected',
    ApprovalStepStatus.skipped => 'Skipped',
  };

  /// Alias for label adhering to standard presentation conventions.
  String get displayName => label;
}
