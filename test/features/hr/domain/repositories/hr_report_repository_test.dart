import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_summary.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_summary.dart';
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

  group('HR-8.5: KPI Report Domain & Repository Tests', () {
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

    test('KpiReportSummary aggregates counts and prevents incompatible unit mixing', () {
      final mixedRows = <KpiReportRow>[
        KpiReportRow(
          kpiId: 'kpi_1',
          employeeId: 'emp_1',
          employeeName: 'Alice',
          metricName: 'Code Reviews',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 20.0,
          actualValue: 25.0,
          score: 100.0,
        ),
        KpiReportRow(
          kpiId: 'kpi_2',
          employeeId: 'emp_2',
          employeeName: 'Bob',
          metricName: 'Sales Revenue',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 1000.0,
          actualValue: 1200.0,
          score: 95.0,
        ),
      ];

      final mixedSummary = KpiReportSummary.fromRows(mixedRows);
      expect(mixedSummary.totalRecords, equals(2));
      expect(mixedSummary.scoredRecords, equals(2));
      expect(mixedSummary.unscoredRecords, equals(0));
      // Invariant: differing metrics must not sum targets or actuals
      expect(mixedSummary.singleMetricName, isNull);
      expect(mixedSummary.totalTargetForMetric, isNull);
      expect(mixedSummary.totalActualForMetric, isNull);

      final singleMetricRows = <KpiReportRow>[
        KpiReportRow(
          kpiId: 'kpi_1',
          employeeId: 'emp_1',
          employeeName: 'Alice',
          metricName: 'Code Reviews',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 20.0,
          actualValue: 25.0,
          score: 100.0,
        ),
        KpiReportRow(
          kpiId: 'kpi_3',
          employeeId: 'emp_3',
          employeeName: 'Charlie',
          metricName: 'Code Reviews',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 30.0,
          actualValue: 28.0,
          score: null,
        ),
      ];

      final singleSummary = KpiReportSummary.fromRows(singleMetricRows);
      expect(singleSummary.totalRecords, equals(2));
      expect(singleSummary.scoredRecords, equals(1));
      expect(singleSummary.unscoredRecords, equals(1));
      expect(singleSummary.singleMetricName, equals('Code Reviews'));
      expect(singleSummary.totalTargetForMetric, equals(50.0));
      expect(singleSummary.totalActualForMetric, equals(53.0));
    });

    test('default KPI report query returns all KPI records with resolved employee names', () async {
      final result = await reportRepo.getKpiReport(const KpiReportQuery());
      expect(result.isNotEmpty, isTrue);
      expect(result.totalCount, equals(5));

      final firstRow = result.rows.first;
      expect(firstRow.employeeName, isNotEmpty);
      expect(firstRow.metricName, isNotEmpty);
      expect(firstRow.formattedPeriod, isNotEmpty);
    });

    test('filtering by employeeId returns only records for that employee', () async {
      final result = await reportRepo.getKpiReport(
        const KpiReportQuery(employeeId: 'emp_1'),
      );
      expect(result.isNotEmpty, isTrue);
      expect(result.totalCount, equals(2));
      expect(result.rows.every((r) => r.employeeId == 'emp_1'), isTrue);
      expect(result.rows.every((r) => r.employeeName == 'Alice Johnson'), isTrue);
    });

    test('filtering by metricName returns only matching KPI records', () async {
      final result = await reportRepo.getKpiReport(
        const KpiReportQuery(metricName: 'Inventory Accuracy'),
      );
      expect(result.isNotEmpty, isTrue);
      expect(result.totalCount, equals(1));
      expect(result.rows.first.metricName, equals('Inventory Accuracy'));
      expect(result.rows.first.employeeName, equals('Bob Miller'));
    });

    test('filtering by date range matches period boundaries', () async {
      final range = ReportDateRange(
        start: DateTime.utc(2026, 7, 1),
        end: DateTime.utc(2026, 9, 30),
      );
      final result = await reportRepo.getKpiReport(
        KpiReportQuery(dateRange: range),
      );
      expect(result.isNotEmpty, isTrue);
      expect(result.totalCount, equals(5));
    });

    test('search term matches employee name or metric name', () async {
      final resultName = await reportRepo.getKpiReport(
        const KpiReportQuery(searchTerm: 'Charlie'),
      );
      expect(resultName.totalCount, equals(1));
      expect(resultName.rows.first.employeeName, equals('Charlie Davis'));

      final resultMetric = await reportRepo.getKpiReport(
        const KpiReportQuery(searchTerm: 'Retention'),
      );
      expect(resultMetric.totalCount, equals(1));
      expect(resultMetric.rows.first.metricName, equals('Employee Retention Rate'));
    });

    test('combined filters execute conjunctively (employeeId + metricName)', () async {
      final result = await reportRepo.getKpiReport(
        const KpiReportQuery(
          employeeId: 'emp_1',
          metricName: 'Time to Hire (Days)',
        ),
      );
      expect(result.totalCount, equals(1));
      expect(result.rows.first.employeeId, equals('emp_1'));
      expect(result.rows.first.metricName, equals('Time to Hire (Days)'));
    });

    test('sorting by metricName ascending orders alphabetically', () async {
      final result = await reportRepo.getKpiReport(
        const KpiReportQuery(
          sort: ReportSort(
            field: 'metricName',
            direction: ReportSortDirection.ascending,
          ),
        ),
      );
      final metrics = result.rows.map((r) => r.metricName).toList();
      for (var i = 0; i < metrics.length - 1; i++) {
        expect(metrics[i].compareTo(metrics[i + 1]), lessThanOrEqualTo(0));
      }
    });

    test('score integrity: stored score is preserved and never recalculated or altered', () async {
      final result = await reportRepo.getKpiReport(
        const KpiReportQuery(employeeId: 'emp_3'),
      );
      expect(result.rows.first.score, equals(100.0));
      expect(result.rows.first.targetValue, equals(150.0));
      expect(result.rows.first.actualValue, equals(165.0));
    });

    test('report query execution does not mutate underlying EmployeeKpiRepository', () async {
      final beforeRecords = await kpiRepo.getKpis();
      await reportRepo.getKpiReport(
        const KpiReportQuery(
          employeeId: 'emp_1',
          metricName: 'Time to Hire (Days)',
        ),
      );
      final afterRecords = await kpiRepo.getKpis();

      expect(afterRecords.length, equals(beforeRecords.length));
      for (var i = 0; i < beforeRecords.length; i++) {
        expect(afterRecords[i].id, equals(beforeRecords[i].id));
      }
    });
  });
}
