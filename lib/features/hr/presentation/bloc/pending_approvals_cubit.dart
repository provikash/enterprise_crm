import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import 'pending_approvals_state.dart';

/// Cubit managing the query, loading, and filter state of pending and submitted HR approval requests.
///
/// Invariants:
/// - Stale async result protection: monotonically increasing [_activeRequestId]
///   ensures out-of-order responses do not overwrite the current view.
/// - Session isolation: [clear] purges in-flight state upon account change or logout.
/// - Route authorization: evaluates [HrAccessPolicy.canAccessModule].
class PendingApprovalsCubit extends Cubit<PendingApprovalsState> {
  final HrApprovalRepository _repository;
  int _activeRequestId = 0;
  CurrentUser? _currentUser;
  PendingApprovalsFilterMode _currentMode = PendingApprovalsFilterMode.pending;

  PendingApprovalsCubit({required HrApprovalRepository repository})
      : _repository = repository,
        super(const PendingApprovalsInitial());

  /// Current active filter mode.
  PendingApprovalsFilterMode get currentMode => _currentMode;

  /// Loads pending approval requests visible to [user].
  Future<void> loadPendingApprovals({required CurrentUser user}) async {
    _currentUser = user;
    _currentMode = PendingApprovalsFilterMode.pending;
    await _executeQuery();
  }

  /// Loads approval requests submitted by [user].
  Future<void> loadMyRequests({required CurrentUser user}) async {
    _currentUser = user;
    _currentMode = PendingApprovalsFilterMode.myRequests;
    await _executeQuery();
  }

  /// Switches filter mode between pending approvals and own requests.
  Future<void> switchMode(
    PendingApprovalsFilterMode mode, {
    required CurrentUser user,
  }) async {
    if (_currentMode == mode && state is PendingApprovalsLoaded) {
      return;
    }
    _currentUser = user;
    _currentMode = mode;
    await _executeQuery();
  }

  /// Refreshes the current active query.
  Future<void> refresh() async {
    if (_currentUser == null) return;
    await _executeQuery();
  }

  /// Clears state on session change or logout.
  void clear() {
    _activeRequestId++;
    _currentUser = null;
    _currentMode = PendingApprovalsFilterMode.pending;
    if (!isClosed) {
      emit(const PendingApprovalsInitial());
    }
  }

  Future<void> _executeQuery() async {
    final user = _currentUser;
    final mode = _currentMode;

    if (user == null || !HrAccessPolicy.canAccessModule(user)) {
      emit(PendingApprovalsFailure(
        message: 'Unauthorized to view HR approval requests.',
        mode: mode,
      ));
      return;
    }

    final requestId = ++_activeRequestId;
    emit(PendingApprovalsLoading(mode));

    try {
      final List<HrApprovalRequest> requests;
      if (mode == PendingApprovalsFilterMode.pending) {
        requests = await _repository.getPendingRequests(user: user);
      } else {
        requests = await _repository.getRequestsSubmittedBy(user.id);
      }

      // Discard stale response if a newer query was dispatched
      if (requestId != _activeRequestId || isClosed) {
        return;
      }

      if (requests.isEmpty) {
        emit(PendingApprovalsEmpty(mode));
      } else {
        emit(PendingApprovalsLoaded(requests: requests, mode: mode));
      }
    } catch (e) {
      if (requestId != _activeRequestId || isClosed) {
        return;
      }
      final message = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      emit(PendingApprovalsFailure(message: message, mode: mode));
    }
  }
}
