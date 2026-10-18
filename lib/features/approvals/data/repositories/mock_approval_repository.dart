import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../domain/entities/approval_activity.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/inputs/create_approval_request_input.dart';
import '../../domain/repositories/approval_repository.dart';
import '../mock/mock_approval_store.dart';

/// In-memory mock implementation of [ApprovalRepository] backed by [MockApprovalStore]
/// with optional lifecycle integration to [NotificationDispatcher].
class MockApprovalRepository implements ApprovalRepository {
  final MockApprovalStore _store;
  final NotificationDispatcher? _notificationDispatcher;

  MockApprovalRepository([
    MockApprovalStore? store,
    NotificationDispatcher? notificationDispatcher,
  ])  : _store = store ?? MockApprovalStore(),
        _notificationDispatcher = notificationDispatcher;

  @override
  Future<List<ApprovalRequest>> getApprovals({
    ApprovalStatus? status,
    CrmModule? module,
    ApprovalPriority? priority,
    String? requesterId,
    String? search,
  }) async {
    return _store.getApprovals(
      status: status,
      module: module,
      priority: priority,
      requesterId: requesterId,
      search: search,
    );
  }

  @override
  Future<ApprovalRequest?> getApprovalById(String id) async {
    return _store.getApprovalById(id);
  }

  @override
  Future<ApprovalRequest> submitRequest(CreateApprovalRequestInput input) async {
    final created = _store.submitRequest(input);

    if (_notificationDispatcher != null) {
      final activeStep = created.currentStep;
      if (activeStep?.assignedUserId != null) {
        await _notificationDispatcher.notifyApprovalRequested(
          request: created,
          approverUserId: activeStep!.assignedUserId!,
        );
      }
    }

    return created;
  }

  @override
  Future<ApprovalRequest> approveRequest({
    required String requestId,
    required CurrentUser actor,
    String? comment,
  }) async {
    final updated = _store.approveRequest(
      requestId: requestId,
      actor: actor,
      comment: comment,
    );

    if (_notificationDispatcher != null) {
      await _notificationDispatcher.notifyApprovalDecision(
        request: updated,
        decision: 'Approved',
        notes: comment,
      );

      // If multi-tier and now advancing to next approver
      if (updated.status == ApprovalStatus.pending &&
          updated.currentStep?.assignedUserId != null) {
        await _notificationDispatcher.notifyApprovalRequested(
          request: updated,
          approverUserId: updated.currentStep!.assignedUserId!,
        );
      }
    }

    return updated;
  }

  @override
  Future<ApprovalRequest> rejectRequest({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
  }) async {
    final updated = _store.rejectRequest(
      requestId: requestId,
      actor: actor,
      rejectionReason: rejectionReason,
    );

    if (_notificationDispatcher != null) {
      await _notificationDispatcher.notifyApprovalDecision(
        request: updated,
        decision: 'Rejected',
        notes: rejectionReason,
      );
    }

    return updated;
  }

  @override
  Future<ApprovalRequest> requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
  }) async {
    final updated = _store.requestRevision(
      requestId: requestId,
      actor: actor,
      revisionNotes: revisionNotes,
    );

    if (_notificationDispatcher != null) {
      await _notificationDispatcher.notifyApprovalDecision(
        request: updated,
        decision: 'Revision Requested',
        notes: revisionNotes,
      );
    }

    return updated;
  }

  @override
  Future<ApprovalRequest> cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  }) async {
    final updated = _store.cancelRequest(
      requestId: requestId,
      actor: actor,
      reason: reason,
    );

    if (_notificationDispatcher != null) {
      await _notificationDispatcher.notifyApprovalDecision(
        request: updated,
        decision: 'Cancelled',
        notes: reason,
      );
    }

    return updated;
  }

  @override
  Future<List<ApprovalActivity>> getAuditTrail(String requestId) async {
    final request = _store.getApprovalById(requestId);
    if (request == null) return [];
    return request.auditTrail;
  }
}
