import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  late MockNotificationStore store;
  late MockNotificationRepository repository;
  late NotificationCubit cubit;

  setUp(() {
    store = MockNotificationStore();
    repository = MockNotificationRepository(store);
    cubit = NotificationCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildWidget({Size? size}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size ?? const Size(800, 600)),
        child: NotificationCenterScreen(
          user: MockAuthTestFixtures.admin,
          cubit: cubit,
        ),
      ),
    );
  }

  group('NotificationCenterScreen Tests', () {
    testWidgets('renders app bar, filters, and seeded notification list', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.byKey(const Key('notification_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('notification_filter_unread_only')), findsOneWidget);

      expect(find.text('Action Required: Urgent PO Approval'), findsOneWidget);
      expect(find.text('Payroll Disbursed'), findsOneWidget);
    });

    testWidgets('filtering by category chips narrows notification cards', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final categoryChip = find.byKey(const Key('notification_chip_approvalRequest'));
      await tester.ensureVisible(categoryChip);
      await tester.tap(categoryChip);
      await tester.pumpAndSettle();

      expect(find.text('Action Required: Urgent PO Approval'), findsOneWidget);
      expect(find.text('Payroll Disbursed'), findsNothing);
    });

    testWidgets('toggling unread filter only displays unread cards', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final unreadChip = find.byKey(const Key('notification_filter_unread_only'));
      await tester.tap(unreadChip);
      await tester.pumpAndSettle();

      expect(find.text('Action Required: Urgent PO Approval'), findsOneWidget);
      expect(find.text('Payroll Disbursed'), findsNothing); // was read
    });

    testWidgets('tapping mark read button updates notification state', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final markReadBtn = find.byKey(const Key('notification_mark_read_notif-101'));
      expect(markReadBtn, findsOneWidget);

      await tester.tap(markReadBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state illustration when list is empty', (
      tester,
    ) async {
      cubit.watchNotifications('usr_disabled'); // user with 0 notifications
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('No notifications found'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow across 4 standard viewports', (
      tester,
    ) async {
      const viewports = [
        Size(320, 568),
        Size(360, 640),
        Size(768, 1024),
        Size(1200, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        cubit.watchNotifications('usr_admin');
        await tester.pumpWidget(buildWidget(size: size));
        await tester.pumpAndSettle();

        expect(find.text('Notification Center'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
