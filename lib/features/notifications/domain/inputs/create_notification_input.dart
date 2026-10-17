import 'package:flutter/foundation.dart';
import '../../../../features/auth/domain/entities/crm_module.dart';
import '../entities/notification_category.dart';
import '../entities/notification_priority.dart';

/// Data payload required to dispatch a notification to a specific user.
@immutable
class CreateNotificationInput {
  final String recipientUserId;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final CrmModule? referenceModule;
  final String? referenceEntityType;
  final String? referenceEntityId;
  final Map<String, dynamic> payload;

  const CreateNotificationInput({
    required this.recipientUserId,
    required this.title,
    required this.body,
    this.category = NotificationCategory.systemAlert,
    this.priority = NotificationPriority.info,
    this.referenceModule,
    this.referenceEntityType,
    this.referenceEntityId,
    this.payload = const {},
  });
}
