import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'attendance_repository_factory.dart';
import 'employee_kpi_repository_factory.dart';
import 'employee_repository_factory.dart';
import 'mock_hr_report_repository.dart';
import 'payroll_repository_factory.dart';

/// Factory for instantiating the appropriate [HrReportRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.9 to govern reporting query execution over either deterministic
/// mock repositories or live backend adapters.
///
/// Invariants:
/// - In backend mode, delegates report aggregation to backend-backed domain repositories.
/// - In mock mode, delegates to deterministic in-memory mock repositories.
/// - Never performs silent fallback to mock data on backend query failures.
class HrReportRepositoryFactory {
  static HrReportRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    EmployeeRepository? employeeRepository,
    AttendanceRepository? attendanceRepository,
    EmployeeKpiRepository? kpiRepository,
    PayrollRepository? payrollRepository,
  }) {
    final effectiveEmpRepo = employeeRepository ??
        EmployeeRepositoryFactory.create(
          config: config,
          apiClient: apiClient,
        );
    final effectiveAttRepo = attendanceRepository ??
        AttendanceRepositoryFactory.create(
          config: config,
          apiClient: apiClient,
        );
    final effectiveKpiRepo = kpiRepository ??
        EmployeeKpiRepositoryFactory.create(
          config: config,
          apiClient: apiClient,
        );
    final effectivePayrollRepo = payrollRepository ??
        PayrollRepositoryFactory.create(
          config: config,
          apiClient: apiClient,
        );

    return MockHrReportRepository(
      employeeRepository: effectiveEmpRepo,
      attendanceRepository: effectiveAttRepo,
      kpiRepository: effectiveKpiRepo,
      payrollRepository: effectivePayrollRepo,
    );
  }
}
