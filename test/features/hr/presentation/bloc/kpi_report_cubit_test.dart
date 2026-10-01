import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_date_range.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_sort.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/kpi_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/kpi_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplodingReportRepository implements HrReportRepository {
  bool shouldThrow = true;
  final HrReportRepository _fallback = MockHrReportRepository(
    employeeRepository: MockEmployeeRepository(),
    attendanceRepository: MockAttendanceRepository(),
    kpiRepository: MockEmployeeKpiRepository(),
  );

  @override
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(
    EmployeeReportQuery query,
  ) {
    return _fallback.getEmployeeReport(query);
  }

  @override
  Future<ReportResult<AttendanceReportRow>> getAttendanceReport(
    AttendanceReportQuery query,
  ) {
    return _fallback.getAttendanceReport(query);
  }

  @override
  Future<ReportResult<KpiReportRow>> getKpiReport(
    KpiReportQuery query,
  ) async {
    if (shouldThrow) {
      throw Exception('Simulated fatal database connection failure');
    }
    return _fallback.getKpiReport(query);
  }
}

void main() {
  group('KpiReportCubit Tests (HR-8.5)', () {
    late MockEmployeeRepository employeeRepo;
    late MockEmployeeKpiRepository kpiRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      kpiRepo = MockEmployeeKpiRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        kpiRepository: kpiRepo,
      );
    });

    test('initializes and immediately loads default KPI report', () async {
      final cubit = KpiReportCubit(repository: reportRepo);
      expect(cubit.state.status, equals(KpiReportStatus.loading));

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(KpiReportStatus.loaded));
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.summary, isNotNull);
      expect(cubit.state.rows, isNotEmpty);
      expect(cubit.state.summary!.totalRecords, equals(cubit.state.rows.length));

      cubit.close();
    });

    test('loadReport transitions to empty when zero records match query', () async {
      final cubit = KpiReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.loadReport(
        query: const KpiReportQuery(employeeId: 'non_existent_emp'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(KpiReportStatus.empty));
      expect(cubit.state.rows, isEmpty);
      expect(cubit.state.summary!.totalRecords, equals(0));

      cubit.close();
    });

    test('loadReport transitions to failure on error and retry recovers', () async {
      final explodingRepo = _ExplodingReportRepository();
      final failingCubit = KpiReportCubit(repository: explodingRepo);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(failingCubit.state.status, equals(KpiReportStatus.failure));
      expect(
        failingCubit.state.errorMessage,
        equals('Failed to generate KPI Performance Report. Please try again.'),
      );

      // Disable error and retry
      explodingRepo.shouldThrow = false;
      await failingCubit.retry();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(failingCubit.state.status, equals(KpiReportStatus.loaded));
      expect(failingCubit.state.rows, isNotEmpty);

      failingCubit.close();
    });

    test('filter methods update query and re-evaluate report correctly', () async {
      final cubit = KpiReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.setEmployeeFilter('emp_1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.employeeId, equals('emp_1'));
      expect(cubit.state.rows.every((r) => r.employeeId == 'emp_1'), isTrue);

      await cubit.setMetricFilter('Employee Retention Rate');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.metricName, equals('Employee Retention Rate'));
      expect(cubit.state.rows.every((r) => r.metricName == 'Employee Retention Rate'), isTrue);

      final range = ReportDateRange(
        start: DateTime.utc(2026, 7, 1),
        end: DateTime.utc(2026, 9, 30),
      );
      await cubit.setDateRangeFilter(range);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.dateRange, equals(range));

      await cubit.setSearchTerm('Retention');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.searchTerm, equals('Retention'));

      await cubit.setSort(const ReportSort(field: 'metricName', direction: ReportSortDirection.descending));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.sort?.field, equals('metricName'));

      // Clear filters resets back to default
      await cubit.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query, equals(KpiReportQuery.defaultQuery));
      expect(cubit.state.status, equals(KpiReportStatus.loaded));

      cubit.close();
    });

    test('rapid query updates discard stale asynchronous results', () async {
      final cubit = KpiReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setEmployeeFilter('emp_1');
      cubit.setEmployeeFilter('emp_2');
      await cubit.setEmployeeFilter('emp_3');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.query.employeeId, equals('emp_3'));
      expect(cubit.state.rows.every((r) => r.employeeId == 'emp_3'), isTrue);

      cubit.close();
    });
  });
}
