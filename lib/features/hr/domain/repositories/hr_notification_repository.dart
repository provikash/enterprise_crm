import '../entities/hr_notification.dart';

/// Repository interface governing retrieval, persistence, and state transitions of HR notifications.
///
/// Follows HR-9.7 invariants:
/// - Recipient Authorization: all query and mutation operations require explicit recipient user ID scoping.
/// - Defensive Isolation: callers cannot read or modify notifications belonging to another user.
/// - Deterministic Ordering: queries return notifications ordered chronologically (newest first).
abstract class HrNotificationRepository {
  /// Stores and sends a new notification to its recipient.
  Future<HrNotification> sendNotification(HrNotification notification);

  /// Retrieves all notifications for [userId], ordered newest first.
  Future<List<HrNotification>> getNotificationsForUser(String userId);

  /// Retrieves all unread notifications for [userId], ordered newest first.
  Future<List<HrNotification>> getUnreadNotificationsForUser(String userId);

  /// Retrieves the count of unread notifications for [userId].
  Future<int> getUnreadCount(String userId);

  /// Retrieves a specific notification by [notificationId], ensuring it belongs to [recipientUserId].
  Future<HrNotification?> getNotificationById(
    String notificationId, {
    required String recipientUserId,
  });

  /// Marks a specific notification as read, ensuring it belongs to [recipientUserId].
  Future<HrNotification> markAsRead(
    String notificationId, {
    required String recipientUserId,
  });

  /// Marks all unread notifications for [recipientUserId] as read.
  Future<void> markAllAsRead({required String recipientUserId});

  /// Clears notifications for [recipientUserId] for session isolation on logout.
  Future<void> clearUserNotifications({required String recipientUserId});
}
