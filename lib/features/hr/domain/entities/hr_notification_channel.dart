/// Delivery channels supported by the Enterprise CRM notification architecture.
///
/// In accordance with HR-9.1 and HR-9.7 rules:
/// - In-app notification delivery is the confirmed and implemented client channel.
/// - Push notification providers (FCM, OneSignal) and email infrastructure (SMTP)
///   are external backend dependencies and are explicitly not implemented client-side.
enum HrNotificationChannel {
  inApp('In-App Notification');

  final String displayName;

  const HrNotificationChannel(this.displayName);

  @override
  String toString() => displayName;
}
