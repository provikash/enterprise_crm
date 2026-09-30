import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_date_range.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_sort.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HR-8.2: Report Domain & Value Objects Tests', () {
    test('HrReportType enum defines approved report types with display names', () {
      expect(HrReportType.values.length, equals(4));
      expect(HrReportType.employeeDirectory.displayName, equals('Employee Directory'));
      expect(HrReportType.attendanceSummary.displayName, equals('Attendance Summary'));
      expect(HrReportType.kpiPerformance.displayName, equals('KPI Performance'));
      expect(HrReportType.payrollSummary.displayName, equals('Payroll Summary'));
    });

    test('ReportDateRange enforces start <= end and normalizes to UTC boundaries', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      final range = ReportDateRange(start: start, end: end);

      expect(range.start, equals(DateTime.utc(2026, 1, 1)));
      expect(range.end, equals(DateTime.utc(2026, 1, 31, 23, 59, 59, 999)));

      // Boundary tests
      expect(range.contains(DateTime.utc(2026, 1, 15)), isTrue);
      expect(range.contains(DateTime.utc(2026, 1, 1, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime.utc(2026, 1, 31, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime.utc(2025, 12, 31)), isFalse);
      expect(range.contains(DateTime.utc(2026, 2, 1)), isFalse);

      // Invalid range
      expect(
        () => ReportDateRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 1, 1)),
        throwsArgumentError,
      );
    });

    test('ReportSort supports direction toggling, equality and hashCode', () {
      const sortAsc = ReportSort(field: 'fullName');
      expect(sortAsc.direction.isAscending, isTrue);

      final sortDesc = sortAsc.toggleDirection();
      expect(sortDesc.direction.isDescending, isTrue);
      expect(sortDesc.field, equals('fullName'));

      const sort2 = ReportSort(field: 'fullName');
      expect(sortAsc, equals(sort2));
      expect(sortAsc.hashCode, equals(sort2.hashCode));
    });

    test('ReportResult provides unmodifiable row collection and metadata', () {
      final row = const EmployeeReportRow(
        id: 'emp_1',
        fullName: 'Alice Johnson',
      );
      final result = ReportResult<EmployeeReportRow>(
        rows: [row],
      );

      expect(result.totalCount, equals(1));
      expect(result.isNotEmpty, isTrue);
      expect(result.isEmpty, isFalse);
      expect(
        () => (result.rows as dynamic).add(const EmployeeReportRow(id: 'emp_2', fullName: 'Bob')),
        throwsUnsupportedError,
      );
    });

    test('EmployeeReportRow maps faithfully from Employee and enforces privacy', () {
      final emp = Employee(
        id: 'emp_test_1',
        employeeCode: 'EMP-999',
        fullName: 'Jane Doe',
        department: 'Engineering',
        designation: 'Staff Engineer',
        employmentStatus: EmploymentStatus.active,
        joiningDate: DateTime.utc(2024, 5, 1),
        email: 'private.jane@enterprise.com',
        phone: '+1 555-9999',
      );

      final row = EmployeeReportRow.fromEmployee(emp);
      expect(row.id, equals('emp_test_1'));
      expect(row.employeeCode, equals('EMP-999'));
      expect(row.fullName, equals('Jane Doe'));
      expect(row.department, equals('Engineering'));
      expect(row.designation, equals('Staff Engineer'));
      expect(row.employmentStatus, equals(EmploymentStatus.active));
      expect(row.statusLabel, equals('Active'));

      // toString does not leak sensitive details
      expect(row.toString(), isNot(contains('private.jane')));
      expect(row.toString(), isNot(contains('+1 555-9999')));
    });

    test('EmployeeReportQuery copyWith and hasFilters work accurately', () {
      const queryEmpty = EmployeeReportQuery();
      expect(queryEmpty.hasFilters, isFalse);

      final queryWithDept = queryEmpty.copyWith(department: 'Human Resources');
      expect(queryWithDept.hasFilters, isTrue);
      expect(queryWithDept.department, equals('Human Resources'));

      final queryCleared = queryWithDept.copyWith(clearDepartment: true);
      expect(queryCleared.hasFilters, isFalse);
      expect(queryCleared.department, isNull);
    });
  });

  group('HR-8.2: MockHrReportRepository Query & Filtering Tests', () {
    late MockEmployeeRepository employeeRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      reportRepo = MockHrReportRepository(employeeRepository: employeeRepo);
    });

    test('default query returns all seeded employees sorted by fullName ascending', () async {
      final result = await reportRepo.getEmployeeReport(const EmployeeReportQuery());

      expect(result.totalCount, equals(5));
      final names = result.rows.map((r) => r.fullName).toList();
      // Should be alphabetically sorted: Alice Johnson, Bob Miller, Charlie Davis, Diana Prince, Evan Wright
      expect(names, equals([
        'Alice Johnson',
        'Bob Miller',
        'Charlie Davis',
        'Dana White',
        'Evan Wright',
      ]));
    });

    test('department filter matches exact department case-insensitively', () async {
      final result = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(department: 'sales & marketing'),
      );

      expect(result.totalCount, equals(1));
      expect(result.rows.first.fullName, equals('Charlie Davis'));
    });

    test('employmentStatus filter filters rows accurately', () async {
      final result = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(employmentStatus: EmploymentStatus.active),
      );

      expect(result.totalCount, equals(3));
      for (final row in result.rows) {
        expect(row.employmentStatus, equals(EmploymentStatus.active));
      }
    });

    test('joiningDateRange filter filters records by date boundary', () async {
      final range = ReportDateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );
      final result = await reportRepo.getEmployeeReport(
        EmployeeReportQuery(joiningDateRange: range),
      );

      // Only Charlie Davis joined in 2024 (2024-01-10)
      expect(result.totalCount, equals(1));
      expect(result.rows.first.fullName, equals('Charlie Davis'));
    });

    test('search query matches fullName or employeeCode', () async {
      final resultName = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(searchTerm: 'alice'),
      );
      expect(resultName.totalCount, equals(1));
      expect(resultName.rows.first.fullName, equals('Alice Johnson'));

      final resultCode = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(searchTerm: 'emp-002'),
      );
      expect(resultCode.totalCount, equals(1));
      expect(resultCode.rows.first.fullName, equals('Bob Miller'));
    });

    test('combined filters evaluate conjunctively', () async {
      // Department = Sales & Marketing, Status = Active
      final result = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(
          department: 'Sales & Marketing',
          employmentStatus: EmploymentStatus.active,
        ),
      );

      // Charlie Davis is active in Sales & Marketing; Evan Wright is inactive in Sales & Marketing
      expect(result.totalCount, equals(1));
      expect(result.rows.first.fullName, equals('Charlie Davis'));
    });

    test('sorting by employeeCode descending produces expected ordering', () async {
      final result = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(
          sort: ReportSort(
            field: 'employeeCode',
            direction: ReportSortDirection.descending,
          ),
        ),
      );

      final codes = result.rows.map((r) => r.employeeCode).toList();
      expect(codes, equals([
        'EMP-005',
        'EMP-004',
        'EMP-003',
        'EMP-002',
        'EMP-001',
      ]));
    });

    test('empty result returned when no employees match filters', () async {
      final result = await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(department: 'NonExistentDept'),
      );

      expect(result.totalCount, equals(0));
      expect(result.isEmpty, isTrue);
      expect(result.rows, isEmpty);
    });

    test('report query execution does not mutate underlying EmployeeRepository', () async {
      final beforeEmployees = await employeeRepo.getEmployees();
      await reportRepo.getEmployeeReport(
        const EmployeeReportQuery(
          department: 'Sales & Marketing',
          sort: ReportSort(field: 'employeeCode', direction: ReportSortDirection.descending),
        ),
      );
      final afterEmployees = await employeeRepo.getEmployees();

      expect(afterEmployees.length, equals(beforeEmployees.length));
      for (var i = 0; i < beforeEmployees.length; i++) {
        expect(afterEmployees[i].id, equals(beforeEmployees[i].id));
        expect(afterEmployees[i].fullName, equals(beforeEmployees[i].fullName));
      }
    });
  });
}
