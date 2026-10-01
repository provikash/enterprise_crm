import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/mock_hr_report_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/payroll_report_query.dart';
import '../../domain/entities/payroll_report_summary.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'payroll_report_state.dart';

/// Cubit managing lifecycle, filters, and evaluation for Payroll Summary Reports.
///
/// Follows HR-8.6 architectural requirements:
/// - Repository-injected; widgets do not query domain or repositories directly.
/// - Concurrent and stale query race-condition protection via [_activeRequestId].
/// - Sanitized user-facing error feedback.
/// - Strictly read-only: displays stored compensation values with currency grouping;
///   zero client-side calculations or statutory payroll formulas.
class PayrollReportCubit extends Cubit<PayrollReportState> {
  final HrReportRepository _reportRepository;
  final PayrollRepository _payrollRepository;
  int _activeRequestId = 0;

  PayrollReportCubit({
    HrReportRepository? reportRepository,
    PayrollRepository? payrollRepository,
    PayrollReportQuery initialQuery = PayrollReportQuery.defaultQuery,
  })  : _reportRepository = reportRepository ?? MockHrReportRepository(),
        _payrollRepository = payrollRepository ?? MockPayrollRepository(),
        super(PayrollReportState(query: initialQuery)) {
    loadInitial();
  }

  /// Initial load: fetches approved payroll periods and runs initial query.
  Future<void> loadInitial() async {
    try {
      final periods = await _payrollRepository.getPayrollPeriods();
      if (isClosed) return;
      emit(state.copyWith(periods: periods));
    } catch (_) {
      // Gracefully continue even if period listing fails; query will still execute
    }
    await loadReport();
  }

  /// Executes the payroll summary report query using current or provided [query].
  Future<void> loadReport({
    PayrollReportQuery? query,
  }) async {
    final effectiveQuery = query ?? state.query;
    final requestId = ++_activeRequestId;

    emit(state.copyWith(
      status: PayrollReportStatus.loading,
      query: effectiveQuery,
      clearError: true,
    ));

    try {
      final result = await _reportRepository.getPayrollReport(effectiveQuery);

      if (requestId != _activeRequestId || isClosed) return;

      final summary = (result.metadata?['summary'] as PayrollReportSummary?) ??
          PayrollReportSummary.fromRows(result.rows);

      if (result.rows.isEmpty) {
        emit(state.copyWith(
          status: PayrollReportStatus.empty,
          result: result,
          summary: summary,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: PayrollReportStatus.loaded,
          result: result,
          summary: summary,
          clearError: true,
        ));
      }
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(state.copyWith(
        status: PayrollReportStatus.failure,
        errorMessage:
            'Failed to generate Payroll Summary Report. Please try again.',
      ));
    }
  }

  /// Updates the payroll period filter and re-evaluates the report.
  Future<void> setPeriodFilter(String? periodId) async {
    final isAll = periodId == null || periodId.isEmpty || periodId == 'All';
    final newQuery = state.query.copyWith(
      payrollPeriodId: isAll ? null : periodId,
      clearPayrollPeriodId: isAll,
    );
    await loadReport(query: newQuery);
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

  /// Updates the payment status filter ('Paid', 'Pending', 'Processing', or 'All').
  Future<void> setPaymentStatusFilter(String? status) async {
    final isAll = status == null || status.isEmpty || status == 'All';
    final newQuery = state.query.copyWith(
      paymentStatus: isAll ? null : status,
      clearPaymentStatus: isAll,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the currency filter ('USD', 'INR', or 'All').
  Future<void> setCurrencyFilter(String? currency) async {
    final isAll = currency == null || currency.isEmpty || currency == 'All';
    final newQuery = state.query.copyWith(
      currency: isAll ? null : currency,
      clearCurrency: isAll,
    );
    await loadReport(query: newQuery);
  }

  /// Updates the search term (matches employee name, employee code, or record ID).
  Future<void> setSearchTerm(String term) async {
    final trimmed = term.trim();
    final newQuery = state.query.copyWith(
      searchTerm: trimmed,
      clearSearchTerm: trimmed.isEmpty,
    );
    await loadReport(query: newQuery);
  }

  /// Sets sorting criteria and re-evaluates the report.
  Future<void> setSort(ReportSort sort) async {
    final newQuery = state.query.copyWith(sort: sort);
    await loadReport(query: newQuery);
  }

  /// Resets all active filters back to the default query.
  Future<void> resetFilters() async {
    await loadReport(query: PayrollReportQuery.defaultQuery);
  }

  /// Retries the current query after failure.
  Future<void> retry() async {
    await loadReport();
  }
}
