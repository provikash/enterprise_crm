import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/attendance_report_query.dart';
import '../../domain/entities/attendance_report_summary.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/hr_report_repository.dart';
import 'attendance_report_state.dart';

/// Cubit managing lifecycle, filters, and evaluation for Attendance Reports.
///
/// Follows HR-8.4 architectural requirements:
/// - Repository-injected; widgets do not query domain or repositories directly.
/// - Concurrent and stale query race-condition protection via [_activeRequestId].
/// - Sanitized user-facing error feedback.
class AttendanceReportCubit extends Cubit<AttendanceReportState> {
  final HrReportRepository _repository;
  int _activeRequestId = 0;

  AttendanceReportCubit({
    HrReportRepository? repository,
    AttendanceReportQuery initialQuery = AttendanceReportQuery.defaultQuery,
  })  : _repository = repository ?? MockHrReportRepository(),
        super(AttendanceReportState(query: initialQuery)) {
    loadReport();
  }

  /// Executes the attendance report query using the current or provided [query].
  Future<void> loadReport({
    AttendanceReportQuery? query,
    bool forceRefresh = false,
  }) async {
    final effectiveQuery = query ?? state.query;
    final requestId = ++_activeRequestId;

    emit(state.copyWith(
      status: AttendanceReportStatus.loading,
      query: effectiveQuery,
      clearError: true,
    ));

    try {
      final result = await _repository.getAttendanceReport(effectiveQuery);

      if (requestId != _activeRequestId || isClosed) return;

      final summary = (result.metadata?['summary'] as AttendanceReportSummary?) ??
          AttendanceReportSummary.fromRows(result.rows);

      if (result.rows.isEmpty) {
        emit(state.copyWith(
          status: AttendanceReportStatus.empty,
          result: result,
          summary: summary,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AttendanceReportStatus.loaded,
          result: result,
          summary: summary,
          clearError: true,
        ));
      }
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(state.copyWith(
        status: AttendanceReportStatus.failure,
        errorMessage:
            'Failed to generate Attendance Report. Please try again.',
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

  /// Updates the attendance status filter and re-evaluates the report.
  Future<void> setStatusFilter(String? status) async {
    final isAll = status == null || status == 'All';
    final newQuery = state.query.copyWith(
      status: isAll ? null : status,
      clearStatus: isAll,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the date range filter and re-evaluates the report.
  Future<void> setDateRangeFilter(ReportDateRange? dateRange) async {
    final newQuery = state.query.copyWith(
      dateRange: dateRange,
      clearDateRange: dateRange == null,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the search term and re-evaluates the report.
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
    const defaultQ = AttendanceReportQuery.defaultQuery;
    await loadReport(query: defaultQ);
  }

  /// Unified alias for resetting filters to default query.
  Future<void> resetFilters() => clearFilters();

  /// Retries the currently applied query after failure.
  Future<void> retry() async {
    await loadReport(forceRefresh: true);
  }
}
