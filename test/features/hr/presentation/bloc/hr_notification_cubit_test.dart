import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_hr_notification_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_notification_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_notification_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/hr_notification_state.dart';

void main() {
  group('HrNotificationCubit Tests (HR-9.7)', () {
    late MockHrNotificationStore store;
    late MockHrNotificationRepository repository;
    late HrNotificationCubit cubit;

    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
      permissions: {},
    );

    const hrUser = CurrentUser(
      id: 'usr_hr',
      displayName: 'HR Specialist',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
      permissions: {},
    );

    setUp(() {
      store = MockHrNotificationStore(seedInitialData: true);
      repository = MockHrNotificationRepository(store: store);
      cubit = HrNotificationCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is HrNotificationInitial', () {
      expect(cubit.state, equals(const HrNotificationInitial()));
    });

    test('loadNotifications emits [Loading, Loaded] with user notifications', () async {
      final expectedStates = [
        const HrNotificationLoading(),
        isA<HrNotificationLoaded>()
            .having((s) => s.notifications.length, 'length', equals(2))
            .having((s) => s.unreadCount, 'unreadCount', equals(2)),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadNotifications(user: adminUser);
    });

    test('markAsRead updates read state and refreshes notification list', () async {
      await cubit.loadNotifications(user: adminUser);

      await cubit.markAsRead(notificationId: 'notif_001', user: adminUser);

      expect(cubit.state, isA<HrNotificationLoaded>());
      final loaded = cubit.state as HrNotificationLoaded;
      expect(loaded.unreadCount, equals(1));
      final notif001 = loaded.notifications.firstWhere((n) => n.id == 'notif_001');
      expect(notif001.isRead, isTrue);
    });

    test('markAllAsRead marks all user notifications as read', () async {
      await cubit.loadNotifications(user: adminUser);

      await cubit.markAllAsRead(user: adminUser);

      expect(cubit.state, isA<HrNotificationLoaded>());
      final loaded = cubit.state as HrNotificationLoaded;
      expect(loaded.unreadCount, equals(0));
    });

    test('repository failure emits HrNotificationError', () async {
      store.simulateFailure = true;

      final expectedStates = [
        const HrNotificationLoading(),
        isA<HrNotificationError>().having((s) => s.code, 'code', equals('delivery_failed')),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadNotifications(user: adminUser);
    });

    test('clear resets cubit to HrNotificationInitial for session isolation', () async {
      await cubit.loadNotifications(user: adminUser);
      expect(cubit.state, isA<HrNotificationLoaded>());

      cubit.clear();
      expect(cubit.state, equals(const HrNotificationInitial()));
    });

    test('loadNotifications for hrUser loads only hrUser notifications', () async {
      await cubit.loadNotifications(user: hrUser);

      expect(cubit.state, isA<HrNotificationLoaded>());
      final loaded = cubit.state as HrNotificationLoaded;
      expect(loaded.notifications.length, equals(1));
      expect(loaded.notifications.first.recipientUserId, equals('usr_hr'));
      expect(loaded.unreadCount, equals(0)); // notif_002 is read
    });
  });
}
