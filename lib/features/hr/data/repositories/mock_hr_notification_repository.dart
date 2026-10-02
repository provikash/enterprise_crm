import '../../domain/entities/hr_notification.dart';
import '../../domain/repositories/hr_notification_repository.dart';
import '../mock/mock_hr_notification_store.dart';

/// Mock implementation of [HrNotificationRepository] backed by [MockHrNotificationStore].
///
/// Provides deterministic in-memory storage for notification workflows in HR checkpoints.
class MockHrNotificationRepository implements HrNotificationRepository {
  final MockHrNotificationStore _store;

  MockHrNotificationRepository({MockHrNotificationStore? store})
      : _store = store ?? MockHrNotificationStore();

  MockHrNotificationStore get store => _store;

  @override
  Future<HrNotification> sendNotification(HrNotification notification) async {
    return _store.sendNotification(notification);
  }

  @override
  Future<List<HrNotification>> getNotificationsForUser(String userId) async {
    return _store.getNotificationsForUser(userId);
  }

  @override
  Future<List<HrNotification>> getUnreadNotificationsForUser(String userId) async {
    return _store.getUnreadNotificationsForUser(userId);
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return _store.getUnreadCount(userId);
  }

  @override
  Future<HrNotification?> getNotificationById(
    String notificationId, {
    required String recipientUserId,
  }) async {
    return _store.getNotificationById(notificationId, recipientUserId: recipientUserId);
  }

  @override
  Future<HrNotification> markAsRead(
    String notificationId, {
    required String recipientUserId,
  }) async {
    return _store.markAsRead(notificationId, recipientUserId: recipientUserId);
  }

  @override
  Future<void> markAllAsRead({required String recipientUserId}) async {
    _store.markAllAsRead(recipientUserId: recipientUserId);
  }

  @override
  Future<void> clearUserNotifications({required String recipientUserId}) async {
    _store.clearUserNotifications(recipientUserId: recipientUserId);
  }
}
