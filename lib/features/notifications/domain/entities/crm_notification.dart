import 'package:flutter/foundation.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import 'notification_category.dart';
import 'notification_priority.dart';

/// The authoritative in-app notification entity delivered to a specific CRM user.
@immutable
class CrmNotification {
  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final CrmModule? referenceModule;
  final String? referenceEntityType;
  final String? referenceEntityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  CrmNotification({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    this.category = NotificationCategory.systemAlert,
    this.priority = NotificationPriority.info,
    this.referenceModule,
    this.referenceEntityType,
    this.referenceEntityId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    Map<String, dynamic> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  CrmNotification copyWith({
    String? id,
    String? recipientUserId,
    String? title,
    String? body,
    NotificationCategory? category,
    NotificationPriority? priority,
    CrmModule? referenceModule,
    String? referenceEntityType,
    String? referenceEntityId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return CrmNotification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      referenceModule: referenceModule ?? this.referenceModule,
      referenceEntityType: referenceEntityType ?? this.referenceEntityType,
      referenceEntityId: referenceEntityId ?? this.referenceEntityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrmNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recipientUserId == other.recipientUserId &&
          title == other.title &&
          category == other.category &&
          priority == other.priority &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    recipientUserId,
    title,
    category,
    priority,
    isRead,
    createdAt,
  );
}
