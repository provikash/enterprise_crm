/// Filter tabs for the Approval Inbox.
enum ApprovalInboxTab {
  pending,
  approved,
  rejected,
  mySubmissions;

  /// Human-readable tab label.
  String get label => switch (this) {
        ApprovalInboxTab.pending => 'Pending Review',
        ApprovalInboxTab.approved => 'Approved',
        ApprovalInboxTab.rejected => 'Rejected',
        ApprovalInboxTab.mySubmissions => 'My Submissions',
      };
}
