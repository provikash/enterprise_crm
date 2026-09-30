import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/employee_report_query.dart';
import '../../domain/entities/employment_status.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/hr_report_repository.dart';
import 'employee_report_state.dart';

/// Cubit managing state for the Employee Directory Report workflow.
///
/// Follows HR-8.3 specifications:
/// - Reuses domain [HrReportRepository].
/// - Pure orchestration: delegates query execution, filtering, and sorting to repository.
/// - Concurrency-safe: tracks request IDs to ignore stale responses.
/// - Sanitizes user-facing errors on repository failure.
class EmployeeReportCubit extends Cubit<EmployeeReportState> {
  final HrReportRepository _repository;
  int _activeRequestId = 0;

  EmployeeReportCubit({
    HrReportRepository? repository,
    EmployeeReportQuery initialQuery = const EmployeeReportQuery(),
  })  : _repository = repository ?? MockHrReportRepository(),
        super(EmployeeReportState(query: initialQuery)) {
    loadReport();
  }

  /// Loads the Employee Directory Report applying [newQuery] or existing [state.query].
  Future<void> loadReport([EmployeeReportQuery? newQuery]) async {
    final effectiveQuery = newQuery ?? state.query;
    final requestId = ++_activeRequestId;

    emit(
      state.copyWith(
        status: EmployeeReportStatus.loading,
        query: effectiveQuery,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await _repository.getEmployeeReport(effectiveQuery);

      if (requestId != _activeRequestId || isClosed) return;

      if (result.isEmpty) {
        emit(
          state.copyWith(
            status: EmployeeReportStatus.empty,
            result: result,
            query: effectiveQuery,
            clearErrorMessage: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: EmployeeReportStatus.loaded,
            result: result,
            query: effectiveQuery,
            clearErrorMessage: true,
          ),
        );
      }
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: EmployeeReportStatus.error,
          errorMessage:
              'Failed to generate Employee Directory Report. Please try again.',
        ),
      );
    }
  }

  /// Sets department filter and refreshes report.
  void setDepartment(String? department) {
    final updated = state.query.copyWith(
      department: department,
      clearDepartment: department == null || department.trim().isEmpty,
    );
    loadReport(updated);
  }

  /// Sets employment status filter and refreshes report.
  void setEmploymentStatus(EmploymentStatus? status) {
    final updated = state.query.copyWith(
      employmentStatus: status,
      clearEmploymentStatus: status == null,
    );
    loadReport(updated);
  }

  /// Sets joining date range filter and refreshes report.
  void setJoiningDateRange(ReportDateRange? range) {
    final updated = state.query.copyWith(
      joiningDateRange: range,
      clearJoiningDateRange: range == null,
    );
    loadReport(updated);
  }

  /// Sets search term filter and refreshes report.
  void setSearchTerm(String? term) {
    final updated = state.query.copyWith(
      searchTerm: term,
      clearSearchTerm: term == null || term.trim().isEmpty,
    );
    loadReport(updated);
  }

  /// Sets sorting criteria and refreshes report.
  void setSort(ReportSort sort) {
    final updated = state.query.copyWith(sort: sort);
    loadReport(updated);
  }

  /// Clears all active filters and resets to default directory view.
  void clearFilters() {
    loadReport(const EmployeeReportQuery());
  }

  /// Retries loading report with existing criteria.
  void retry() {
    loadReport(state.query);
  }
}
