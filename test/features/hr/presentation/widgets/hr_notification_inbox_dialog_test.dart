import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_notification_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_notification_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_approval_request_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/hr_notification_inbox_dialog.dart';

void main() {
  group('HrNotificationInboxDialog Tests (HR-9.7)', () {
    late MockHrNotificationStore notificationStore;
    late MockHrNotificationRepository notificationRepository;
    late MockHrApprovalRepository approvalRepository;

    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
      permissions: {},
    );

    const emptyUser = CurrentUser(
      id: 'usr_empty',
      displayName: 'Empty User',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {},
    );

    setUp(() {
      notificationStore = MockHrNotificationStore(seedInitialData: true);
      notificationRepository = MockHrNotificationRepository(store: notificationStore);
      approvalRepository = MockHrApprovalRepository();
    });

    testWidgets('renders dialog with user notifications and unread badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrNotificationInboxDialog(
              user: adminUser,
              notificationRepository: notificationRepository,
              approvalRepository: approvalRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 unread
      expect(find.text('New Approval Request'), findsOneWidget);
      expect(find.text('Approval Request Cancelled'), findsOneWidget);
      expect(find.byKey(const Key('hr_notifications_mark_all_read_button')), findsOneWidget);
    });

    testWidgets('tapping Mark all read marks all notifications as read', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrNotificationInboxDialog(
              user: adminUser,
              notificationRepository: notificationRepository,
              approvalRepository: approvalRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final markAllBtn = find.byKey(const Key('hr_notifications_mark_all_read_button'));
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      final unreadCount = await notificationRepository.getUnreadCount(adminUser.id);
      expect(unreadCount, equals(0));
    });

    testWidgets('renders empty state when user has no notifications', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HrNotificationInboxDialog(
              user: emptyUser,
              notificationRepository: notificationRepository,
              approvalRepository: approvalRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('tapping notification navigates to HrApprovalRequestDetailsScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HrNotificationInboxDialog.show(
                  context: context,
                  user: adminUser,
                  notificationRepository: notificationRepository,
                  approvalRepository: approvalRepository,
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final notifItem = find.byKey(const Key('hr_notification_item_notif_001'));
      expect(notifItem, findsOneWidget);

      await tester.tap(notifItem);
      await tester.pumpAndSettle();

      expect(find.byType(HrApprovalRequestDetailsScreen), findsOneWidget);
    });
  });
}
