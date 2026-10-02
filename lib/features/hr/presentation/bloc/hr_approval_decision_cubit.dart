import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_decision.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/exceptions/hr_approval_exception.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import 'hr_approval_decision_state.dart';

/// Cubit managing approval decision submission, request cancellation, and audit history.
///
/// Invariants:
/// - Stale-response protection via sequential request version tokens.
/// - Duplicate-click and duplicate-decision prevention during in-flight operations.
/// - Authorization checks ensuring only authorized actors can trigger approve/reject/cancel.
/// - Session isolation: supports clean reset on user logout or session switch.
class HrApprovalDecisionCubit extends Cubit<HrApprovalDecisionState> {
  final HrApprovalRepository _repository;
  final CurrentUser _actor;
  final String _requestId;

  int _versionToken = 0;
  HrApprovalRequest? _currentRequest;

  HrApprovalDecisionCubit({
    required HrApprovalRepository repository,
    required CurrentUser actor,
    required String requestId,
    HrApprovalRequest? initialRequest,
  })  : _repository = repository,
        _actor = actor,
        _requestId = requestId,
        _currentRequest = initialRequest,
        super(const HrApprovalDecisionInitial());

  /// Retrieves the current loaded request, if any.
  HrApprovalRequest? get currentRequest => _currentRequest;

  /// Loads request details and its associated chronological audit history.
  Future<void> loadDetails() async {
    final token = ++_versionToken;

    if (!isClosed) {
      emit(const HrApprovalDecisionLoading());
    }

    try {
      final req = await _repository.getRequestById(_requestId);
      if (token != _versionToken || isClosed) return;

      if (req == null) {
        emit(HrApprovalDecisionFailure('Approval request "$_requestId" not found.'));
        return;
      }

      _currentRequest = req;
      final history = await _repository.getHistoryForRequest(_requestId);
      if (token != _versionToken || isClosed) return;

      final canDecide = _actor.isAdmin && req.status.isPending;
      final canCancel = req.status.isPending &&
          (_actor.isAdmin || _actor.id == req.requesterId);

      emit(HrApprovalDecisionReady(
        request: req,
        history: history,
        canDecide: canDecide,
        canCancel: canCancel,
      ));
    } on HrApprovalWorkflowException catch (e) {
      if (token == _versionToken && !isClosed) {
        emit(HrApprovalDecisionFailure(e.message));
      }
    } catch (e) {
      if (token == _versionToken && !isClosed) {
        final cleanMsg = e
            .toString()
            .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        emit(HrApprovalDecisionFailure(cleanMsg));
      }
    }
  }

  /// Submits an approval decision.
  Future<void> approve({String? reason}) async {
    await _executeDecision(
      decisionType: HrApprovalDecisionType.approve,
      reason: reason,
      actionLabel: 'approving',
      successMessage: 'Approval request was successfully approved.',
    );
  }

  /// Submits a rejection decision.
  Future<void> reject({String? reason}) async {
    await _executeDecision(
      decisionType: HrApprovalDecisionType.reject,
      reason: reason,
      actionLabel: 'rejecting',
      successMessage: 'Approval request was successfully rejected.',
    );
  }

  /// Cancels an active pending request.
  Future<void> cancel({String? reason}) async {
    if (state is HrApprovalDecisionSubmitting) return;

    final req = _currentRequest;
    if (req == null) {
      emit(const HrApprovalDecisionFailure('No active request loaded to cancel.'));
      return;
    }

    final token = ++_versionToken;
    emit(const HrApprovalDecisionSubmitting('cancelling'));

    try {
      final updated = await _repository.cancelRequest(
        requestId: req.id,
        actor: _actor,
        reason: reason,
      );
      if (token != _versionToken || isClosed) return;

      _currentRequest = updated;
      final history = await _repository.getHistoryForRequest(req.id);
      if (token != _versionToken || isClosed) return;

      emit(HrApprovalDecisionSuccess(
        request: updated,
        history: history,
        message: 'Approval request was successfully cancelled.',
      ));
    } on HrApprovalWorkflowException catch (e) {
      if (token == _versionToken && !isClosed) {
        emit(HrApprovalDecisionFailure(e.message));
      }
    } catch (e) {
      if (token == _versionToken && !isClosed) {
        final cleanMsg = e
            .toString()
            .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        emit(HrApprovalDecisionFailure(cleanMsg));
      }
    }
  }

  Future<void> _executeDecision({
    required HrApprovalDecisionType decisionType,
    required String? reason,
    required String actionLabel,
    required String successMessage,
  }) async {
    if (state is HrApprovalDecisionSubmitting) return;

    final req = _currentRequest;
    if (req == null) {
      emit(const HrApprovalDecisionFailure('No active request loaded to decide.'));
      return;
    }

    final token = ++_versionToken;
    emit(HrApprovalDecisionSubmitting(actionLabel));

    try {
      final decision = HrApprovalDecision(
        requestId: req.id,
        actorId: _actor.id,
        decisionType: decisionType,
        decisionTime: DateTime.now().toUtc(),
        reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      );

      final updated = await _repository.submitDecision(
        requestId: req.id,
        decision: decision,
        actor: _actor,
      );
      if (token != _versionToken || isClosed) return;

      _currentRequest = updated;
      final history = await _repository.getHistoryForRequest(req.id);
      if (token != _versionToken || isClosed) return;

      emit(HrApprovalDecisionSuccess(
        request: updated,
        history: history,
        message: successMessage,
      ));
    } on HrApprovalWorkflowException catch (e) {
      if (token == _versionToken && !isClosed) {
        emit(HrApprovalDecisionFailure(e.message));
      }
    } catch (e) {
      if (token == _versionToken && !isClosed) {
        final cleanMsg = e
            .toString()
            .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        emit(HrApprovalDecisionFailure(cleanMsg));
      }
    }
  }

  /// Resets the cubit state, discarding sensitive references.
  void reset() {
    _versionToken++;
    _currentRequest = null;
    emit(const HrApprovalDecisionInitial());
  }
}
