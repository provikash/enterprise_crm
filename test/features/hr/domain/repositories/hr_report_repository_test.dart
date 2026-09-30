import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_summary.dart';
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

  group('HR-8.4: Attendance Report Domain & Repository Tests', () {
    late MockEmployeeRepository employeeRepo;
    late MockAttendanceRepository attendanceRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      attendanceRepo = MockAttendanceRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        attendanceRepository: attendanceRepo,
      );
    });

    test('AttendanceReportSummary correctly aggregates counts without fabricated data', () {
      final rows = [
        AttendanceReportRow(
          attendanceId: 'att_1',
          employeeId: 'emp_1',
          employeeName: 'Alice',
          attendanceDate: DateTime.utc(2026, 9, 21),
          attendanceStatus: 'Present',
        ),
        AttendanceReportRow(
          attendanceId: 'att_2',
          employeeId: 'emp_1',
          employeeName: 'Alice',
          attendanceDate: DateTime.utc(2026, 9, 22),
          attendanceStatus: 'Absent',
        ),
        AttendanceReportRow(
          attendanceId: 'att_3',
          employeeId: 'emp_2',
          employeeName: 'Bob',
          attendanceDate: DateTime.utc(2026, 9, 21),
          attendanceStatus: 'Half-day',
        ),
        AttendanceReportRow(
          attendanceId: 'att_4',
          employeeId: 'emp_2',
          employeeName: 'Bob',
          attendanceDate: DateTime.utc(2026, 9, 22),
          attendanceStatus: 'On Leave',
        ),
      ];

      final summary = AttendanceReportSummary.fromRows(rows);
      expect(summary.totalRecords, equals(4));
      expect(summary.presentCount, equals(1));
      expect(summary.absentCount, equals(1));
      expect(summary.halfDayCount, equals(1));
      expect(summary.onLeaveCount, equals(1));
    });

    test('default attendance report query executes and resolves employee names', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(),
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.totalCount, greaterThan(0));

      final firstRow = result.rows.first;
      expect(firstRow.employeeName, isNotEmpty);
      expect(firstRow.attendanceDate.isUtc, isTrue);
    });

    test('filtering by employeeId returns only records for that employee', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(employeeId: 'emp_1'),
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.rows.every((r) => r.employeeId == 'emp_1'), isTrue);
      expect(result.rows.every((r) => r.employeeName == 'Alice Johnson'), isTrue);
    });

    test('filtering by status returns only matching attendance records', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(status: 'On Leave'),
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.rows.every((r) => r.attendanceStatus == 'On Leave'), isTrue);
    });

    test('filtering by date range restricts records to inclusive boundaries', () async {
      final range = ReportDateRange(
        start: DateTime.utc(2026, 9, 21),
        end: DateTime.utc(2026, 9, 22),
      );

      final result = await reportRepo.getAttendanceReport(
        AttendanceReportQuery(dateRange: range),
      );

      expect(result.isNotEmpty, isTrue);
      expect(
        result.rows.every((r) => range.contains(r.attendanceDate)),
        isTrue,
      );
    });

    test('search term filters dynamically by employee name or code', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(searchTerm: 'Alice'),
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.rows.every((r) => r.employeeName.contains('Alice')), isTrue);
    });

    test('combined filters execute conjunctively (employeeId + status)', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(
          employeeId: 'emp_1',
          status: 'Present',
        ),
      );

      expect(result.isNotEmpty, isTrue);
      expect(
        result.rows.every((r) => r.employeeId == 'emp_1' && r.attendanceStatus == 'Present'),
        isTrue,
      );
    });

    test('sorting by date ascending orders chronologically', () async {
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(
          sort: ReportSort(
            field: 'date',
            direction: ReportSortDirection.ascending,
          ),
        ),
      );

      final dates = result.rows.map((r) => r.attendanceDate).toList();
      for (var i = 0; i < dates.length - 1; i++) {
        expect(dates[i].compareTo(dates[i + 1]), lessThanOrEqualTo(0));
      }
    });

    test('missing attendance integrity: does not fabricate absent records', () async {
      // Query for an employee on a date range with known records
      final result = await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(employeeId: 'emp_1'),
      );

      // Verify that every returned row corresponds to a real AttendanceRecord in the store
      final actualRecords = await attendanceRepo.getAttendanceForEmployee('emp_1');
      expect(result.totalCount, equals(actualRecords.length));
    });

    test('report execution does not mutate underlying AttendanceRepository', () async {
      final beforeRecords = await attendanceRepo.getAttendanceRecords();
      await reportRepo.getAttendanceReport(
        const AttendanceReportQuery(
          employeeId: 'emp_1',
          status: 'Present',
        ),
      );
      final afterRecords = await attendanceRepo.getAttendanceRecords();

      expect(afterRecords.length, equals(beforeRecords.length));
      for (var i = 0; i < beforeRecords.length; i++) {
        expect(afterRecords[i].id, equals(beforeRecords[i].id));
      }
    });
  });
}
