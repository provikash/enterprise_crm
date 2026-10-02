import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_notification.dart';
import '../../domain/entities/hr_notification_channel.dart';
import '../../domain/entities/hr_notification_type.dart';
import '../../domain/exceptions/hr_notification_exception.dart';

/// In-memory thread-safe mock store for HR notifications.
///
/// Follows HR-9.7 invariants:
/// - Deterministic initial seed data across stable users (`usr_admin`, `usr_hr`).
/// - Strict defensive copy isolation so returned entities cannot mutate internal state.
/// - Recipient Authorization: operations check that notifications belong to caller.
/// - Chronological ordering: queries return notifications newest first.
/// - Controlled error injection via [simulateFailure].
class MockHrNotificationStore {
  final Map<String, HrNotification> _notifications = {};
  bool simulateFailure = false;
  int _idCounter = 100;

  MockHrNotificationStore({bool seedInitialData = true}) {
    if (seedInitialData) {
      _seed();
    }
  }

  void _seed() {
    final seeds = [
      HrNotification(
        id: 'notif_001',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestSubmitted,
        channel: HrNotificationChannel.inApp,
        title: 'New Approval Request',
        body: 'A new request for Attendance Record att_101 has been submitted by usr_hr.',
        target: HrApprovalTarget.attendanceRecord('att_101'),
        requestId: 'appr_req_1',
        createdAt: DateTime.utc(2026, 2, 5, 9, 30),
        isRead: false,
      ),
      HrNotification(
        id: 'notif_002',
        recipientUserId: 'usr_hr',
        type: HrNotificationType.approvalDecisionRecorded,
        channel: HrNotificationChannel.inApp,
        title: 'Approval Decision Recorded',
        body: 'Your request for Payroll Period period_2026_01 was approved.',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        requestId: 'appr_req_3',
        createdAt: DateTime.utc(2026, 2, 4, 14, 15),
        isRead: true,
        readAt: DateTime.utc(2026, 2, 4, 14, 30),
      ),
      HrNotification(
        id: 'notif_003',
        recipientUserId: 'usr_admin',
        type: HrNotificationType.approvalRequestCancelled,
        channel: HrNotificationChannel.inApp,
        title: 'Approval Request Cancelled',
        body: 'Request appr_req_2 for Employee Document doc_1 was cancelled by requester.',
        target: HrApprovalTarget.employeeDocument('doc_1'),
        requestId: 'appr_req_2',
        createdAt: DateTime.utc(2026, 2, 5, 11, 0),
        isRead: false,
      ),
    ];

    for (final seed in seeds) {
      _notifications[seed.id] = seed;
    }
  }

  void _checkFailure() {
    if (simulateFailure) {
      throw const HrNotificationException(
        'Simulated notification repository failure.',
        code: HrNotificationException.deliveryFailed,
      );
    }
  }

  String generateId() {
    _idCounter++;
    return 'notif_$_idCounter';
  }

  HrNotification sendNotification(HrNotification notification) {
    _checkFailure();
    _notifications[notification.id] = notification;
    return notification.copyWith();
  }

  List<HrNotification> getNotificationsForUser(String userId) {
    _checkFailure();
    final userNotifs = _notifications.values
        .where((n) => n.recipientUserId == userId)
        .map((n) => n.copyWith())
        .toList();

    userNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userNotifs;
  }

  List<HrNotification> getUnreadNotificationsForUser(String userId) {
    _checkFailure();
    final unread = _notifications.values
        .where((n) => n.recipientUserId == userId && !n.isRead)
        .map((n) => n.copyWith())
        .toList();

    unread.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return unread;
  }

  int getUnreadCount(String userId) {
    _checkFailure();
    return _notifications.values
        .where((n) => n.recipientUserId == userId && !n.isRead)
        .length;
  }

  HrNotification? getNotificationById(String notificationId, {required String recipientUserId}) {
    _checkFailure();
    final notif = _notifications[notificationId];
    if (notif == null) return null;

    if (notif.recipientUserId != recipientUserId) {
      throw const HrNotificationException(
        'Unauthorized: notification belongs to another user.',
        code: HrNotificationException.unauthorizedRecipient,
      );
    }

    return notif.copyWith();
  }

  HrNotification markAsRead(String notificationId, {required String recipientUserId}) {
    _checkFailure();
    final notif = _notifications[notificationId];
    if (notif == null) {
      throw HrNotificationException(
        'Notification "$notificationId" not found.',
        code: HrNotificationException.notificationNotFound,
      );
    }

    if (notif.recipientUserId != recipientUserId) {
      throw const HrNotificationException(
        'Unauthorized: cannot mark notification for another user as read.',
        code: HrNotificationException.unauthorizedRecipient,
      );
    }

    final updated = notif.markAsRead();
    _notifications[notificationId] = updated;
    return updated.copyWith();
  }

  void markAllAsRead({required String recipientUserId}) {
    _checkFailure();
    final now = DateTime.now().toUtc();
    for (final entry in _notifications.entries) {
      if (entry.value.recipientUserId == recipientUserId && !entry.value.isRead) {
        _notifications[entry.key] = entry.value.markAsRead(timestamp: now);
      }
    }
  }

  void clearUserNotifications({required String recipientUserId}) {
    _notifications.removeWhere((_, n) => n.recipientUserId == recipientUserId);
  }

  void reset() {
    _notifications.clear();
    simulateFailure = false;
    _idCounter = 100;
    _seed();
  }
}
