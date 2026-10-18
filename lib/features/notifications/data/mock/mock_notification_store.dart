import 'dart:async';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/entities/notification_priority.dart';
import '../../domain/inputs/create_notification_input.dart';

/// Thread-safe in-memory store for user notifications with reactive stream broadcasting.
class MockNotificationStore {
  final List<CrmNotification> _notifications = [];
  final StreamController<List<CrmNotification>> _streamController =
      StreamController<List<CrmNotification>>.broadcast();
  int _counter = 300;

  MockNotificationStore() {
    reset();
  }

  /// Resets store state to deterministic initial seed data.
  void reset() {
    _notifications.clear();
    _counter = 300;

    final now = DateTime.utc(2026, 10, 15, 14, 0);

    _notifications.addAll([
      CrmNotification(
        id: 'notif-101',
        recipientUserId: 'usr_admin',
        title: 'Action Required: Urgent PO Approval',
        body: 'Purchase Order #PO-9821 (\$14,500.00) is awaiting Finance Director Sign-off.',
        category: NotificationCategory.approvalRequest,
        priority: NotificationPriority.critical,
        referenceModule: CrmModule.purchase,
        referenceEntityType: 'approval_request',
        referenceEntityId: 'appr-001',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      CrmNotification(
        id: 'notif-102',
        recipientUserId: 'usr_admin',
        title: 'Payroll Disbursed',
        body: 'September 2026 Monthly Payroll Run Finalization was approved and cleared.',
        category: NotificationCategory.approvalDecision,
        priority: NotificationPriority.success,
        referenceModule: CrmModule.hrPayroll,
        referenceEntityType: 'approval_request',
        referenceEntityId: 'appr-005',
        isRead: true,
        readAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CrmNotification(
        id: 'notif-103',
        recipientUserId: 'usr_admin',
        title: 'Scheduled System Maintenance',
        body: 'CRM core infrastructure upgrade scheduled for Saturday 22:00 UTC.',
        category: NotificationCategory.systemAlert,
        priority: NotificationPriority.info,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      CrmNotification(
        id: 'notif-201',
        recipientUserId: 'usr_buyer',
        title: 'Purchase Order Rejected',
        body: 'PO #PO-9825 was rejected by Finance. Reason: Quarterly budget limit reached.',
        category: NotificationCategory.approvalDecision,
        priority: NotificationPriority.warning,
        referenceModule: CrmModule.purchase,
        referenceEntityType: 'approval_request',
        referenceEntityId: 'appr-006',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      CrmNotification(
        id: 'notif-202',
        recipientUserId: 'usr_standard',
        title: 'New Lead Assignment',
        body: 'Acme Corp enterprise lead assigned to your queue.',
        category: NotificationCategory.systemAlert,
        priority: NotificationPriority.info,
        referenceModule: CrmModule.leadManagement,
        referenceEntityType: 'lead',
        referenceEntityId: 'lead-100',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    _notify();
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_notifications));
    }
  }

  bool _matchesRecipient(String notificationRecipient, String queryRecipient) {
    if (notificationRecipient == queryRecipient) return true;
    if ((notificationRecipient == 'usr_admin' && queryRecipient == 'admin') ||
        (notificationRecipient == 'admin' && queryRecipient == 'usr_admin')) {
      return true;
    }
    if ((notificationRecipient == 'usr_standard' && queryRecipient == 'user') ||
        (notificationRecipient == 'user' && queryRecipient == 'usr_standard')) {
      return true;
    }
    if ((notificationRecipient == 'usr_buyer' && queryRecipient == 'buyer') ||
        (notificationRecipient == 'buyer' && queryRecipient == 'usr_buyer')) {
      return true;
    }
    return false;
  }

  /// Returns a stream of notifications for a specific recipient user.
  Stream<List<CrmNotification>> watchNotifications(String recipientUserId) {
    return _streamController.stream.map(
      (list) => list
          .where((n) => _matchesRecipient(n.recipientUserId, recipientUserId))
          .toList(),
    );
  }

  /// Queries notifications for a specific user with optional filters.
  List<CrmNotification> getNotifications({
    required String recipientUserId,
    bool? unreadOnly,
    NotificationCategory? category,
  }) {
    return _notifications.where((n) {
      if (!_matchesRecipient(n.recipientUserId, recipientUserId)) return false;
      if (unreadOnly == true && n.isRead) return false;
      if (category != null && n.category != category) return false;
      return true;
    }).toList();
  }

  /// Calculates the unread notification count for a user.
  int getUnreadCount(String recipientUserId) {
    return _notifications
        .where(
          (n) => _matchesRecipient(n.recipientUserId, recipientUserId) && !n.isRead,
        )
        .length;
  }

  /// Marks a specific notification as read.
  void markAsRead({required String notificationId, required String userId}) {
    final index = _notifications.indexWhere(
      (n) => n.id == notificationId && _matchesRecipient(n.recipientUserId, userId),
    );
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now().toUtc(),
      );
      _notify();
    }
  }

  /// Marks all notifications for a specific user as read.
  void markAllAsRead(String userId) {
    var changed = false;
    final now = DateTime.now().toUtc();
    for (var i = 0; i < _notifications.length; i++) {
      if (_matchesRecipient(_notifications[i].recipientUserId, userId) &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: now,
        );
        changed = true;
      }
    }
    if (changed) {
      _notify();
    }
  }

  /// Clears/deletes a single notification for a user.
  void clearNotification({
    required String notificationId,
    required String userId,
  }) {
    final countBefore = _notifications.length;
    _notifications.removeWhere(
      (n) =>
          n.id == notificationId && _matchesRecipient(n.recipientUserId, userId),
    );
    if (_notifications.length != countBefore) {
      _notify();
    }
  }

  /// Dispatches a new notification to a recipient user.
  CrmNotification dispatchNotification(CreateNotificationInput input) {
    _counter++;
    final id = 'notif-$_counter';
    final now = DateTime.now().toUtc();

    final notification = CrmNotification(
      id: id,
      recipientUserId: input.recipientUserId,
      title: input.title,
      body: input.body,
      category: input.category,
      priority: input.priority,
      referenceModule: input.referenceModule,
      referenceEntityType: input.referenceEntityType,
      referenceEntityId: input.referenceEntityId,
      isRead: false,
      createdAt: now,
      payload: input.payload,
    );

    _notifications.insert(0, notification);
    _notify();
    return notification;
  }

  /// Closes internal stream controllers.
  void dispose() {
    _streamController.close();
  }
}
