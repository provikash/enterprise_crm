import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';

/// Status lifecycle for the Employee Payroll History state.
enum EmployeePayrollHistoryStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

/// Immutable state for the Employee Payroll History Cubit.
///
/// Follows HR-6.7 architectural constraints:
/// - Stably tracks the queried [employeeId].
/// - Holds the loaded [records] for the employee and a map of [periods] for period label resolution.
/// - Concurrency-safe: clear distinction between initial, loading, loaded, empty, and error states.
/// - Safe error handling: [errorMessage] prevents internal exception leakage.
/// - Purely read-only: contains 0 client-side calculations or salary modifications.
class EmployeePayrollHistoryState {
  final EmployeePayrollHistoryStatus status;
  final String? employeeId;
  final List<PayrollRecord> records;
  final Map<String, PayrollPeriod> periods;
  final String? errorMessage;

  const EmployeePayrollHistoryState({
    this.status = EmployeePayrollHistoryStatus.initial,
    this.employeeId,
    this.records = const [],
    this.periods = const {},
    this.errorMessage,
  });

  bool get isLoading => status == EmployeePayrollHistoryStatus.loading;
  bool get isLoaded => status == EmployeePayrollHistoryStatus.loaded;
  bool get isEmpty => status == EmployeePayrollHistoryStatus.empty;
  bool get isError => status == EmployeePayrollHistoryStatus.error;

  EmployeePayrollHistoryState copyWith({
    EmployeePayrollHistoryStatus? status,
    String? employeeId,
    List<PayrollRecord>? records,
    Map<String, PayrollPeriod>? periods,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EmployeePayrollHistoryState(
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      records: records ?? this.records,
      periods: periods ?? this.periods,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (other is! EmployeePayrollHistoryState) return false;

    if (other.status != status ||
        other.employeeId != employeeId ||
        other.errorMessage != errorMessage ||
        other.records.length != records.length ||
        other.periods.length != periods.length) {
      return false;
    }

    for (var i = 0; i < records.length; i++) {
      if (records[i] != other.records[i]) return false;
    }

    for (final entry in periods.entries) {
      if (other.periods[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    status,
    employeeId,
    Object.hashAll(records),
    Object.hashAll(periods.entries),
    errorMessage,
  );

  @override
  String toString() =>
      'EmployeePayrollHistoryState(status: $status, employeeId: $employeeId, records: ${records.length}, periods: ${periods.length}, error: $errorMessage)';
}
