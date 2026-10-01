import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_date_range.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_report_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_report_state.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/kpi_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HR-8.7 Cross-Report Filters, Periods & Summaries Integration Tests', () {
    late MockEmployeeRepository employeeRepo;
    late MockAttendanceRepository attendanceRepo;
    late MockEmployeeKpiRepository kpiRepo;
    late MockPayrollRepository payrollRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      attendanceRepo = MockAttendanceRepository();
      kpiRepo = MockEmployeeKpiRepository();
      payrollRepo = MockPayrollRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        attendanceRepository: attendanceRepo,
        kpiRepository: kpiRepo,
        payrollRepository: payrollRepo,
      );
    });

    group('1. Query Filter Contract & Alias Standardization', () {
      test('all 4 report queries provide hasFilters and hasActiveFilters equivalently', () {
        const empQ = EmployeeReportQuery();
        expect(empQ.hasFilters, isFalse);
        expect(empQ.hasActiveFilters, isFalse);
        final filteredEmpQ = empQ.copyWith(department: 'Engineering');
        expect(filteredEmpQ.hasFilters, isTrue);
        expect(filteredEmpQ.hasActiveFilters, isTrue);

        const attQ = AttendanceReportQuery.defaultQuery;
        expect(attQ.hasFilters, isFalse);
        expect(attQ.hasActiveFilters, isFalse);
        final filteredAttQ = attQ.copyWith(status: 'Present');
        expect(filteredAttQ.hasFilters, isTrue);
        expect(filteredAttQ.hasActiveFilters, isTrue);

        const kpiQ = KpiReportQuery.defaultQuery;
        expect(kpiQ.hasFilters, isFalse);
        expect(kpiQ.hasActiveFilters, isFalse);
        final filteredKpiQ = kpiQ.copyWith(employeeId: 'emp_1');
        expect(filteredKpiQ.hasFilters, isTrue);
        expect(filteredKpiQ.hasActiveFilters, isTrue);

        const payQ = PayrollReportQuery.defaultQuery;
        expect(payQ.hasFilters, isFalse);
        expect(payQ.hasActiveFilters, isFalse);
        final filteredPayQ = payQ.copyWith(payrollPeriodId: 'period_2026_09');
        expect(filteredPayQ.hasFilters, isTrue);
        expect(filteredPayQ.hasActiveFilters, isTrue);
      });

      test('all 4 report cubits support both clearFilters() and resetFilters() aliases', () async {
        final empCubit = EmployeeReportCubit(repository: reportRepo);
        final attCubit = AttendanceReportCubit(repository: reportRepo);
        final kpiCubit = KpiReportCubit(repository: reportRepo);
        final payCubit = PayrollReportCubit(repository: reportRepo);

        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Employee
        empCubit.setDepartment('Engineering');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(empCubit.state.query.department, equals('Engineering'));
        empCubit.resetFilters();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(empCubit.state.query.hasActiveFilters, isFalse);

        // Attendance
        await attCubit.setStatusFilter('Present');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(attCubit.state.query.status, equals('Present'));
        await attCubit.resetFilters();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(attCubit.state.query.hasActiveFilters, isFalse);

        // KPI
        await kpiCubit.setEmployeeFilter('emp_1');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(kpiCubit.state.query.employeeId, equals('emp_1'));
        await kpiCubit.resetFilters();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(kpiCubit.state.query.hasActiveFilters, isFalse);

        // Payroll
        await payCubit.setPeriodFilter('period_2026_09');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(payCubit.state.query.payrollPeriodId, equals('period_2026_09'));
        await payCubit.clearFilters();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(payCubit.state.query.hasActiveFilters, isFalse);

        empCubit.close();
        attCubit.close();
        kpiCubit.close();
        payCubit.close();
      });
    });

    group('2. Combined Filter Intersection (AND Semantics)', () {
      test('Employee report intersects department and status filters', () async {
        final cubit = EmployeeReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        cubit.setDepartment('Finance & Accounts');
        cubit.setEmploymentStatus(EmploymentStatus.inactive);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Evan Wright is Inactive and in Finance & Accounts
        expect(cubit.state.status, equals(EmployeeReportStatus.loaded));
        expect(cubit.state.totalCount, equals(1));
        expect(cubit.state.rows.first.fullName, equals('Evan Wright'));

        cubit.close();
      });

      test('Attendance report intersects employee ID and attendance status', () async {
        final cubit = AttendanceReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await cubit.setEmployeeFilter('emp_1');
        await cubit.setStatusFilter('Present');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cubit.state.status, equals(AttendanceReportStatus.loaded));
        for (final row in cubit.state.rows) {
          expect(row.employeeId, equals('emp_1'));
          expect(row.attendanceStatus, equals('Present'));
        }

        cubit.close();
      });

      test('Payroll report intersects payroll period and payment status', () async {
        final cubit = PayrollReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await cubit.setPeriodFilter('period_2026_01');
        await cubit.setPaymentStatusFilter('Paid');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cubit.state.status, equals(PayrollReportStatus.loaded));
        for (final row in cubit.state.rows) {
          expect(row.payrollPeriodId, equals('period_2026_01'));
          expect(row.paymentStatus, equals('Paid'));
        }

        cubit.close();
      });
    });

    group('3. Period & Date Range Domain Separation', () {
      test('ReportDateRange enforces inclusive start and end boundaries for attendance', () async {
        final range = ReportDateRange(
          start: DateTime.utc(2026, 9, 21),
          end: DateTime.utc(2026, 9, 22),
        );
        final result = await reportRepo.getAttendanceReport(
          AttendanceReportQuery(dateRange: range),
        );

        for (final row in result.rows) {
          expect(
            row.attendanceDate.isBefore(range.start) || row.attendanceDate.isAfter(range.end),
            isFalse,
          );
        }
      });

      test('PayrollPeriod retains discrete entity identity and does not collapse into date range', () async {
        final result = await reportRepo.getPayrollReport(
          const PayrollReportQuery(payrollPeriodId: 'period_2026_01'),
        );

        expect(result.rows, isNotEmpty);
        for (final row in result.rows) {
          expect(row.payrollPeriodId, equals('period_2026_01'));
          expect(row.periodName, isNotEmpty);
        }
      });
    });

    group('4. Stale Asynchronous Request Protection', () {
      test('rapid filter updates discard intermediate and out-of-order queries', () async {
        final cubit = PayrollReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Fire multiple rapid updates
        cubit.setPeriodFilter('period_2026_02');
        cubit.setPeriodFilter('period_2026_01');
        await cubit.setPeriodFilter('period_2026_01');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cubit.state.query.payrollPeriodId, equals('period_2026_01'));
        for (final row in cubit.state.rows) {
          expect(row.payrollPeriodId, equals('period_2026_01'));
        }

        cubit.close();
      });
    });

    group('5. Summary Calculation Integrity & Currency Safety', () {
      test('Payroll summaries are strictly grouped by currency without cross-currency addition', () async {
        final cubit = PayrollReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final summary = cubit.state.summary;
        expect(summary, isNotNull);
        expect(summary!.totalRecords, equals(cubit.state.rows.length));

        // Verify each currency total only aggregates amounts matching that currency
        for (final curSummary in summary.currencySummaries.values) {
          final matchingRows = cubit.state.rows.where((r) => r.currency == curSummary.currency);
          final expectedGross = matchingRows.fold<double>(
            0.0,
            (sum, r) => sum + (r.grossSalary ?? 0.0),
          );
          final expectedNet = matchingRows.fold<double>(
            0.0,
            (sum, r) => sum + (r.netSalary ?? 0.0),
          );
          expect(curSummary.totalGross, closeTo(expectedGross, 0.001));
          expect(curSummary.totalNet, closeTo(expectedNet, 0.001));
        }

        cubit.close();
      });

      test('Summaries reflect exact filtered subset and update dynamically on filter change', () async {
        final cubit = AttendanceReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final initialTotal = cubit.state.summary!.totalRecords;
        expect(initialTotal, greaterThan(0));

        await cubit.setStatusFilter('Present');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final filteredSummary = cubit.state.summary!;
        expect(filteredSummary.totalRecords, equals(cubit.state.rows.length));
        expect(filteredSummary.presentCount, equals(cubit.state.rows.length));
        expect(filteredSummary.absentCount, equals(0));

        cubit.close();
      });

      test('Empty query returns zero summary records without fabricating values', () async {
        final cubit = PayrollReportCubit(repository: reportRepo);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        await cubit.loadReport(
          query: const PayrollReportQuery(employeeId: 'non_existent_employee_xyz'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cubit.state.status, equals(PayrollReportStatus.empty));
        expect(cubit.state.rows, isEmpty);
        expect(cubit.state.summary!.totalRecords, equals(0));
        expect(cubit.state.summary!.currencySummaries, isEmpty);

        cubit.close();
      });
    });
  });
}
