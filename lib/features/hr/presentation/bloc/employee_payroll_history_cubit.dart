import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payroll_period.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'employee_payroll_history_state.dart';

/// Cubit managing state for the Employee Payroll History screen.
///
/// Follows HR-6.7 requirements:
/// - Stably requests history by [employeeId] via [PayrollRepository].
/// - Resolves associated [PayrollPeriod] records for human-readable labels.
/// - Concurrency-safe: tracks request IDs to prevent stale or out-of-order responses.
/// - Prevents cross-employee data leaks: clears previous employee data on request.
/// - Purely read-only: performs 0 client-side calculations or salary modifications.
class EmployeePayrollHistoryCubit extends Cubit<EmployeePayrollHistoryState> {
  final PayrollRepository _repository;
  int _activeRequestId = 0;

  EmployeePayrollHistoryCubit({
    required PayrollRepository repository,
    String? initialEmployeeId,
  })  : _repository = repository,
        super(EmployeePayrollHistoryState(employeeId: initialEmployeeId)) {
    if (initialEmployeeId != null && initialEmployeeId.trim().isNotEmpty) {
      loadHistory(initialEmployeeId);
    }
  }

  /// Loads payroll records and periods for the specified [employeeId].
  ///
  /// Concurrency-safe: increments [_activeRequestId] to ensure that if employees
  /// are switched rapidly, only the most recently initiated query completes.
  Future<void> loadHistory(String employeeId) async {
    final cleanId = employeeId.trim();
    if (cleanId.isEmpty) return;

    final requestId = ++_activeRequestId;

    // Reset records when querying a different employee to avoid cross-employee leakage
    emit(
      state.copyWith(
        status: EmployeePayrollHistoryStatus.loading,
        employeeId: cleanId,
        records: cleanId == state.employeeId ? state.records : const [],
        clearErrorMessage: true,
      ),
    );

    try {
      final records = await _repository.getPayrollRecordsForEmployee(cleanId);

      // Early exit if a subsequent request was launched
      if (requestId != _activeRequestId || isClosed) return;

      Map<String, PayrollPeriod> periodsMap = {};
      try {
        final periodsList = await _repository.getPayrollPeriods();
        if (requestId != _activeRequestId || isClosed) return;
        periodsMap = {for (final p in periodsList) p.id: p};
      } catch (_) {
        // Continue with empty periods map if periods fetch fails; record display should still function
      }

      if (records.isEmpty) {
        emit(
          state.copyWith(
            status: EmployeePayrollHistoryStatus.empty,
            employeeId: cleanId,
            records: const [],
            periods: periodsMap,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: EmployeePayrollHistoryStatus.loaded,
            employeeId: cleanId,
            records: records,
            periods: periodsMap,
          ),
        );
      }
    } catch (e) {
      if (requestId != _activeRequestId || isClosed) return;
      emit(
        state.copyWith(
          status: EmployeePayrollHistoryStatus.error,
          employeeId: cleanId,
          errorMessage: 'Failed to load payroll history. Please try again.',
        ),
      );
    }
  }

  /// Retries loading history for the current [employeeId].
  void retry() {
    if (state.employeeId != null) {
      loadHistory(state.employeeId!);
    }
  }
}
