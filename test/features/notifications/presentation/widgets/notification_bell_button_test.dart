import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:enterprise_crm/features/notifications/presentation/widgets/notification_dropdown_popover.dart';
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

  Widget buildWidget({Size size = const Size(800, 600)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          appBar: AppBar(
            actions: [
              NotificationBellButton(
                user: MockAuthTestFixtures.admin,
                cubit: cubit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('NotificationBellButton Widget Tests', () {
    testWidgets('renders bell icon and unread count badge when loaded', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_bell_button')), findsOneWidget);
      // usr_admin has 2 unread notifications seeded
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tapping bell button opens popover dialog on wide screen', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget(size: const Size(1024, 768)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_bell_button')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDropdownPopover), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('tapping bell button opens bottom sheet on compact screen', (
      tester,
    ) async {
      cubit.watchNotifications('usr_admin');
      await tester.pumpWidget(buildWidget(size: const Size(360, 640)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_bell_button')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationDropdownPopover), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });
  });
}
