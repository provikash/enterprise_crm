import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_toast_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_toast_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NotificationToastCubit triggers toast on critical or warning notifications',
      () {
    final cubit = NotificationToastCubit();
    expect(cubit.state, isA<NotificationToastInitial>());

    final criticalNotification = CrmNotification(
      id: 'notif-urgent-1',
      recipientUserId: 'usr-admin',
      title: 'Urgent Approval Needed',
      body: 'Purchase order pending sign-off',
      category: NotificationCategory.approvalRequest,
      priority: NotificationPriority.critical,
      isRead: false,
      createdAt: DateTime.now(),
    );

    cubit.handleIncomingNotification(criticalNotification);
    expect(cubit.state, isA<NotificationToastShow>());

    cubit.dismissToast();
    expect(cubit.state, isA<NotificationToastInitial>());

    // Normal info priority should not trigger toast banner
    final infoNotification = CrmNotification(
      id: 'notif-info-1',
      recipientUserId: 'usr-admin',
      title: 'Routine Update',
      body: 'Daily statistics synchronized',
      category: NotificationCategory.systemAlert,
      priority: NotificationPriority.info,
      isRead: false,
      createdAt: DateTime.now(),
    );

    cubit.handleIncomingNotification(infoNotification);
    expect(cubit.state, isA<NotificationToastInitial>());

    cubit.close();
  });
}
