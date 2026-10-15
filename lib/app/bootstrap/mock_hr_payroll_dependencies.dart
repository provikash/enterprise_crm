import '../../features/hr/data/repositories/mock_attendance_repository.dart';
import '../../features/hr/data/repositories/mock_employee_document_repository.dart';
import '../../features/hr/data/repositories/mock_employee_kpi_repository.dart';
import '../../features/hr/data/repositories/mock_employee_repository.dart';
import '../../features/payroll/configuration/data/mock_payroll_configuration_repository.dart';
import '../../features/payroll/operations/data/mock_payroll_operations_repository.dart';
import 'hr_payroll_dependencies.dart';

/// The only production entry-point that assembles HR/Payroll mock data.
///
/// Replace this factory with an API-backed factory during backend integration;
/// no presentation or routing files need to change.
HrPayrollDependencies createMockHrPayrollDependencies() =>
    HrPayrollDependencies(
      employees: MockEmployeeRepository(),
      employeeDocuments: MockEmployeeDocumentRepository(),
      attendance: MockAttendanceRepository(),
      employeeKpis: MockEmployeeKpiRepository(),
      payrollConfiguration: MockPayrollConfigurationRepository(),
      payrollOperations: MockPayrollOperationsRepository(),
    );
