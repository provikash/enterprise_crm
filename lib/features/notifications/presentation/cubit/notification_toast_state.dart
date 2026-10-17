import 'package:flutter/foundation.dart';
import '../../domain/entities/crm_notification.dart';

/// Sealed hierarchy of states for transient toast notification banners.
sealed class NotificationToastState {
  const NotificationToastState();
}

/// Idle state when no toast is displayed.
final class NotificationToastInitial extends NotificationToastState {
  const NotificationToastInitial();
}

/// State triggering a transient notification toast banner.
@immutable
final class NotificationToastShow extends NotificationToastState {
  final CrmNotification notification;

  const NotificationToastShow(this.notification);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationToastShow && other.notification == notification;

  @override
  int get hashCode => notification.hashCode;
}
