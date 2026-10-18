/// Actions recorded in the append-only approval audit trail.
enum ApprovalActionType {
  submitted,
  approved,
  rejected,
  revisionRequested,
  reassigned,
  cancelled,
  commentAdded;

  /// Human-readable label for the action.
  String get label => switch (this) {
    ApprovalActionType.submitted => 'Submitted',
    ApprovalActionType.approved => 'Approved',
    ApprovalActionType.rejected => 'Rejected',
    ApprovalActionType.revisionRequested => 'Revision Requested',
    ApprovalActionType.reassigned => 'Reassigned',
    ApprovalActionType.cancelled => 'Cancelled',
    ApprovalActionType.commentAdded => 'Comment Added',
  };

  /// Alias for label adhering to standard presentation conventions.
  String get displayName => label;
}
