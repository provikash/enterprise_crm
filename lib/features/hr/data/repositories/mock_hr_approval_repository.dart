import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_decision.dart';
import '../../domain/entities/hr_approval_history_entry.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_approval_workflow_type.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../../domain/services/hr_approval_notification_service.dart';
import '../mock/mock_hr_approval_store.dart';

/// Mock implementation of [HrApprovalRepository] backed by [MockHrApprovalStore].
///
/// Follows repository patterns established across the Enterprise CRM.
/// Presentation Cubits and future UI screens depend exclusively on this abstraction.
class MockHrApprovalRepository implements HrApprovalRepository {
  final MockHrApprovalStore _store;
  final HrApprovalNotificationService? _notificationService;

  MockHrApprovalRepository({
    MockHrApprovalStore? store,
    HrApprovalNotificationService? notificationService,
  })  : _store = store ?? MockHrApprovalStore(),
        _notificationService = notificationService;

  /// Access to the underlying mock store for testing and reset capability.
  MockHrApprovalStore get store => _store;

  /// Access to the optional notification service.
  HrApprovalNotificationService? get notificationService => _notificationService;

  @override
  Future<HrApprovalRequest> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
  }) async {
    final req = _store.submitRequest(
      workflowType: workflowType,
      requesterId: requesterId,
      target: target,
      remarks: remarks,
    );
    await _notificationService?.handleRequestSubmitted(req);
    return req;
  }

  @override
  Future<HrApprovalRequest?> getRequestById(String id) async {
    return _store.getRequestById(id);
  }

  @override
  Future<List<HrApprovalRequest>> getRequestsSubmittedBy(
    String requesterId,
  ) async {
    return _store.getRequestsSubmittedBy(requesterId);
  }

  @override
  Future<List<HrApprovalRequest>> getPendingRequests({CurrentUser? user}) async {
    return _store.getPendingRequests(user: user);
  }

  @override
  Future<List<HrApprovalRequest>> getRequestsForTarget(
    HrApprovalTarget target,
  ) async {
    return _store.getRequestsForTarget(target);
  }

  @override
  Future<List<HrApprovalRequest>> getAllRequests({CurrentUser? user}) async {
    return _store.getAllRequests(user: user);
  }

  @override
  Future<HrApprovalRequest> submitDecision({
    required String requestId,
    required HrApprovalDecision decision,
    required CurrentUser actor,
  }) async {
    final req = _store.submitDecision(
      requestId: requestId,
      decision: decision,
      actor: actor,
    );
    await _notificationService?.handleDecisionRecorded(req, decision);
    return req;
  }

  @override
  Future<HrApprovalRequest> cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  }) async {
    final req = _store.cancelRequest(
      requestId: requestId,
      actor: actor,
      reason: reason,
    );
    await _notificationService?.handleRequestCancelled(req, actor: actor, reason: reason);
    return req;
  }

  @override
  Future<List<HrApprovalHistoryEntry>> getHistoryForRequest(
    String requestId,
  ) async {
    return _store.getHistoryForRequest(requestId);
  }
}
