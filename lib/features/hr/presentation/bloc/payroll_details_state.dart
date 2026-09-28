import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';

/// Status lifecycle for the Payroll Details state.
enum PayrollDetailsStatus {
  initial,
  loading,
  loaded,
  notFound,
  failure,
}

/// Immutable state for the Payroll Details Cubit.
///
/// Follows HR-6.6 architectural constraints:
/// - Stably identifies the record via [recordId].
/// - Holds the loaded [record], associated [period], and resolved [employee].
/// - Distinct [PayrollDetailsStatus.notFound] state for unknown records.
/// - Safe [errorMessage] preventing internal exception leakage.
/// - Purely read-only: contains 0 calculated values.
class PayrollDetailsState {
  final PayrollDetailsStatus status;
  final String? recordId;
  final PayrollRecord? record;
  final PayrollPeriod? period;
  final Employee? employee;
  final String? errorMessage;

  const PayrollDetailsState({
    this.status = PayrollDetailsStatus.initial,
    this.recordId,
    this.record,
    this.period,
    this.employee,
    this.errorMessage,
  });

  /// Whether the state contains a successfully loaded payroll record.
  bool get hasRecord => status == PayrollDetailsStatus.loaded && record != null;

  PayrollDetailsState copyWith({
    PayrollDetailsStatus? status,
    String? recordId,
    PayrollRecord? record,
    bool clearRecord = false,
    PayrollPeriod? period,
    bool clearPeriod = false,
    Employee? employee,
    bool clearEmployee = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollDetailsState(
      status: status ?? this.status,
      recordId: recordId ?? this.recordId,
      record: clearRecord ? null : (record ?? this.record),
      period: clearPeriod ? null : (period ?? this.period),
      employee: clearEmployee ? null : (employee ?? this.employee),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollDetailsState &&
        other.status == status &&
        other.recordId == recordId &&
        other.record == record &&
        other.period == period &&
        other.employee == employee &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        recordId,
        record,
        period,
        employee,
        errorMessage,
      );

  @override
  String toString() =>
      'PayrollDetailsState(status: $status, recordId: $recordId, hasRecord: $hasRecord)';
}
