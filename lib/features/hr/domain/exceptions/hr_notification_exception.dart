/// Domain exception thrown during notification operations in HR workflows.
///
/// Error codes adhere to standard CRM failure reporting conventions without
/// leaking sensitive payroll or employee payloads in messages.
class HrNotificationException implements Exception {
  static const String unauthorizedRecipient = 'unauthorized_recipient';
  static const String notificationNotFound = 'notification_not_found';
  static const String invalidReadStateTransition = 'invalid_read_state_transition';
  static const String deliveryFailed = 'delivery_failed';

  final String message;
  final String code;

  const HrNotificationException(
    this.message, {
    this.code = 'hr_notification_error',
  });

  @override
  String toString() => 'HrNotificationException[$code]: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrNotificationException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}
