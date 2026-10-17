/// Functional categories of system notifications.
enum NotificationCategory {
  approvalRequest,
  approvalDecision,
  systemAlert,
  announcement,
  reminder;

  /// Human-readable display label.
  String get displayName => switch (this) {
    NotificationCategory.approvalRequest => 'Approval Request',
    NotificationCategory.approvalDecision => 'Approval Decision',
    NotificationCategory.systemAlert => 'System Alert',
    NotificationCategory.announcement => 'Announcement',
    NotificationCategory.reminder => 'Reminder',
  };
}
