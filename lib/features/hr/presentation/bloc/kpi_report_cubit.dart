import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/kpi_report_query.dart';
import '../../domain/entities/kpi_report_summary.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/hr_report_repository.dart';
import 'kpi_report_state.dart';

/// Cubit managing lifecycle, filters, and evaluation for KPI Performance Reports.
///
/// Follows HR-8.5 architectural requirements:
/// - Repository-injected; widgets do not query domain or repositories directly.
/// - Concurrent and stale query race-condition protection via [_activeRequestId].
/// - Sanitized user-facing error feedback.
class KpiReportCubit extends Cubit<KpiReportState> {
  final HrReportRepository _repository;
  int _activeRequestId = 0;

  KpiReportCubit({
    HrReportRepository? repository,
    KpiReportQuery initialQuery = KpiReportQuery.defaultQuery,
  })  : _repository = repository ?? MockHrReportRepository(),
        super(KpiReportState(query: initialQuery)) {
    loadReport();
  }

  /// Executes the KPI performance report query using current or provided [query].
  Future<void> loadReport({
    KpiReportQuery? query,
    bool forceRefresh = false,
  }) async {
    final effectiveQuery = query ?? state.query;
    final requestId = ++_activeRequestId;

    emit(state.copyWith(
      status: KpiReportStatus.loading,
      query: effectiveQuery,
      clearError: true,
    ));

    try {
      final result = await _repository.getKpiReport(effectiveQuery);

      if (requestId != _activeRequestId || isClosed) return;

      final summary = (result.metadata?['summary'] as KpiReportSummary?) ??
          KpiReportSummary.fromRows(result.rows);

      if (result.rows.isEmpty) {
        emit(state.copyWith(
          status: KpiReportStatus.empty,
          result: result,
          summary: summary,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: KpiReportStatus.loaded,
          result: result,
          summary: summary,
          clearError: true,
        ));
      }
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(state.copyWith(
        status: KpiReportStatus.failure,
        errorMessage:
            'Failed to generate KPI Performance Report. Please try again.',
      ));
    }
  }

  /// Updates the employee filter and re-evaluates the report.
  Future<void> setEmployeeFilter(String? employeeId) async {
    final trimmed = employeeId?.trim();
    final newQuery = state.query.copyWith(
      employeeId: trimmed,
      clearEmployeeId: trimmed == null || trimmed.isEmpty,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the metric name filter and re-evaluates the report.
  Future<void> setMetricFilter(String? metricName) async {
    final isAll = metricName == null || metricName == 'All';
    final newQuery = state.query.copyWith(
      metricName: isAll ? null : metricName,
      clearMetricName: isAll,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the evaluation period / date range filter and re-evaluates the report.
  Future<void> setDateRangeFilter(ReportDateRange? dateRange) async {
    final newQuery = state.query.copyWith(
      dateRange: dateRange,
      clearDateRange: dateRange == null,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the search query and re-evaluates the report.
  Future<void> setSearchTerm(String? term) async {
    final trimmed = term?.trim();
    final newQuery = state.query.copyWith(
      searchTerm: trimmed,
      clearSearchTerm: trimmed == null || trimmed.isEmpty,
    );
    await loadReport(query: newQuery);
  }

  /// Updates report sorting and re-evaluates the report.
  Future<void> setSort(ReportSort sort) async {
    final newQuery = state.query.copyWith(sort: sort);
    await loadReport(query: newQuery);
  }

  /// Clears all filters back to default and reloads.
  Future<void> clearFilters() async {
    const defaultQ = KpiReportQuery.defaultQuery;
    await loadReport(query: defaultQ);
  }

  /// Unified alias for resetting filters to default query.
  Future<void> resetFilters() => clearFilters();

  /// Retries the currently applied query after failure.
  Future<void> retry() async {
    await loadReport(forceRefresh: true);
  }
}
