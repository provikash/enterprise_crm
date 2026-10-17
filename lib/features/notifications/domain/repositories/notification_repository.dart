import '../entities/crm_notification.dart';
import '../entities/notification_category.dart';
import '../inputs/create_notification_input.dart';

/// Abstract contract governing in-app notifications and real-time streams.
abstract interface class NotificationRepository {
  /// Watches the reactive notification stream for the specified recipient user.
  Stream<List<CrmNotification>> watchNotifications(String recipientUserId);

  /// Fetches a list of notifications for the specified recipient user.
  Future<List<CrmNotification>> getNotifications({
    required String recipientUserId,
    bool? unreadOnly,
    NotificationCategory? category,
  });

  /// Computes the number of unread notifications for a user.
  Future<int> getUnreadCount(String recipientUserId);

  /// Marks a single notification as read.
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  });

  /// Marks all notifications as read for a specific user.
  Future<void> markAllAsRead(String userId);

  /// Clears/deletes a specific notification from a user's inbox.
  Future<void> clearNotification({
    required String notificationId,
    required String userId,
  });

  /// Dispatches a new notification to a recipient user.
  Future<CrmNotification> dispatchNotification(CreateNotificationInput input);
}
