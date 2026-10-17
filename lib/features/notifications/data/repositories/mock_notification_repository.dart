import 'dart:async';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/inputs/create_notification_input.dart';
import '../../domain/repositories/notification_repository.dart';
import '../mock/mock_notification_store.dart';

/// In-memory mock implementation of [NotificationRepository] backed by [MockNotificationStore].
class MockNotificationRepository implements NotificationRepository {
  final MockNotificationStore _store;

  MockNotificationRepository([MockNotificationStore? store])
      : _store = store ?? MockNotificationStore();

  @override
  Stream<List<CrmNotification>> watchNotifications(String recipientUserId) {
    return _store.watchNotifications(recipientUserId);
  }

  @override
  Future<List<CrmNotification>> getNotifications({
    required String recipientUserId,
    bool? unreadOnly,
    NotificationCategory? category,
  }) async {
    return _store.getNotifications(
      recipientUserId: recipientUserId,
      unreadOnly: unreadOnly,
      category: category,
    );
  }

  @override
  Future<int> getUnreadCount(String recipientUserId) async {
    return _store.getUnreadCount(recipientUserId);
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    _store.markAsRead(notificationId: notificationId, userId: userId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    _store.markAllAsRead(userId);
  }

  @override
  Future<void> clearNotification({
    required String notificationId,
    required String userId,
  }) async {
    _store.clearNotification(notificationId: notificationId, userId: userId);
  }

  @override
  Future<CrmNotification> dispatchNotification(
      CreateNotificationInput input) async {
    return _store.dispatchNotification(input);
  }
}
