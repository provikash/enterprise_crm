/// Semantic urgency level for notifications.
enum NotificationPriority {
  info,
  success,
  warning,
  critical;

  /// Human-readable label.
  String get label => switch (this) {
    NotificationPriority.info => 'Info',
    NotificationPriority.success => 'Success',
    NotificationPriority.warning => 'Warning',
    NotificationPriority.critical => 'Critical',
  };
}
