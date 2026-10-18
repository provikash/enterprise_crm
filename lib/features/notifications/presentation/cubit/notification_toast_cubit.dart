import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_priority.dart';
import 'notification_toast_state.dart';

/// Cubit managing transient high-priority toast banners triggered by incoming real-time notifications.
class NotificationToastCubit extends Cubit<NotificationToastState> {
  NotificationToastCubit() : super(const NotificationToastInitial());

  /// Triggers a toast banner if notification priority is high or critical.
  void handleIncomingNotification(CrmNotification notification) {
    if (notification.priority == NotificationPriority.critical ||
        notification.priority == NotificationPriority.warning) {
      showToast(notification);
    }
  }

  /// Explicitly displays a toast notification.
  void showToast(CrmNotification notification) {
    emit(NotificationToastShow(notification));
  }

  /// Dismisses any active toast notification banner.
  void dismissToast() {
    emit(const NotificationToastInitial());
  }
}
