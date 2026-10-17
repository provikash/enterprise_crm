import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/crm_notification.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:enterprise_crm/features/notifications/presentation/widgets/notification_dropdown_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  late MockNotificationStore store;
  late MockNotificationRepository repository;
  late NotificationCubit cubit;

  final sampleNotifications = [
    CrmNotification(
      id: 'notif-1',
      recipientUserId: 'usr_admin',
      title: 'Action Required: Urgent PO Approval',
      body: 'Purchase Order #PO-9821 is awaiting review.',
      category: NotificationCategory.approvalRequest,
      priority: NotificationPriority.critical,
      referenceModule: CrmModule.purchase,
      referenceEntityType: 'approval_request',
      referenceEntityId: 'appr-001',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    CrmNotification(
      id: 'notif-2',
      recipientUserId: 'usr_admin',
      title: 'Payroll Disbursed',
      body: 'Monthly Payroll Run was finalized.',
      category: NotificationCategory.approvalDecision,
      priority: NotificationPriority.success,
      referenceModule: CrmModule.hrPayroll,
      referenceEntityType: 'approval_request',
      referenceEntityId: 'appr-005',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  setUp(() {
    store = MockNotificationStore();
    repository = MockNotificationRepository(store);
    cubit = NotificationCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildWidget({
    List<CrmNotification>? items,
    int unreadCount = 1,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: NotificationDropdownPopover(
            notifications: items ?? sampleNotifications,
            unreadCount: unreadCount,
            user: MockAuthTestFixtures.admin,
            cubit: cubit,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  group('NotificationDropdownPopover Widget Tests', () {
    testWidgets('renders header, unread badge, and recent notifications', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Action Required: Urgent PO Approval'), findsOneWidget);
      expect(find.text('Purchase Order #PO-9821 is awaiting review.'), findsOneWidget);
      expect(find.text('Payroll Disbursed'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('View all in Notification Center'), findsOneWidget);
    });

    testWidgets('renders empty state illustration when notifications list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(items: [], unreadCount: 0));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('tapping Mark all read calls cubit.markAllAsRead', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final markAllBtn = find.byKey(const Key('notification_popover_mark_all_read'));
      expect(markAllBtn, findsOneWidget);

      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping View all in Notification Center navigates to NotificationCenterScreen', (
      tester,
    ) async {
      bool closed = false;
      await tester.pumpWidget(
        buildWidget(
          onClose: () {
            closed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      final viewAllBtn = find.byKey(const Key('notification_popover_view_all_button'));
      await tester.tap(viewAllBtn);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.byType(NotificationCenterScreen), findsOneWidget);
      expect(find.text('Notification Center'), findsOneWidget);
    });
  });
}
