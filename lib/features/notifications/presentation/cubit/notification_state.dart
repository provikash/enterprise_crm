import 'package:flutter/foundation.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';

/// Sealed hierarchy of states for the Notification center and bell badge.
sealed class NotificationState {
  const NotificationState();
}

/// Initial uninitialized state.
final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading state indicating notifications are being retrieved.
final class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Loaded state with active notifications, unread count, and optional category filter.
@immutable
final class NotificationLoaded extends NotificationState {
  final List<CrmNotification> notifications;
  final int unreadCount;
  final NotificationCategory? selectedCategory;
  final String? activeUserId;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.selectedCategory,
    this.activeUserId,
  });

  /// Returns notifications filtered by [selectedCategory] if set.
  List<CrmNotification> get filteredNotifications {
    if (selectedCategory == null) return notifications;
    return notifications.where((n) => n.category == selectedCategory).toList();
  }

  /// Copies this state with optional parameters replaced.
  NotificationLoaded copyWith({
    List<CrmNotification>? notifications,
    int? unreadCount,
    NotificationCategory? Function()? selectedCategory,
    String? activeUserId,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      activeUserId: activeUserId ?? this.activeUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationLoaded &&
        listEquals(other.notifications, notifications) &&
        other.unreadCount == unreadCount &&
        other.selectedCategory == selectedCategory &&
        other.activeUserId == activeUserId;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(notifications),
        unreadCount,
        selectedCategory,
        activeUserId,
      );
}

/// Failure state representing an error fetching or mutating notifications.
final class NotificationFailure extends NotificationState {
  final String message;

  const NotificationFailure(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
