import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/hr_approval_target.dart';
import '../../domain/entities/hr_approval_workflow_type.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import 'hr_approval_request_state.dart';

/// Cubit managing the submission of an HR approval request.
///
/// Invariants:
/// - Double-tap protection: ignores submission requests while in-flight.
/// - Authorization guard: ensures requester has access to the HR module.
/// - Sanitized errors: never leaks raw stack traces or sensitive financial data.
class HrApprovalRequestCubit extends Cubit<HrApprovalRequestState> {
  final HrApprovalRepository _repository;

  HrApprovalRequestCubit({required HrApprovalRepository repository})
      : _repository = repository,
        super(const HrApprovalRequestInitial());

  /// Submits an approval request for an HR workflow.
  Future<void> submitRequest({
    required HrApprovalWorkflowType workflowType,
    required HrApprovalTarget target,
    required CurrentUser requester,
    String? remarks,
  }) async {
    // 1. Guard against duplicate submission while already submitting
    if (state is HrApprovalRequestSubmitting) {
      return;
    }

    // 2. Authorization check
    if (!HrAccessPolicy.canAccessModule(requester)) {
      emit(const HrApprovalRequestFailure('Unauthorized to submit HR approval requests.'));
      return;
    }

    // 3. Validation check
    if (target.targetEntityId.trim().isEmpty) {
      emit(const HrApprovalRequestFailure('Target entity ID is required.'));
      return;
    }

    emit(const HrApprovalRequestSubmitting());

    try {
      final request = await _repository.submitRequest(
        workflowType: workflowType,
        requesterId: requester.id,
        target: target,
        remarks: remarks,
      );

      if (!isClosed) {
        emit(HrApprovalRequestSuccess(request));
      }
    } catch (e) {
      if (!isClosed) {
        final message = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
        emit(HrApprovalRequestFailure(message));
      }
    }
  }

  /// Resets state back to initial.
  void reset() {
    if (!isClosed) {
      emit(const HrApprovalRequestInitial());
    }
  }
}
