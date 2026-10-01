import '../entities/attendance_report_query.dart';
import '../entities/attendance_report_row.dart';
import '../entities/employee_report_query.dart';
import '../entities/employee_report_row.dart';
import '../entities/kpi_report_query.dart';
import '../entities/kpi_report_row.dart';
import '../entities/payroll_report_query.dart';
import '../entities/payroll_report_row.dart';
import '../entities/report_result.dart';

/// Abstract domain repository interface for HR and Payroll reporting queries.
///
/// Follows HR-8.2 architectural boundaries:
/// - Presentation layers interact exclusively through this contract.
/// - Encapsulates data fetching, query execution, and authorization checks.
/// - Read-only: zero mutating or export side-effects.
abstract interface class HrReportRepository {
  /// Evaluates and returns the Employee Directory Report matching [query].
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(
    EmployeeReportQuery query,
  );

  /// Evaluates and returns the Attendance Summary Report matching [query].
  Future<ReportResult<AttendanceReportRow>> getAttendanceReport(
    AttendanceReportQuery query,
  );

  /// Evaluates and returns the KPI Performance Report matching [query].
  Future<ReportResult<KpiReportRow>> getKpiReport(
    KpiReportQuery query,
  );

  /// Evaluates and returns the Payroll Summary Report matching [query].
  Future<ReportResult<PayrollReportRow>> getPayrollReport(
    PayrollReportQuery query,
  );
}

/// Operational domain exception for reporting failures.
class ReportException implements Exception {
  final String message;

  const ReportException(this.message);

  @override
  String toString() => message;
}
