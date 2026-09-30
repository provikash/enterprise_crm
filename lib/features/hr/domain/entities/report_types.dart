/// Identifies supported report categories in the Enterprise CRM HR module.
///
/// Follows HR-8.1 requirements classification:
/// - [employeeDirectory]: Confirmed for HR-8.3.
/// - [attendanceSummary]: Confirmed for HR-8.4.
/// - [kpiPerformance]: Confirmed for HR-8.5.
/// - [payrollSummary]: Confirmed for HR-8.6.
enum HrReportType {
  employeeDirectory,
  attendanceSummary,
  kpiPerformance,
  payrollSummary;

  String get displayName {
    switch (this) {
      case HrReportType.employeeDirectory:
        return 'Employee Directory';
      case HrReportType.attendanceSummary:
        return 'Attendance Summary';
      case HrReportType.kpiPerformance:
        return 'KPI Performance';
      case HrReportType.payrollSummary:
        return 'Payroll Summary';
    }
  }
}
