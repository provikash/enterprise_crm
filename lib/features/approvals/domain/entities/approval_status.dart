/// Represents the overall lifecycle status of an approval request.
enum ApprovalStatus {
  pending,
  approved,
  rejected,
  revisionRequested,
  cancelled;

  /// Returns true if this request has reached a terminal decision.
  bool get isTerminal =>
      this == ApprovalStatus.approved ||
      this == ApprovalStatus.rejected ||
      this == ApprovalStatus.cancelled;

  /// Returns true if this request can still be acted upon by an approver or requester.
  bool get isActionable =>
      this == ApprovalStatus.pending ||
      this == ApprovalStatus.revisionRequested;

  /// Human-readable label for the status.
  String get label => switch (this) {
    ApprovalStatus.pending => 'Pending',
    ApprovalStatus.approved => 'Approved',
    ApprovalStatus.rejected => 'Rejected',
    ApprovalStatus.revisionRequested => 'Revision Requested',
    ApprovalStatus.cancelled => 'Cancelled',
  };

  /// Alias for label adhering to standard presentation conventions.
  String get displayName => label;
}
