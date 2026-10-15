import '../../features/hr/domain/repositories/attendance_repository.dart';
import '../../features/hr/domain/repositories/employee_document_repository.dart';
import '../../features/hr/domain/repositories/employee_kpi_repository.dart';
import '../../features/hr/domain/repositories/employee_repository.dart';
import '../../features/payroll/configuration/domain/payroll_configuration_repository.dart';
import '../../features/payroll/operations/domain/payroll_operations_repository.dart';

/// Repository boundary for the HR and Payroll modules.
///
/// The application and presentation layers depend only on these contracts.
/// A mock or API bootstrap can construct this bundle without changing screens,
/// routes, or business-state classes.
class HrPayrollDependencies {
  final EmployeeRepository employees;
  final EmployeeDocumentRepository employeeDocuments;
  final AttendanceRepository attendance;
  final EmployeeKpiRepository employeeKpis;
  final PayrollConfigurationRepository payrollConfiguration;
  final PayrollOperationsRepository payrollOperations;

  const HrPayrollDependencies({
    required this.employees,
    required this.employeeDocuments,
    required this.attendance,
    required this.employeeKpis,
    required this.payrollConfiguration,
    required this.payrollOperations,
  });
}
