import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_date_range.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_report_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplodingReportRepository implements HrReportRepository {
  bool shouldThrow = true;
  final HrReportRepository _fallback = MockHrReportRepository(
    employeeRepository: MockEmployeeRepository(),
    attendanceRepository: MockAttendanceRepository(),
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
  ) async {
    if (shouldThrow) {
      throw Exception('Simulated fatal database connection failure');
    }
    return _fallback.getAttendanceReport(query);
  }
}

void main() {
  group('AttendanceReportCubit Tests (HR-8.4)', () {
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

    test('initializes and immediately loads default attendance report', () async {
      final cubit = AttendanceReportCubit(repository: reportRepo);
      expect(cubit.state.status, equals(AttendanceReportStatus.loading));

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(AttendanceReportStatus.loaded));
      expect(cubit.state.result, isNotNull);
      expect(cubit.state.summary, isNotNull);
      expect(cubit.state.rows, isNotEmpty);
      expect(cubit.state.summary!.totalRecords, equals(cubit.state.rows.length));

      cubit.close();
    });

    test('loadReport transitions to empty when zero records match query', () async {
      final cubit = AttendanceReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.loadReport(
        query: const AttendanceReportQuery(employeeId: 'non_existent_emp'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, equals(AttendanceReportStatus.empty));
      expect(cubit.state.rows, isEmpty);
      expect(cubit.state.summary!.totalRecords, equals(0));

      cubit.close();
    });

    test('loadReport transitions to failure on error and retry recovers', () async {
      final explodingRepo = _ExplodingReportRepository();
      final failingCubit = AttendanceReportCubit(repository: explodingRepo);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(failingCubit.state.status, equals(AttendanceReportStatus.failure));
      expect(
        failingCubit.state.errorMessage,
        equals('Failed to generate Attendance Report. Please try again.'),
      );

      // Now disable error and retry
      explodingRepo.shouldThrow = false;
      await failingCubit.retry();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(failingCubit.state.status, equals(AttendanceReportStatus.loaded));
      expect(failingCubit.state.rows, isNotEmpty);

      failingCubit.close();
    });

    test('filter methods update query and re-evaluate report correctly', () async {
      final cubit = AttendanceReportCubit(repository: reportRepo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.setEmployeeFilter('emp_1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.employeeId, equals('emp_1'));
      expect(cubit.state.rows.every((r) => r.employeeId == 'emp_1'), isTrue);

      await cubit.setStatusFilter('Present');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.status, equals('Present'));
      expect(cubit.state.rows.every((r) => r.attendanceStatus == 'Present'), isTrue);

      final range = ReportDateRange(
        start: DateTime.utc(2026, 9, 21),
        end: DateTime.utc(2026, 9, 22),
      );
      await cubit.setDateRangeFilter(range);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.dateRange, equals(range));

      await cubit.setSearchTerm('Alice');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query.searchTerm, equals('Alice'));

      // Clear filters resets back to default
      await cubit.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.query, equals(AttendanceReportQuery.defaultQuery));
      expect(cubit.state.status, equals(AttendanceReportStatus.loaded));

      cubit.close();
    });

    test('rapid query updates discard stale asynchronous results', () async {
      final cubit = AttendanceReportCubit(repository: reportRepo);
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
