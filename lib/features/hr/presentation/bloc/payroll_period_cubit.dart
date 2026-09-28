import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/payroll_repository.dart';
import 'payroll_period_state.dart';

/// Cubit managing state for loading and selecting approved Payroll Periods.
///
/// Follows HR-6.4 architectural constraints:
/// - Constructor injection of [PayrollRepository].
/// - Tracks selected period by stable unique identity.
/// - Validates selection against available records.
/// - Preserves valid selection across reloads, clearing safely if removed.
/// - Guards against stale asynchronous responses.
/// - Strictly decoupled from monetary calculations and mutation logic.
class PayrollPeriodCubit extends Cubit<PayrollPeriodState> {
  final PayrollRepository _repository;
  bool _isLoading = false;

  PayrollPeriodCubit({
    required PayrollRepository repository,
    String? initialPeriodId,
  })  : _repository = repository,
        super(PayrollPeriodState(selectedPeriodId: initialPeriodId));

  /// Loads approved payroll periods from the repository.
  Future<void> loadPeriods() async {
    if (isClosed || _isLoading) return;
    _isLoading = true;

    emit(state.copyWith(
      status: PayrollPeriodStatus.loading,
      clearError: true,
    ));

    try {
      final fetched = await _repository.getPayrollPeriods();
      if (isClosed) return;

      // Validate or preserve active selection
      String? preservedSelection = state.selectedPeriodId;
      bool shouldClear = false;

      if (preservedSelection != null) {
        final stillExists = fetched.any((p) => p.id == preservedSelection);
        if (!stillExists) {
          preservedSelection = null;
          shouldClear = true;
        }
      }

      emit(state.copyWith(
        status: PayrollPeriodStatus.loaded,
        periods: fetched,
        selectedPeriodId: preservedSelection,
        clearSelection: shouldClear,
        clearError: true,
      ));
    } on PayrollException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: PayrollPeriodStatus.failure,
        errorMessage: e.message,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        status: PayrollPeriodStatus.failure,
        errorMessage: 'Failed to load payroll periods. Please try again.',
      ));
    } finally {
      _isLoading = false;
    }
  }

  /// Selects an approved payroll period by its stable [periodId].
  ///
  /// Validates that [periodId] exists among the loaded periods before updating.
  /// If [periodId] is already selected or not found, safely ignores.
  void selectPeriod(String periodId) {
    if (isClosed || periodId == state.selectedPeriodId) return;

    final isValid = state.periods.any((p) => p.id == periodId);
    if (!isValid) return;

    emit(state.copyWith(selectedPeriodId: periodId));
  }

  /// Clears the active period selection.
  void clearSelection() {
    if (isClosed || state.selectedPeriodId == null) return;
    emit(state.copyWith(clearSelection: true));
  }

  /// Retries a previously failed period loading operation.
  Future<void> retry() async {
    await loadPeriods();
  }

  /// Reloads payroll periods while preserving valid selection.
  Future<void> reload() async {
    await loadPeriods();
  }
}
