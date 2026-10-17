import 'package:enterprise_crm/features/notifications/data/mock/mock_notification_store.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/inputs/create_notification_input.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:enterprise_crm/features/notifications/presentation/cubit/notification_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockNotificationStore store;
  late MockNotificationRepository repo;

  setUp(() {
    store = MockNotificationStore();
    repo = MockNotificationRepository(store);
  });

  test('NotificationCubit initial state is NotificationInitial', () {
    final cubit = NotificationCubit(repo);
    expect(cubit.state, isA<NotificationInitial>());
    cubit.close();
  });

  test('loadNotifications emits Loading then Loaded with seeded notifications',
      () async {
    final cubit = NotificationCubit(repo);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<NotificationLoading>(),
        isA<NotificationLoaded>().having(
          (s) => s.notifications.isNotEmpty,
          'has notifications',
          isTrue,
        ),
      ]),
    );

    await cubit.loadNotifications('usr_admin');
    await expectation;
    await cubit.close();
  });

  test('watchNotifications receives real-time stream updates when notification is dispatched',
      () async {
    final cubit = NotificationCubit(repo);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<NotificationLoading>(),
        isA<NotificationLoaded>(),
        isA<NotificationLoaded>().having(
          (s) => s.notifications.any((n) => n.title == 'Live Alert'),
          'contains Live Alert',
          isTrue,
        ),
      ]),
    );

    cubit.watchNotifications('usr_admin');
    await pumpEventQueue();

    await repo.dispatchNotification(
      const CreateNotificationInput(
        recipientUserId: 'usr_admin',
        title: 'Live Alert',
        body: 'Real-time test message',
      ),
    );

    await expectation;
    await cubit.close();
  });

  test('markAsRead updates unread count and read status', () async {
    final cubit = NotificationCubit(repo);
    await cubit.loadNotifications('usr_admin');

    final loadedState = cubit.state as NotificationLoaded;
    final unreadItem = loadedState.notifications.firstWhere((n) => !n.isRead);
    final initialUnreadCount = loadedState.unreadCount;

    await cubit.markAsRead(
      notificationId: unreadItem.id,
      userId: 'usr_admin',
    );

    final updatedState = cubit.state as NotificationLoaded;
    expect(updatedState.unreadCount, equals(initialUnreadCount - 1));

    final updatedItem =
        updatedState.notifications.firstWhere((n) => n.id == unreadItem.id);
    expect(updatedItem.isRead, isTrue);

    await cubit.close();
  });

  test('markAllAsRead marks all notifications as read and sets unreadCount to 0',
      () async {
    final cubit = NotificationCubit(repo);
    await cubit.loadNotifications('usr_admin');

    await cubit.markAllAsRead('usr_admin');

    final state = cubit.state as NotificationLoaded;
    expect(state.unreadCount, equals(0));
    expect(state.notifications.every((n) => n.isRead), isTrue);

    await cubit.close();
  });

  test('clearNotification removes notification from state', () async {
    final cubit = NotificationCubit(repo);
    await cubit.loadNotifications('usr_admin');

    final loadedState = cubit.state as NotificationLoaded;
    final itemToRemove = loadedState.notifications.first;

    await cubit.clearNotification(
      notificationId: itemToRemove.id,
      userId: 'usr_admin',
    );

    final updatedState = cubit.state as NotificationLoaded;
    expect(
      updatedState.notifications.any((n) => n.id == itemToRemove.id),
      isFalse,
    );

    await cubit.close();
  });

  test('setCategoryFilter restricts filteredNotifications without modifying full list',
      () async {
    final cubit = NotificationCubit(repo);
    await cubit.loadNotifications('usr_admin');

    cubit.setCategoryFilter(NotificationCategory.approvalRequest);

    final state = cubit.state as NotificationLoaded;
    expect(state.selectedCategory, NotificationCategory.approvalRequest);
    expect(
      state.filteredNotifications
          .every((n) => n.category == NotificationCategory.approvalRequest),
      isTrue,
    );

    // Reset filter
    cubit.setCategoryFilter(null);
    final resetState = cubit.state as NotificationLoaded;
    expect(resetState.selectedCategory, isNull);
    expect(resetState.filteredNotifications.length, equals(resetState.notifications.length));

    await cubit.close();
  });

  test('User isolation: User A notifications do not leak to User B', () async {
    final cubitA = NotificationCubit(repo);
    final cubitB = NotificationCubit(repo);

    await cubitA.loadNotifications('usr_admin');
    await cubitB.loadNotifications('usr_standard');

    final stateA = cubitA.state as NotificationLoaded;
    final stateB = cubitB.state as NotificationLoaded;

    expect(stateA.notifications.every((n) => n.recipientUserId == 'usr_admin'), isTrue);
    expect(stateB.notifications.every((n) => n.recipientUserId == 'usr_standard'), isTrue);

    await cubitA.close();
    await cubitB.close();
  });
}
