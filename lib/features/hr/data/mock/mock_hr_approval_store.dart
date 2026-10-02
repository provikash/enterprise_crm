import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_decision.dart';
import '../../domain/entities/hr_approval_history_entry.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/entities/hr_approval_status.dart';
import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_approval_workflow_type.dart';
import '../../domain/exceptions/hr_approval_exception.dart';
import '../../domain/services/hr_approval_workflow_validator.dart';

/// In-memory thread-safe mock store for HR approval requests and audit history.
///
/// Follows HR-9 architectural constraints:
/// - Deterministic initial seed fixtures across stable CRM user and HR target references.
/// - Full copy isolation: returning new instances to prevent caller mutation leaks.
/// - UTC-normalized timestamps; no random data generation.
/// - Strictly side-effect free: does NOT mutate source Employee, Attendance, KPI, or Payroll stores.
/// - Configurable error injection for test coverage of failure and retry states.
/// - Atomic status and history updates for decisions and cancellations.
class MockHrApprovalStore {
  final Map<String, HrApprovalRequest> _requests = {};
  final Map<String, List<HrApprovalHistoryEntry>> _history = {};
  int _counter = 100;
  int _historyCounter = 100;
  bool _shouldThrow = false;

  MockHrApprovalStore({bool seedInitialData = true}) {
    if (seedInitialData) {
      _seed();
    }
  }

  void _seed() {
    final seedItems = [
      HrApprovalRequest(
        id: 'appr_req_1',
        workflowType: HrApprovalWorkflowType.payrollFinalization,
        requesterId: 'usr_hr',
        target: HrApprovalTarget.payrollPeriod('period_2026_01'),
        status: HrApprovalStatus.pending,
        createdAt: DateTime.utc(2026, 2, 1, 10, 0),
        remarks: 'January 2026 payroll finalization request',
      ),
      HrApprovalRequest(
        id: 'appr_req_2',
        workflowType: HrApprovalWorkflowType.attendanceCorrection,
        requesterId: 'usr_standard',
        target: HrApprovalTarget.attendanceRecord('att_1'),
        status: HrApprovalStatus.pending,
        createdAt: DateTime.utc(2026, 2, 2, 11, 30),
        remarks: 'Check-in time adjustment for Feb 1',
      ),
      HrApprovalRequest(
        id: 'appr_req_3',
        workflowType: HrApprovalWorkflowType.documentVerification,
        requesterId: 'usr_admin',
        target: HrApprovalTarget.employeeDocument('doc_1'),
        status: HrApprovalStatus.approved,
        createdAt: DateTime.utc(2026, 1, 15, 9, 0),
        updatedAt: DateTime.utc(2026, 1, 15, 14, 0),
        remarks: 'Government ID verification verified and approved',
      ),
    ];

    for (final req in seedItems) {
      _requests[req.id] = req;
    }

    // Seed corresponding history entries
    _history['appr_req_1'] = [
      HrApprovalHistoryEntry(
        id: 'hist_1',
        requestId: 'appr_req_1',
        actorId: 'usr_hr',
        action: 'submitted',
        newStatus: HrApprovalStatus.pending,
        timestamp: DateTime.utc(2026, 2, 1, 10, 0),
        reason: 'January 2026 payroll finalization request',
      ),
    ];

    _history['appr_req_2'] = [
      HrApprovalHistoryEntry(
        id: 'hist_2',
        requestId: 'appr_req_2',
        actorId: 'usr_standard',
        action: 'submitted',
        newStatus: HrApprovalStatus.pending,
        timestamp: DateTime.utc(2026, 2, 2, 11, 30),
        reason: 'Check-in time adjustment for Feb 1',
      ),
    ];

    _history['appr_req_3'] = [
      HrApprovalHistoryEntry(
        id: 'hist_3',
        requestId: 'appr_req_3',
        actorId: 'usr_admin',
        action: 'submitted',
        newStatus: HrApprovalStatus.pending,
        timestamp: DateTime.utc(2026, 1, 15, 9, 0),
        reason: 'Government ID verification submitted',
      ),
      HrApprovalHistoryEntry(
        id: 'hist_4',
        requestId: 'appr_req_3',
        actorId: 'usr_admin',
        action: 'approved',
        previousStatus: HrApprovalStatus.pending,
        newStatus: HrApprovalStatus.approved,
        timestamp: DateTime.utc(2026, 1, 15, 14, 0),
        reason: 'Government ID verification verified and approved',
      ),
    ];
  }

  /// Sets error simulation flag.
  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  void _checkThrow() {
    if (_shouldThrow) {
      throw const HrApprovalWorkflowException(
        'Simulated mock approval store failure.',
        code: 'STORE_FAILURE',
      );
    }
  }

  /// Submits and stores a new approval request.
  HrApprovalRequest submitRequest({
    required HrApprovalWorkflowType workflowType,
    required String requesterId,
    required HrApprovalTarget target,
    String? remarks,
    DateTime? submissionTime,
  }) {
    _checkThrow();

    if (requesterId.trim().isEmpty) {
      throw const HrApprovalWorkflowException(
        'Requester ID cannot be empty.',
        code: HrApprovalWorkflowException.validationError,
      );
    }

    final id = 'appr_req_${++_counter}';
    final now = submissionTime ?? DateTime.now().toUtc();
    final request = HrApprovalRequest(
      id: id,
      workflowType: workflowType,
      requesterId: requesterId.trim(),
      target: target,
      status: HrApprovalStatus.pending,
      createdAt: now,
      remarks: remarks?.trim().isEmpty == true ? null : remarks?.trim(),
    );

    _requests[id] = request;

    // Record submission history entry
    final historyEntry = HrApprovalHistoryEntry(
      id: 'hist_${++_historyCounter}',
      requestId: id,
      actorId: requesterId.trim(),
      action: 'submitted',
      newStatus: HrApprovalStatus.pending,
      timestamp: now,
      reason: remarks?.trim().isEmpty == true ? null : remarks?.trim(),
    );
    _history.putIfAbsent(id, () => []).add(historyEntry);

    return _clone(request);
  }

  /// Retrieves an approval request by its unique [id].
  HrApprovalRequest? getRequestById(String id) {
    _checkThrow();
    final req = _requests[id];
    return req != null ? _clone(req) : null;
  }

  /// Retrieves all approval requests submitted by [requesterId], sorted newest-first.
  List<HrApprovalRequest> getRequestsSubmittedBy(String requesterId) {
    _checkThrow();
    final matches = _requests.values
        .where((r) => r.requesterId == requesterId)
        .map(_clone)
        .toList();
    _sortNewestFirst(matches);
    return matches;
  }

  /// Retrieves pending approval requests visible to [user], sorted newest-first.
  List<HrApprovalRequest> getPendingRequests({CurrentUser? user}) {
    _checkThrow();
    var query = _requests.values.where((r) => r.status.isPending);

    if (user != null && !user.isAdmin) {
      // Standard users only see pending requests they submitted
      query = query.where((r) => r.requesterId == user.id);
    }

    final result = query.map(_clone).toList();
    _sortNewestFirst(result);
    return result;
  }

  /// Retrieves approval requests matching [target], sorted newest-first.
  List<HrApprovalRequest> getRequestsForTarget(HrApprovalTarget target) {
    _checkThrow();
    final result = _requests.values
        .where((r) => r.target == target)
        .map(_clone)
        .toList();
    _sortNewestFirst(result);
    return result;
  }

  /// Retrieves all approval requests visible to [user], sorted newest-first.
  List<HrApprovalRequest> getAllRequests({CurrentUser? user}) {
    _checkThrow();
    var query = _requests.values;

    if (user != null && !user.isAdmin) {
      query = query.where((r) => r.requesterId == user.id);
    }

    final result = query.map(_clone).toList();
    _sortNewestFirst(result);
    return result;
  }

  /// Submits and atomically executes a decision on [requestId] by [actor].
  HrApprovalRequest submitDecision({
    required String requestId,
    required HrApprovalDecision decision,
    required CurrentUser actor,
  }) {
    _checkThrow();

    final req = _requests[requestId];
    if (req == null) {
      throw HrApprovalWorkflowException(
        'Approval request "$requestId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    // Pure domain validation and transition derivation
    final updated = HrApprovalWorkflowValidator.applyDecision(
      request: req,
      decision: decision,
      actor: actor,
    );

    // Atomic update in store
    _requests[requestId] = updated;

    final historyEntry = HrApprovalHistoryEntry(
      id: 'hist_${++_historyCounter}',
      requestId: requestId,
      actorId: actor.id,
      action: decision.isApproved ? 'approved' : 'rejected',
      previousStatus: req.status,
      newStatus: updated.status,
      timestamp: decision.decisionTime,
      reason: decision.reason,
    );
    _history.putIfAbsent(requestId, () => []).add(historyEntry);

    return _clone(updated);
  }

  /// Cancels an active pending approval request.
  HrApprovalRequest cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
    DateTime? cancellationTime,
  }) {
    _checkThrow();

    final req = _requests[requestId];
    if (req == null) {
      throw HrApprovalWorkflowException(
        'Approval request "$requestId" not found.',
        code: HrApprovalWorkflowException.requestNotFound,
      );
    }

    final time = cancellationTime ?? DateTime.now().toUtc();
    final updated = HrApprovalWorkflowValidator.applyCancellation(
      request: req,
      actor: actor,
      cancellationTime: time,
      reason: reason,
    );

    _requests[requestId] = updated;

    final historyEntry = HrApprovalHistoryEntry(
      id: 'hist_${++_historyCounter}',
      requestId: requestId,
      actorId: actor.id,
      action: 'cancelled',
      previousStatus: req.status,
      newStatus: updated.status,
      timestamp: time,
      reason: reason,
    );
    _history.putIfAbsent(requestId, () => []).add(historyEntry);

    return _clone(updated);
  }

  /// Retrieves the chronological audit history for [requestId].
  List<HrApprovalHistoryEntry> getHistoryForRequest(String requestId) {
    _checkThrow();
    final list = _history[requestId] ?? [];
    return list.map((e) => HrApprovalHistoryEntry(
      id: e.id,
      requestId: e.requestId,
      actorId: e.actorId,
      action: e.action,
      previousStatus: e.previousStatus,
      newStatus: e.newStatus,
      timestamp: e.timestamp,
      reason: e.reason,
    )).toList();
  }

  /// Clears and re-seeds the store.
  void reset() {
    _requests.clear();
    _history.clear();
    _counter = 100;
    _historyCounter = 100;
    _shouldThrow = false;
    _seed();
  }

  void _sortNewestFirst(List<HrApprovalRequest> list) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  HrApprovalRequest _clone(HrApprovalRequest req) {
    return req.copyWith();
  }
}
