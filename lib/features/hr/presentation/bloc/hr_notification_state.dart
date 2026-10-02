import '../../domain/entities/hr_notification.dart';

/// States for [HrNotificationCubit].
sealed class HrNotificationState {
  const HrNotificationState();
}

/// Initial uninitialized state.
final class HrNotificationInitial extends HrNotificationState {
  const HrNotificationInitial();
}

/// Loading notifications for active user.
final class HrNotificationLoading extends HrNotificationState {
  const HrNotificationLoading();
}

/// Successfully loaded notifications for active user.
final class HrNotificationLoaded extends HrNotificationState {
  final List<HrNotification> notifications;
  final int unreadCount;

  const HrNotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrNotificationLoaded &&
          runtimeType == other.runtimeType &&
          unreadCount == other.unreadCount &&
          notifications.length == other.notifications.length;

  @override
  int get hashCode => Object.hash(unreadCount, notifications.length);
}

/// Error state encountered while performing notification operations.
final class HrNotificationError extends HrNotificationState {
  final String message;
  final String code;

  const HrNotificationError({
    required this.message,
    required this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrNotificationError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(message, code);
}
