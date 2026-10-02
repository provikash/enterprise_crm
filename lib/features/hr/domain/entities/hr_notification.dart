import 'hr_approval_target.dart';
import 'hr_notification_channel.dart';
import 'hr_notification_type.dart';

/// Immutable domain representation of an in-app notification in Enterprise CRM.
///
/// Follows HR-9.7 architectural invariants:
/// - Recipient Identity: strictly references [recipientUserId] (`CurrentUser.id`), never workforce `Employee.id`.
/// - Content Privacy: contains only high-level, generic summaries. Zero salary figures,
///   zero deduction amounts, zero PII, and zero sensitive document bytes.
/// - Event Reference: stable pointer to [requestId] and [target].
/// - Normalized Timestamps: all timestamps are stored in UTC.
class HrNotification {
  final String id;
  final String recipientUserId;
  final HrNotificationType type;
  final HrNotificationChannel channel;
  final String title;
  final String body;
  final HrApprovalTarget target;
  final String requestId;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  HrNotification({
    required this.id,
    required this.recipientUserId,
    required this.type,
    this.channel = HrNotificationChannel.inApp,
    required this.title,
    required this.body,
    required this.target,
    required this.requestId,
    required DateTime createdAt,
    this.isRead = false,
    DateTime? readAt,
  })  : assert(id.trim().isNotEmpty, 'Notification id cannot be empty'),
        assert(recipientUserId.trim().isNotEmpty, 'recipientUserId cannot be empty'),
        assert(title.trim().isNotEmpty, 'title cannot be empty'),
        assert(body.trim().isNotEmpty, 'body cannot be empty'),
        assert(requestId.trim().isNotEmpty, 'requestId cannot be empty'),
        createdAt = createdAt.isUtc ? createdAt : createdAt.toUtc(),
        readAt = readAt != null
            ? (readAt.isUtc ? readAt : readAt.toUtc())
            : null;

  /// Creates a copy of this notification with specified fields updated.
  HrNotification copyWith({
    String? id,
    String? recipientUserId,
    HrNotificationType? type,
    HrNotificationChannel? channel,
    String? title,
    String? body,
    HrApprovalTarget? target,
    String? requestId,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    bool clearReadAt = false,
  }) {
    return HrNotification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      title: title ?? this.title,
      body: body ?? this.body,
      target: target ?? this.target,
      requestId: requestId ?? this.requestId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
    );
  }

  /// Marks this notification as read at the given [timestamp] (defaults to UTC now).
  HrNotification markAsRead({DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now().toUtc();
    return copyWith(
      isRead: true,
      readAt: now.isUtc ? now : now.toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recipientUserId == other.recipientUserId &&
          type == other.type &&
          channel == other.channel &&
          title == other.title &&
          body == other.body &&
          target == other.target &&
          requestId == other.requestId &&
          createdAt == other.createdAt &&
          isRead == other.isRead &&
          readAt == other.readAt;

  @override
  int get hashCode => Object.hash(
        id,
        recipientUserId,
        type,
        channel,
        title,
        body,
        target,
        requestId,
        createdAt,
        isRead,
        readAt,
      );

  @override
  String toString() =>
      'HrNotification(id: $id, recipient: $recipientUserId, type: $type, '
      'requestId: $requestId, isRead: $isRead)';
}
