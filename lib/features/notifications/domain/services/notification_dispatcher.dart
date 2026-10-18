import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../approvals/domain/entities/approval_priority.dart';
import '../../../approvals/domain/entities/approval_request.dart';
import '../entities/crm_notification.dart';
import '../entities/notification_category.dart';
import '../entities/notification_priority.dart';
import '../inputs/create_notification_input.dart';
import '../repositories/notification_repository.dart';

/// Abstract service interface for dispatching real-time notifications across CRM business events.
abstract interface class NotificationDispatcher {
  /// Dispatches a raw notification input to a recipient user.
  Future<CrmNotification> dispatch(CreateNotificationInput input);

  /// Dispatches a notification to an assigned approver when an approval request is submitted.
  Future<CrmNotification> notifyApprovalRequested({
    required ApprovalRequest request,
    required String approverUserId,
  });

  /// Dispatches a notification to the requester when their request is decided (approved/rejected/revised).
  Future<CrmNotification> notifyApprovalDecision({
    required ApprovalRequest request,
    required String decision,
    String? notes,
  });

  /// Dispatches a system alert or operational announcement.
  Future<CrmNotification> notifySystemAlert({
    required String recipientUserId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.info,
    CrmModule? module,
  });
}

/// Default implementation of [NotificationDispatcher] delegating to [NotificationRepository].
class DefaultNotificationDispatcher implements NotificationDispatcher {
  final NotificationRepository _repository;

  const DefaultNotificationDispatcher(this._repository);

  @override
  Future<CrmNotification> dispatch(CreateNotificationInput input) async {
    return _repository.dispatchNotification(input);
  }

  @override
  Future<CrmNotification> notifyApprovalRequested({
    required ApprovalRequest request,
    required String approverUserId,
  }) async {
    final priority = switch (request.priority) {
      ApprovalPriority.urgent => NotificationPriority.critical,
      ApprovalPriority.high => NotificationPriority.warning,
      ApprovalPriority.normal => NotificationPriority.info,
      ApprovalPriority.low => NotificationPriority.info,
    };

    final input = CreateNotificationInput(
      recipientUserId: approverUserId,
      title: 'Approval Required: ${request.requestNumber}',
      body: '${request.requesterName} submitted "${request.entityTitle}" for your review.',
      category: NotificationCategory.approvalRequest,
      priority: priority,
      referenceModule: request.module,
      referenceEntityType: request.entityType,
      referenceEntityId: request.id,
      payload: {
        'requestId': request.id,
        'requestNumber': request.requestNumber,
        'requesterId': request.requesterId,
        'requesterName': request.requesterName,
        'entityTitle': request.entityTitle,
      },
    );

    return _repository.dispatchNotification(input);
  }

  @override
  Future<CrmNotification> notifyApprovalDecision({
    required ApprovalRequest request,
    required String decision,
    String? notes,
  }) async {
    final NotificationCategory category = NotificationCategory.approvalDecision;
    final NotificationPriority priority = switch (decision.toLowerCase()) {
      'rejected' => NotificationPriority.warning,
      'revision requested' => NotificationPriority.warning,
      'approved' => NotificationPriority.success,
      _ => NotificationPriority.info,
    };

    final notesText = notes != null && notes.trim().isNotEmpty
        ? ' Remarks: "$notes"'
        : '';

    final input = CreateNotificationInput(
      recipientUserId: request.requesterId,
      title: 'Request ${request.requestNumber} $decision',
      body: 'Your request "${request.entityTitle}" was marked as $decision.$notesText',
      category: category,
      priority: priority,
      referenceModule: request.module,
      referenceEntityType: request.entityType,
      referenceEntityId: request.id,
      payload: {
        'requestId': request.id,
        'requestNumber': request.requestNumber,
        'decision': decision,
        'notes': notes,
      },
    );

    return _repository.dispatchNotification(input);
  }

  @override
  Future<CrmNotification> notifySystemAlert({
    required String recipientUserId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.info,
    CrmModule? module,
  }) async {
    final input = CreateNotificationInput(
      recipientUserId: recipientUserId,
      title: title,
      body: message,
      category: NotificationCategory.systemAlert,
      priority: priority,
      referenceModule: module,
    );

    return _repository.dispatchNotification(input);
  }
}
