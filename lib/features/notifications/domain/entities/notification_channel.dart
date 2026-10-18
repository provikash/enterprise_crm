/// In-app delivery channel for notifications.
enum NotificationChannel {
  inApp;

  String get displayName => switch (this) {
    NotificationChannel.inApp => 'In-App',
  };
}
