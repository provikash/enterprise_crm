import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_sort.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplodingReportRepository implements HrReportRepository {
  bool shouldThrow = true;
  final HrReportRepository _fallback = MockHrReportRepository();

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
  ) {
    return _fallback.getKpiReport(query);
  }

  @override
  Future<ReportResult<PayrollReportRow>> getPayrollReport(
    PayrollReportQuery query,
  ) async {
    if (shouldThrow) {
      throw Exception('Simulated fatal database connection failure');
    }
    return _fallback.getPayrollReport(query);
  }
}

void main() {
  group('PayrollReportCubit Tests (HR-8.6)', () {
    late MockEmployeeRepository employeeRepo;
    late MockPayrollRepository payrollRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      payrollRepo = MockPayrollRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
      );
    });

    test('initializes and immediately loads periods and default payroll report', () async {
      final cubit = PayrollReportCubit(
        reportRepository: reportRepo,
        payrollRepository: payrollRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, equals(PayrollReportStatus.loaded));
      expect(cubit.state.totalCount, equals(5));
      expect(cubit.state.periods.length, equals(3));
      expect(cubit.state.summary, isNotNull);
      expect(cubit.state.summary!.totalRecords, equals(5));

      await cubit.close();
    });

    test('loadReport transitions to empty when zero records match query', () async {
      final cubit = PayrollReportCubit(
        reportRepository: reportRepo,
        payrollRepository: payrollRepo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.loadReport(
        query: const PayrollReportQuery(payrollPeriodId: 'period_2026_03'),
      );

      expect(cubit.state.status, equals(PayrollReportStatus.empty));
      expect(cubit.state.totalCount, equals(0));
      expect(cubit.state.summary?.totalRecords, equals(0));

      await cubit.close();
    });

    test('loadReport transitions to failure on error and retry recovers', () async {
      final explosiveRepo = _ExplodingReportRepository();
      final cubit = PayrollReportCubit(
        reportRepository: explosiveRepo,
        payrollRepository: payrollRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, equals(PayrollReportStatus.failure));
      expect(
        cubit.state.errorMessage,
        equals('Failed to generate Payroll Summary Report. Please try again.'),
      );

      // Disable simulated failure and retry
      explosiveRepo.shouldThrow = false;
      await cubit.retry();

      expect(cubit.state.status, equals(PayrollReportStatus.loaded));
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
    });

    test('filter methods update query and re-evaluate report correctly', () async {
      final cubit = PayrollReportCubit(
        reportRepository: reportRepo,
        payrollRepository: payrollRepo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 1. Period filter
      await cubit.setPeriodFilter('period_2026_01');
      expect(cubit.state.query.payrollPeriodId, equals('period_2026_01'));
      expect(cubit.state.totalCount, equals(3));

      // 2. Employee filter
      await cubit.setEmployeeFilter('emp_1');
      expect(cubit.state.query.employeeId, equals('emp_1'));
      expect(cubit.state.totalCount, equals(1));

      // 3. Search term filter
      await cubit.setSearchTerm('Alice');
      expect(cubit.state.query.searchTerm, equals('Alice'));
      expect(cubit.state.totalCount, equals(1));

      // 4. Payment status filter
      await cubit.setPaymentStatusFilter('Paid');
      expect(cubit.state.query.paymentStatus, equals('Paid'));
      expect(cubit.state.totalCount, equals(1));

      // 5. Currency filter
      await cubit.setCurrencyFilter('USD');
      expect(cubit.state.query.currency, equals('USD'));
      expect(cubit.state.totalCount, equals(1));

      // 6. Sort
      await cubit.setSort(const ReportSort(
        field: 'grossSalary',
        direction: ReportSortDirection.descending,
      ));
      expect(cubit.state.query.sort?.field, equals('grossSalary'));

      // 7. Reset filters
      await cubit.resetFilters();
      expect(cubit.state.query.hasActiveFilters, isFalse);
      expect(cubit.state.totalCount, equals(5));

      await cubit.close();
    });

    test('rapid query updates discard stale asynchronous results', () async {
      final cubit = PayrollReportCubit(
        reportRepository: reportRepo,
        payrollRepository: payrollRepo,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Fire queries rapidly without awaiting
      cubit.setPeriodFilter('period_2026_01');
      cubit.setPeriodFilter('period_2026_02');
      final lastOp = cubit.setPeriodFilter('period_2026_01');

      await lastOp;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // State must correspond to the final query
      expect(cubit.state.query.payrollPeriodId, equals('period_2026_01'));
      expect(cubit.state.totalCount, equals(3));

      await cubit.close();
    });
  });
}
