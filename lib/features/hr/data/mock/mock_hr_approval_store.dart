import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/entities/hr_approval_status.dart';
import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_approval_workflow_type.dart';
import '../../domain/exceptions/hr_approval_exception.dart';

/// In-memory thread-safe mock store for HR approval requests.
///
/// Follows HR-9 architectural constraints:
/// - Deterministic initial seed fixtures across stable CRM user and HR target references.
/// - Full copy isolation: returning new instances to prevent caller mutation leaks.
/// - UTC-normalized timestamps; no random data generation.
/// - Strictly side-effect free: does NOT mutate source Employee, Attendance, KPI, or Payroll stores.
/// - Configurable error injection for test coverage of failure and retry states.
class MockHrApprovalStore {
  final Map<String, HrApprovalRequest> _requests = {};
  int _counter = 100;
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
    final request = HrApprovalRequest(
      id: id,
      workflowType: workflowType,
      requesterId: requesterId.trim(),
      target: target,
      status: HrApprovalStatus.pending,
      createdAt: submissionTime ?? DateTime.now().toUtc(),
      remarks: remarks?.trim().isEmpty == true ? null : remarks?.trim(),
    );

    _requests[id] = request;
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

  /// Clears and re-seeds the store.
  void reset() {
    _requests.clear();
    _counter = 100;
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
