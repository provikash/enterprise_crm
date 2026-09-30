import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/employee_kpi_repository.dart';
import 'employee_kpi_summary_state.dart';

/// Cubit managing loading, period selection, and data derivation for KPI Summary.
///
/// Ensures strict data consistency with the authoritative [EmployeeKpiRepository].
class EmployeeKpiSummaryCubit extends Cubit<EmployeeKpiSummaryState> {
  final EmployeeKpiRepository _repository;
  int _currentRequestId = 0;

  EmployeeKpiSummaryCubit({
    required EmployeeKpiRepository repository,
    DateTime? initialPeriodStart,
    DateTime? initialPeriodEnd,
  }) : _repository = repository,
       super(
         EmployeeKpiSummaryState(
           periodStart: initialPeriodStart,
           periodEnd: initialPeriodEnd,
         ),
       );

  /// Loads summary records for the specified period boundaries.
  Future<void> loadSummary({DateTime? startDate, DateTime? endDate}) async {
    final requestId = ++_currentRequestId;

    emit(
      state.copyWith(
        status: EmployeeKpiSummaryStatus.loading,
        periodStart: startDate,
        periodEnd: endDate,
        clearPeriod: startDate == null && endDate == null,
        clearError: true,
      ),
    );

    try {
      final records = await _repository.getKpis(
        startDate: startDate,
        endDate: endDate,
      );

      if (isClosed || requestId != _currentRequestId) return;

      emit(
        state.copyWith(
          status: EmployeeKpiSummaryStatus.loaded,
          records: records,
          periodStart: startDate,
          periodEnd: endDate,
          clearPeriod: startDate == null && endDate == null,
        ),
      );
    } on EmployeeKpiException catch (e) {
      if (isClosed || requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: EmployeeKpiSummaryStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: EmployeeKpiSummaryStatus.failure,
          errorMessage: 'Failed to load KPI summary. Please try again.',
        ),
      );
    }
  }

  /// Updates active measurement period and triggers a summary reload.
  void setPeriod(DateTime? startDate, DateTime? endDate) {
    loadSummary(startDate: startDate, endDate: endDate);
  }

  /// Reloads the summary using the currently selected period.
  Future<void> reload() async {
    await loadSummary(startDate: state.periodStart, endDate: state.periodEnd);
  }
}
