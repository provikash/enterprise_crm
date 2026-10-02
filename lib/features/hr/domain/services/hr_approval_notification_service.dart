import '../../../../features/auth/domain/entities/current_user.dart';
import '../entities/hr_approval_decision.dart';
import '../entities/hr_approval_request.dart';
import '../entities/hr_notification.dart';
import '../entities/hr_notification_channel.dart';
import '../entities/hr_notification_type.dart';
import '../repositories/hr_notification_repository.dart';

/// Coordinates the dispatch of in-app notifications in response to confirmed HR approval events.
///
/// Follows HR-9.8 rules:
/// - Event Invariant: notifications are emitted ONLY after successful repository persistence.
/// - Failure Isolation: a failure during notification delivery must NEVER fail or corrupt
///   the underlying approval decision or request state.
/// - Content Privacy: zero salary amounts, zero deduction values, and zero PII are included
///   in notification messages.
/// - Duplicate Protection (Idempotency): prevents duplicate notifications for the same logical event.
/// - Recipient Identity: strictly addresses notifications to CRM user accounts (`CurrentUser.id`),
///   never workforce `Employee.id`.
class HrApprovalNotificationService {
  final HrNotificationRepository _notificationRepository;
  final Set<String> _dispatchedEventKeys = {};
  int _counter = 200;

  /// Default recipient for administrative approval notifications.
  /// In CRM mock fixtures, 'usr_admin' is the primary authorized system administrator.
  final String adminRecipientUserId;

  HrApprovalNotificationService({
    required HrNotificationRepository notificationRepository,
    this.adminRecipientUserId = 'usr_admin',
  }) : _notificationRepository = notificationRepository;

  String _generateId() {
    _counter++;
    return 'notif_$_counter';
  }

  /// Dispatches a notification to administrators when a new approval request is submitted (NOTIF-01).
  Future<HrNotification?> handleRequestSubmitted(HrApprovalRequest request) async {
    final eventKey = 'submitted_${request.id}';
    if (_dispatchedEventKeys.contains(eventKey)) {
      return null;
    }

    final notif = HrNotification(
      id: _generateId(),
      recipientUserId: adminRecipientUserId,
      type: HrNotificationType.approvalRequestSubmitted,
      channel: HrNotificationChannel.inApp,
      title: 'New Approval Request',
      body: 'A new request for ${request.target.targetEntityType} '
          '${request.target.targetEntityId} was submitted by ${request.requesterId}.',
      target: request.target,
      requestId: request.id,
      createdAt: request.createdAt,
    );

    try {
      final sent = await _notificationRepository.sendNotification(notif);
      _dispatchedEventKeys.add(eventKey);
      return sent;
    } catch (_) {
      // Failure isolation: notification failure must never corrupt approval state
      return null;
    }
  }

  /// Dispatches a notification to the requester when an approval or rejection decision is recorded (NOTIF-02, NOTIF-03).
  Future<HrNotification?> handleDecisionRecorded(
    HrApprovalRequest request,
    HrApprovalDecision decision,
  ) async {
    final eventKey = 'decision_${request.id}_${decision.decisionType.name}';
    if (_dispatchedEventKeys.contains(eventKey)) {
      return null;
    }

    final isApproved = decision.decisionType == HrApprovalDecisionType.approve;
    final title = isApproved ? 'Approval Decision Recorded' : 'Approval Request Rejected';
    final reasonSuffix = (!isApproved && decision.reason != null && decision.reason!.trim().isNotEmpty)
        ? ' Reason: ${decision.reason!.trim()}'
        : '';
    final actionText = isApproved ? 'approved' : 'rejected';

    final notif = HrNotification(
      id: _generateId(),
      recipientUserId: request.requesterId,
      type: HrNotificationType.approvalDecisionRecorded,
      channel: HrNotificationChannel.inApp,
      title: title,
      body: 'Your request for ${request.target.targetEntityType} '
          '${request.target.targetEntityId} was $actionText by ${decision.actorId}.$reasonSuffix',
      target: request.target,
      requestId: request.id,
      createdAt: decision.decisionTime,
    );

    try {
      final sent = await _notificationRepository.sendNotification(notif);
      _dispatchedEventKeys.add(eventKey);
      return sent;
    } catch (_) {
      // Failure isolation
      return null;
    }
  }

  /// Dispatches a notification to administrators when a request is cancelled by its requester (NOTIF-04).
  Future<HrNotification?> handleRequestCancelled(
    HrApprovalRequest request, {
    required CurrentUser actor,
    String? reason,
  }) async {
    final eventKey = 'cancelled_${request.id}';
    if (_dispatchedEventKeys.contains(eventKey)) {
      return null;
    }

    final notif = HrNotification(
      id: _generateId(),
      recipientUserId: adminRecipientUserId,
      type: HrNotificationType.approvalRequestCancelled,
      channel: HrNotificationChannel.inApp,
      title: 'Approval Request Cancelled',
      body: 'Request ${request.id} for ${request.target.targetEntityType} '
          '${request.target.targetEntityId} was cancelled by requester.',
      target: request.target,
      requestId: request.id,
      createdAt: DateTime.now().toUtc(),
    );

    try {
      final sent = await _notificationRepository.sendNotification(notif);
      _dispatchedEventKeys.add(eventKey);
      return sent;
    } catch (_) {
      // Failure isolation
      return null;
    }
  }

  /// Checks if an event has already been dispatched.
  bool isEventDispatched(String eventKey) => _dispatchedEventKeys.contains(eventKey);

  /// Resets state and deduplication cache for session isolation.
  void reset() {
    _dispatchedEventKeys.clear();
  }
}
