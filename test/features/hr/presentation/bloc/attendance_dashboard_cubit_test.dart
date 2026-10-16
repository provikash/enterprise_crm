import 'dart:async';

import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/attendance_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_dashboard_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_dashboard_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledRepository implements AttendanceRepository {
  final Map<String, Completer<List<AttendanceRecord>>> requests = {};

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) {
    return (requests[_key(date)] ??= Completer<List<AttendanceRecord>>())
        .future;
  }

  @override
  Future<AttendanceRecord?> getAttendanceById(String id) async => null;

  @override
  Future<List<AttendanceRecord>> getAttendanceForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async => const [];

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async => const [];

  @override
  Future<AttendanceRecord> recordAttendance(AttendanceRecord record) async =>
      record;
}

void main() {
  test('loads a date-scoped summary using approved statuses', () async {
    final cubit = AttendanceDashboardCubit(
      repository: MockAttendanceRepository(),
      initialDate: DateTime.utc(2026, 9, 24),
    );
    addTearDown(cubit.close);

    await cubit.loadDate(DateTime.utc(2026, 9, 24));

    expect(cubit.state.status, AttendanceDashboardStatus.loaded);
    expect(cubit.state.records, hasLength(2));
    expect(cubit.state.presentCount, 1);
    expect(cubit.state.absentCount, 1);
    expect(cubit.state.leaveCount, 0);
  });

  test('a late earlier date cannot overwrite a newer date', () async {
    final repository = _ControlledRepository();
    final firstDate = DateTime.utc(2026, 9, 21);
    final secondDate = DateTime.utc(2026, 9, 22);
    final cubit = AttendanceDashboardCubit(
      repository: repository,
      initialDate: firstDate,
    );
    addTearDown(cubit.close);

    final firstLoad = cubit.loadDate(firstDate);
    final secondLoad = cubit.loadDate(secondDate);

    repository.requests['2026-9-22']!.complete([
      AttendanceRecord(
        id: 'second',
        employeeId: 'emp_2',
        date: secondDate,
        attendanceStatus: 'Present',
      ),
    ]);
    await secondLoad;

    repository.requests['2026-9-21']!.complete([
      AttendanceRecord(
        id: 'first',
        employeeId: 'emp_1',
        date: firstDate,
        attendanceStatus: 'Absent',
      ),
    ]);
    await firstLoad;

    expect(cubit.state.selectedDate, secondDate);
    expect(cubit.state.records.single.id, 'second');
  });
}
