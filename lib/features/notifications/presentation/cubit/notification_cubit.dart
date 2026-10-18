import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

/// Cubit managing real-time notification stream subscriptions, unread badges, and read/clear actions.
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription<List<CrmNotification>>? _subscription;
  String? _activeUserId;
  int _loadSequence = 0;

  NotificationCubit(this._repository) : super(const NotificationInitial());

  /// Subscribes to the reactive notification stream for the specified [userId].
  void watchNotifications(String userId) {
    if (_activeUserId == userId && _subscription != null) {
      return;
    }

    _subscription?.cancel();
    _activeUserId = userId;

    emit(const NotificationLoading());

    // Retrieve initial snapshot
    _repository.getNotifications(recipientUserId: userId).then((initialList) {
      if (isClosed || _activeUserId != userId) return;
      final currentCategory = state is NotificationLoaded
          ? (state as NotificationLoaded).selectedCategory
          : null;
      final unreadCount = initialList.where((n) => !n.isRead).length;

      emit(
        NotificationLoaded(
          notifications: initialList,
          unreadCount: unreadCount,
          selectedCategory: currentCategory,
          activeUserId: userId,
        ),
      );
    });

    _subscription = _repository.watchNotifications(userId).listen(
      (notifications) {
        if (isClosed) return;

        final currentCategory = state is NotificationLoaded
            ? (state as NotificationLoaded).selectedCategory
            : null;

        final unreadCount = notifications.where((n) => !n.isRead).length;

        emit(
          NotificationLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
            selectedCategory: currentCategory,
            activeUserId: userId,
          ),
        );
      },
      onError: (error) {
        if (isClosed) return;
        emit(NotificationFailure('Failed to stream notifications: $error'));
      },
    );
  }

  /// Manually loads notifications for [userId] with sequence guard.
  Future<void> loadNotifications(
    String userId, {
    NotificationCategory? category,
    bool? unreadOnly,
  }) async {
    _activeUserId = userId;
    final seq = ++_loadSequence;

    emit(const NotificationLoading());

    try {
      final notifications = await _repository.getNotifications(
        recipientUserId: userId,
        category: category,
        unreadOnly: unreadOnly,
      );
      final unreadCount = await _repository.getUnreadCount(userId);

      if (isClosed || seq != _loadSequence) return;

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
          selectedCategory: category,
          activeUserId: userId,
        ),
      );
    } catch (e) {
      if (isClosed || seq != _loadSequence) return;
      emit(NotificationFailure('Failed to load notifications: $e'));
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _repository.markAsRead(notificationId: notificationId, userId: userId);
      // If we don't have an active stream, refresh manually
      if (_subscription == null) {
        await loadNotifications(userId);
      }
    } catch (e) {
      if (!isClosed) {
        emit(NotificationFailure('Failed to mark notification as read: $e'));
      }
    }
  }

  /// Marks all notifications as read for [userId].
  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);
      if (_subscription == null) {
        await loadNotifications(userId);
      }
    } catch (e) {
      if (!isClosed) {
        emit(NotificationFailure('Failed to mark all as read: $e'));
      }
    }
  }

  /// Clears/deletes a notification from user's inbox.
  Future<void> clearNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _repository.clearNotification(
        notificationId: notificationId,
        userId: userId,
      );
      if (_subscription == null) {
        await loadNotifications(userId);
      }
    } catch (e) {
      if (!isClosed) {
        emit(NotificationFailure('Failed to clear notification: $e'));
      }
    }
  }

  /// Sets the active category filter for the notification list.
  void setCategoryFilter(NotificationCategory? category) {
    if (state is NotificationLoaded) {
      final loaded = state as NotificationLoaded;
      emit(loaded.copyWith(selectedCategory: () => category));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
