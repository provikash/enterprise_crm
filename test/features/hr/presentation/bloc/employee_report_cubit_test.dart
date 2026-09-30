import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_date_range.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_sort.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplosiveReportRepository implements HrReportRepository {
  @override
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(EmployeeReportQuery query) async {
    throw Exception('DATABASE_CRASH');
  }
}

void main() {
  group('EmployeeReportCubit Unit Tests (HR-8.3)', () {
    late MockEmployeeRepository employeeRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      reportRepo = MockHrReportRepository(employeeRepository: employeeRepo);
    });

    test('initializes and immediately loads default employee directory report', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      expect(cubit.state.status, equals(EmployeeReportStatus.loading));

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(EmployeeReportStatus.loaded));
      expect(cubit.state.totalCount, equals(5));
      expect(cubit.state.rows.length, equals(5));
      expect(cubit.state.errorMessage, isNull);

      cubit.close();
    });

    test('setDepartment updates query and filters matching rows', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setDepartment('Human Resources');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.query.department, equals('Human Resources'));
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.rows.first.fullName, equals('Alice Johnson'));

      cubit.close();
    });

    test('setEmploymentStatus filters matching rows accurately', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setEmploymentStatus(EmploymentStatus.inactive);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.rows.first.fullName, equals('Evan Wright'));

      cubit.close();
    });

    test('setJoiningDateRange filters records within date boundaries', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setJoiningDateRange(
        ReportDateRange(start: DateTime(2025, 1, 1), end: DateTime(2025, 12, 31)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Dana White joined 2025-11-20
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.rows.first.fullName, equals('Dana White'));

      cubit.close();
    });

    test('setSearchTerm filters by name or code and sets empty status when no match', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setSearchTerm('non_existent_search');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(EmployeeReportStatus.empty));
      expect(cubit.state.totalCount, equals(0));
      expect(cubit.state.rows, isEmpty);

      // Clearing search restores loaded state
      cubit.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(EmployeeReportStatus.loaded));
      expect(cubit.state.totalCount, equals(5));

      cubit.close();
    });

    test('setSort applies sort criteria', () async {
      final cubit = EmployeeReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      cubit.setSort(
        const ReportSort(field: 'fullName', direction: ReportSortDirection.descending),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.rows.first.fullName, equals('Evan Wright'));
      expect(cubit.state.rows.last.fullName, equals('Alice Johnson'));

      cubit.close();
    });

    test('repository failure emits error status with sanitized message and retry recovers', () async {
      final cubit = EmployeeReportCubit(repository: _ExplosiveReportRepository());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(EmployeeReportStatus.error));
      expect(cubit.state.errorMessage, contains('Failed to generate Employee Directory Report'));
      expect(cubit.state.errorMessage, isNot(contains('DATABASE_CRASH')));

      cubit.close();
    });
  });
}
