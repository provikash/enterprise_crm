import '../entities/payroll_period.dart';
import '../entities/payroll_record.dart';

/// Abstract domain repository interface for HR Payroll management.
///
/// Follows pure repository patterns established across the Enterprise CRM.
/// Presentation Cubits and future UI screens depend exclusively on this abstraction.
///
/// Strictly read-only for HR-6:
/// - Retrieval of payroll periods.
/// - Retrieval of payroll records by period and/or employee.
/// - Retrieval of individual records and periods by ID.
/// - No mutation methods, calculation logic, or processing routines.
abstract interface class PayrollRepository {
  /// Retrieves all approved payroll periods in deterministic order.
  Future<List<PayrollPeriod>> getPayrollPeriods();

  /// Retrieves an individual payroll period by its unique [id], or `null` if not found.
  Future<PayrollPeriod?> getPayrollPeriodById(String id);

  /// Retrieves payroll records, optionally filtered by [payrollPeriodId] and/or [employeeId].
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  });

  /// Retrieves all payroll records for an approved [periodId].
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId);

  /// Retrieves all payroll records associated with a specific [employeeId].
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId);

  /// Retrieves an individual payroll record by its unique [id], or `null` if not found.
  Future<PayrollRecord?> getPayrollRecordById(String id);
}

/// Domain exception thrown when a payroll repository operation fails.
class PayrollException implements Exception {
  final String message;
  final String? code;

  const PayrollException(this.message, {this.code});

  @override
  String toString() =>
      'PayrollException: $message${code != null ? ' (code: $code)' : ''}';
}
