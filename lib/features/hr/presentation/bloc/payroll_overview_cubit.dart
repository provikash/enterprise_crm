import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'payroll_overview_state.dart';

/// Cubit managing state for the Payroll Overview screen.
///
/// Follows HR-6.5 requirements:
/// - Stably requests records by [periodId] via [PayrollRepository].
/// - Safely tracks asynchronous request IDs to prevent stale out-of-order responses.
/// - Resolves employee names via [EmployeeRepository] when available.
/// - Performs safe client-side filtering without modifying authoritative records.
/// - Strictly read-only: performs 0 client-side calculations or salary modifications.
class PayrollOverviewCubit extends Cubit<PayrollOverviewState> {
  final PayrollRepository _repository;
  final EmployeeRepository? _employeeRepository;

  int _activeRequestId = 0;
  Map<String, String> _cachedEmployeeNames = {};

  PayrollOverviewCubit({
    required PayrollRepository repository,
    EmployeeRepository? employeeRepository,
    String? initialPeriodId,
  })  : _repository = repository,
        _employeeRepository = employeeRepository,
        super(PayrollOverviewState(selectedPeriodId: initialPeriodId)) {
    if (initialPeriodId != null && initialPeriodId.trim().isNotEmpty) {
      loadRecordsForPeriod(initialPeriodId);
    }
  }

  /// Loads payroll records for the specified [periodId].
  ///
  /// Concurrency-safe: increments [_activeRequestId] to ensure that if periods
  /// are switched rapidly, only the most recently initiated query completes.
  Future<void> loadRecordsForPeriod(String periodId) async {
    final cleanId = periodId.trim();
    if (cleanId.isEmpty) return;

    final requestId = ++_activeRequestId;

    emit(
      state.copyWith(
        status: PayrollOverviewStatus.loading,
        selectedPeriodId: cleanId,
        clearErrorMessage: true,
      ),
    );

    try {
      // Resolve employees if not already cached
      if (_employeeRepository != null && _cachedEmployeeNames.isEmpty) {
        try {
          final employees = await _employeeRepository.getEmployees();
          _cachedEmployeeNames = {
            for (final emp in employees) emp.id: emp.fullName,
          };
        } catch (_) {
          // Failure to load employee names should not block payroll records display
        }
      }

      final records = await _repository.getPayrollRecordsForPeriod(cleanId);

      // Concurrency guard: ignore stale results if user switched period or cubit closed
      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollOverviewStatus.loaded,
          records: records,
          selectedPeriodId: cleanId,
          employeeNames: _cachedEmployeeNames.isNotEmpty
              ? _cachedEmployeeNames
              : state.employeeNames,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollOverviewStatus.failure,
          errorMessage: 'Failed to load payroll records for this period.',
        ),
      );
    }
  }

  /// Retries loading records for the currently selected period.
  Future<void> retry() async {
    final currentPeriodId = state.selectedPeriodId;
    if (currentPeriodId != null && currentPeriodId.trim().isNotEmpty) {
      await loadRecordsForPeriod(currentPeriodId);
    }
  }

  /// Updates the search filter query in real time.
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Clears the active search query.
  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  /// Injects an updated employee name mapping for employee ID resolution.
  void updateEmployeeNameMap(Map<String, String> names) {
    _cachedEmployeeNames = Map.from(names);
    emit(state.copyWith(employeeNames: Map.unmodifiable(names)));
  }
}
