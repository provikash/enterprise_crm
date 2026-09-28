import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'payroll_details_state.dart';

/// Cubit managing state for the Payroll Details screen.
///
/// Follows HR-6.6 requirements:
/// - Stably requests a single record by [id] via [PayrollRepository].
/// - Resolves associated [PayrollPeriod] and [Employee] relationships.
/// - Concurrency-safe: tracks request IDs to prevent stale responses.
/// - Emits [PayrollDetailsStatus.notFound] when the record does not exist.
/// - Read-only: 0 client-side calculations or salary modifications.
class PayrollDetailsCubit extends Cubit<PayrollDetailsState> {
  final PayrollRepository _repository;
  final EmployeeRepository? _employeeRepository;

  int _activeRequestId = 0;

  PayrollDetailsCubit({
    required PayrollRepository repository,
    EmployeeRepository? employeeRepository,
    String? initialRecordId,
  })  : _repository = repository,
        _employeeRepository = employeeRepository,
        super(PayrollDetailsState(recordId: initialRecordId)) {
    if (initialRecordId != null && initialRecordId.trim().isNotEmpty) {
      loadRecord(initialRecordId);
    }
  }

  /// Loads the payroll record with the specified [id].
  Future<void> loadRecord(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    final requestId = ++_activeRequestId;

    emit(
      state.copyWith(
        status: PayrollDetailsStatus.loading,
        recordId: cleanId,
        clearErrorMessage: true,
      ),
    );

    try {
      final record = await _repository.getPayrollRecordById(cleanId);

      if (requestId != _activeRequestId || isClosed) return;

      if (record == null) {
        emit(
          state.copyWith(
            status: PayrollDetailsStatus.notFound,
            recordId: cleanId,
            clearRecord: true,
            clearPeriod: true,
            clearEmployee: true,
          ),
        );
        return;
      }

      PayrollPeriod? period;
      try {
        period = await _repository.getPayrollPeriodById(record.payrollPeriodId);
      } catch (_) {
        // Failing to resolve period metadata should not block the record itself
      }

      Employee? employee;
      if (_employeeRepository != null) {
        try {
          employee = await _employeeRepository.getEmployeeById(record.employeeId);
        } catch (_) {
          // Failing to resolve employee should not block the record itself
        }
      }

      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollDetailsStatus.loaded,
          recordId: cleanId,
          record: record,
          period: period,
          employee: employee,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollDetailsStatus.failure,
          recordId: cleanId,
          errorMessage: 'Failed to load payroll record details.',
        ),
      );
    }
  }

  /// Retries loading the current record.
  Future<void> retry() async {
    final currentId = state.recordId;
    if (currentId != null && currentId.trim().isNotEmpty) {
      await loadRecord(currentId);
    }
  }
}
