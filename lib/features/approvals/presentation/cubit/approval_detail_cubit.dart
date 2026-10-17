import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/approval_repository.dart';
import 'approval_detail_state.dart';

/// Cubit managing loading, inspection, and real-time step tracking for an individual approval request.
class ApprovalDetailCubit extends Cubit<ApprovalDetailState> {
  final ApprovalRepository _repository;
  String? _currentRequestId;
  int _loadSequence = 0;

  ApprovalDetailCubit(this._repository) : super(const ApprovalDetailInitial());

  /// Loads full details and audit timeline for the specified request ID.
  Future<void> loadDetail(String requestId) async {
    _currentRequestId = requestId;
    final seq = ++_loadSequence;

    emit(const ApprovalDetailLoading());

    try {
      final request = await _repository.getApprovalById(requestId);

      if (isClosed || seq != _loadSequence) return;

      if (request == null) {
        emit(ApprovalDetailFailure('Approval request "$requestId" not found.'));
        return;
      }

      final auditTrail = await _repository.getAuditTrail(requestId);

      if (isClosed || seq != _loadSequence) return;

      emit(
        ApprovalDetailLoaded(
          request: request,
          auditTrail: auditTrail,
        ),
      );
    } catch (e) {
      if (isClosed || seq != _loadSequence) return;
      emit(ApprovalDetailFailure('Failed to load request: ${e.toString()}'));
    }
  }

  /// Refreshes the currently active approval request detail.
  Future<void> refresh() async {
    if (_currentRequestId != null) {
      await loadDetail(_currentRequestId!);
    }
  }
}
