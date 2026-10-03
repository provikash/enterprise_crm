import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/attendance_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_list_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAttendanceRepository repository;
  late AttendanceListCubit cubit;

  setUp(() {
    repository = MockAttendanceRepository();
    cubit = AttendanceListCubit(repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AttendanceListCubit Tests', () {
    test('initial state has initial status and empty records', () {
      expect(cubit.state.status, equals(AttendanceListStatus.initial));
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.viewMode, equals(AttendanceViewMode.list));
    });

    test(
      'loadAttendance emits loading then loaded with seeded records',
      () async {
        await cubit.loadAttendance();

        expect(cubit.state.status, equals(AttendanceListStatus.loaded));
        expect(cubit.state.records.length, equals(12));
        expect(cubit.state.filteredRecords.length, equals(12));
      },
    );

    test('setSearchQuery filters records by query string', () async {
      await cubit.loadAttendance();

      cubit.setSearchQuery('casual leave');
      expect(cubit.state.filteredRecords.length, equals(1));
      expect(
        cubit.state.filteredRecords.first.attendanceStatus,
        equals('On Leave'),
      );
    });

    test('setStatusFilter filters records by attendance status', () async {
      await cubit.loadAttendance();

      cubit.setStatusFilter('Absent');
      expect(cubit.state.filteredRecords.length, equals(1));
      expect(cubit.state.filteredRecords.first.employeeId, equals('emp_2'));
    });

    test('setSelectedDate filters records to specific calendar date', () async {
      await cubit.loadAttendance();

      cubit.setSelectedDate(DateTime.utc(2026, 9, 21));
      expect(cubit.state.filteredRecords.length, equals(3));
      expect(
        cubit.state.filteredRecords.every(
          (r) => r.isSameDay(DateTime.utc(2026, 9, 21)),
        ),
        isTrue,
      );
    });

    test('setSelectedEmployeeId filters records to target employee', () async {
      await cubit.loadAttendance();

      cubit.setSelectedEmployeeId('emp_3');
      expect(cubit.state.filteredRecords.length, equals(2));
      expect(
        cubit.state.filteredRecords.every((r) => r.employeeId == 'emp_3'),
        isTrue,
      );
    });

    test('setViewMode switches view mode between list and calendar', () {
      expect(cubit.state.viewMode, equals(AttendanceViewMode.list));

      cubit.setViewMode(AttendanceViewMode.calendar);
      expect(cubit.state.viewMode, equals(AttendanceViewMode.calendar));

      cubit.setViewMode(AttendanceViewMode.list);
      expect(cubit.state.viewMode, equals(AttendanceViewMode.list));
    });

    test('resetFilters clears query, status, and date filters', () async {
      await cubit.loadAttendance();

      cubit.setSearchQuery('emp_1');
      cubit.setStatusFilter('Present');
      cubit.setSelectedDate(DateTime.utc(2026, 9, 21));
      expect(cubit.state.filteredRecords.length, equals(1));

      await cubit.resetFilters();
      expect(cubit.state.searchQuery, isEmpty);
      expect(cubit.state.selectedStatus, isNull);
      expect(cubit.state.selectedDate, isNull);
      expect(cubit.state.filteredRecords.length, equals(12));
    });

    test('combined Employee + Date + Status filter', () async {
      await cubit.loadAttendance();

      await cubit.setSelectedEmployeeId('emp_1');
      await cubit.setSelectedDate(DateTime.utc(2026, 9, 23));
      await cubit.setStatusFilter('Half-day');

      expect(cubit.state.filteredRecords.length, equals(1));
      final rec = cubit.state.filteredRecords.first;
      expect(rec.employeeId, equals('emp_1'));
      expect(rec.isSameDay(DateTime.utc(2026, 9, 23)), isTrue);
      expect(rec.attendanceStatus, equals('Half-day'));
    });

    test('selecting empty date shows empty filtered records and no fabricated absent records', () async {
      await cubit.loadAttendance();

      // Sunday 2026-09-20 has no records
      await cubit.setSelectedDate(DateTime.utc(2026, 9, 20));

      expect(cubit.state.selectedDate, equals(DateTime.utc(2026, 9, 20)));
      expect(cubit.state.filteredRecords, isEmpty);
      // Invariant: Never fabricate absent records
      expect(cubit.state.filteredRecords.any((r) => r.attendanceStatus == 'Absent'), isFalse);
    });

    test('Date selection stale response prevention: late Date A response does not overwrite newer Date B', () async {
      final controlledRepo = _ControlledDelayAttendanceRepository(repository);
      final testCubit = AttendanceListCubit(controlledRepo);

      await testCubit.loadAttendance();

      final dateA = DateTime.utc(2026, 9, 21);
      final dateB = DateTime.utc(2026, 9, 22);

      // Trigger Date A with artificial delay
      controlledRepo.delayForDate[dateA] = 100;
      final futureA = testCubit.setSelectedDate(dateA);

      // Immediately trigger Date B without delay
      controlledRepo.delayForDate[dateB] = 10;
      final futureB = testCubit.setSelectedDate(dateB);

      // Wait for both to finish
      await Future.wait([futureA, futureB]);

      // State must display Date B, not Date A!
      expect(testCubit.state.selectedDate, equals(dateB));
      expect(
        testCubit.state.filteredRecords.every((r) => r.isSameDay(dateB)),
        isTrue,
      );

      await testCubit.close();
    });

    test('Employee switching stale response prevention: late Employee A response does not overwrite Employee B', () async {
      final controlledRepo = _ControlledDelayAttendanceRepository(repository);
      final testCubit = AttendanceListCubit(controlledRepo);

      await testCubit.loadAttendance();

      // Trigger emp_1 with artificial delay
      controlledRepo.delayForEmployee['emp_1'] = 100;
      final futureEmp1 = testCubit.setSelectedEmployeeId('emp_1');

      // Immediately trigger emp_2 without delay
      controlledRepo.delayForEmployee['emp_2'] = 10;
      final futureEmp2 = testCubit.setSelectedEmployeeId('emp_2');

      // Wait for both to finish
      await Future.wait([futureEmp1, futureEmp2]);

      // State must display emp_2, not emp_1!
      expect(testCubit.state.selectedEmployeeId, equals('emp_2'));
      expect(
        testCubit.state.filteredRecords.every((r) => r.employeeId == 'emp_2'),
        isTrue,
      );

      await testCubit.close();
    });

    test('Leap-year February has 29 days and non-leap has 28 days in UTC', () {
      final feb2028Days = DateTime.utc(2028, 3, 0).day;
      expect(feb2028Days, equals(29));

      final feb2026Days = DateTime.utc(2026, 3, 0).day;
      expect(feb2026Days, equals(28));
    });

    test('resetFilters restores initialEmployeeId scope', () async {
      final scopedCubit = AttendanceListCubit(repository, initialEmployeeId: 'emp_2');
      await scopedCubit.loadAttendance();

      expect(scopedCubit.state.selectedEmployeeId, equals('emp_2'));
      expect(scopedCubit.state.filteredRecords.every((r) => r.employeeId == 'emp_2'), isTrue);

      // Change employee
      await scopedCubit.setSelectedEmployeeId('emp_3');
      expect(scopedCubit.state.selectedEmployeeId, equals('emp_3'));

      // Reset
      await scopedCubit.resetFilters();
      expect(scopedCubit.state.selectedEmployeeId, equals('emp_2'));
      expect(scopedCubit.state.filteredRecords.every((r) => r.employeeId == 'emp_2'), isTrue);

      await scopedCubit.close();
    });
  });
}

class _ControlledDelayAttendanceRepository implements AttendanceRepository {
  final AttendanceRepository _inner;
  final Map<DateTime, int> delayForDate = {};
  final Map<String, int> delayForEmployee = {};

  _ControlledDelayAttendanceRepository(this._inner);

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    if (startDate != null && delayForDate.containsKey(startDate)) {
      await Future<void>.delayed(Duration(milliseconds: delayForDate[startDate]!));
    }
    if (employeeId != null && delayForEmployee.containsKey(employeeId)) {
      await Future<void>.delayed(Duration(milliseconds: delayForEmployee[employeeId]!));
    }
    return _inner.getAttendanceRecords(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );
  }

  @override
  Future<AttendanceRecord?> getAttendanceById(String id) => _inner.getAttendanceById(id);

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) =>
      _inner.getAttendanceForDate(date);

  @override
  Future<List<AttendanceRecord>> getAttendanceForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _inner.getAttendanceForEmployee(employeeId, startDate: startDate, endDate: endDate);

  @override
  Future<AttendanceRecord> recordAttendance(AttendanceRecord record) =>
      _inner.recordAttendance(record);
}
