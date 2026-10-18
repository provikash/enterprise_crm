import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/entities/notification_priority.dart';

/// Data Transfer Object representing in-app notifications mapped to/from REST endpoints.
class NotificationDto {
  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final String category;
  final String priority;
  final String? referenceModule;
  final String? referenceEntityType;
  final String? referenceEntityId;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic> payload;

  const NotificationDto({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    this.category = 'systemAlert',
    this.priority = 'info',
    this.referenceModule,
    this.referenceEntityType,
    this.referenceEntityId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.payload = const {},
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String? ?? '',
      recipientUserId: json['recipient_user_id'] as String? ??
          json['user_id'] as String? ??
          '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      category: json['category'] as String? ??
          json['notification_type'] as String? ??
          'systemAlert',
      priority: json['priority'] as String? ?? 'info',
      referenceModule: json['reference_module'] as String?,
      referenceEntityType: json['reference_entity_type'] as String? ??
          json['reference_type'] as String?,
      referenceEntityId: json['reference_entity_id'] as String? ??
          json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
      payload: (json['payload'] as Map<String, dynamic>?) ??
          (json['metadata'] as Map<String, dynamic>?) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_user_id': recipientUserId,
      'title': title,
      'body': body,
      'category': category,
      'priority': priority,
      if (referenceModule != null) 'reference_module': referenceModule,
      if (referenceEntityType != null)
        'reference_entity_type': referenceEntityType,
      if (referenceEntityId != null) 'reference_entity_id': referenceEntityId,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt,
      'created_at': createdAt,
      if (payload.isNotEmpty) 'payload': payload,
    };
  }

  CrmNotification toDomain() {
    return CrmNotification(
      id: id,
      recipientUserId: recipientUserId,
      title: title,
      body: body,
      category: NotificationCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
        orElse: () => NotificationCategory.systemAlert,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name.toLowerCase() == priority.toLowerCase(),
        orElse: () => NotificationPriority.info,
      ),
      referenceModule: referenceModule != null
          ? CrmModule.values.firstWhere(
              (m) => m.name.toLowerCase() == referenceModule!.toLowerCase(),
              orElse: () => CrmModule.approvalsNotifications,
            )
          : null,
      referenceEntityType: referenceEntityType,
      referenceEntityId: referenceEntityId,
      isRead: isRead,
      readAt: readAt != null ? DateTime.tryParse(readAt!) : null,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      payload: payload,
    );
  }

  factory NotificationDto.fromDomain(CrmNotification notification) {
    return NotificationDto(
      id: notification.id,
      recipientUserId: notification.recipientUserId,
      title: notification.title,
      body: notification.body,
      category: notification.category.name,
      priority: notification.priority.name,
      referenceModule: notification.referenceModule?.name,
      referenceEntityType: notification.referenceEntityType,
      referenceEntityId: notification.referenceEntityId,
      isRead: notification.isRead,
      readAt: notification.readAt?.toIso8601String(),
      createdAt: notification.createdAt.toIso8601String(),
      payload: notification.payload,
    );
  }
}
