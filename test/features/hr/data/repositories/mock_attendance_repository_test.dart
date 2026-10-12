import 'package:enterprise_crm/features/hr/data/mock/mock_attendance_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_daily.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_log.dart';
import 'package:enterprise_crm/features/hr/domain/inputs/manual_attendance_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAttendanceStore store;
  late MockAttendanceRepository repository;

  setUp(() {
    store = MockAttendanceStore(seedInitialData: true);
    repository = MockAttendanceRepository(store: store);
  });

  group('MockAttendanceRepository Tests', () {
    test('getAttendanceRecords retrieves seeded records', () async {
      final records = await repository.getAttendanceRecords();

      expect(records, isNotEmpty);
      expect(
        records.length,
        equals(12),
      ); // 5 for emp_1, 5 for emp_2, 2 for emp_3
    });

    test('getAttendanceRecords filters by employeeId', () async {
      final records = await repository.getAttendanceRecords(
        employeeId: 'emp_1',
      );

      expect(records.length, equals(5));
      expect(records.every((r) => r.employeeId == 'emp_1'), isTrue);
    });

    test('getAttendanceRecords filters by date range', () async {
      final records = await repository.getAttendanceRecords(
        startDate: DateTime.utc(2026, 9, 21),
        endDate: DateTime.utc(2026, 9, 22),
      );

      expect(records.isNotEmpty, isTrue);
      expect(
        records.every(
          (r) =>
              !r.date.isBefore(DateTime.utc(2026, 9, 21)) &&
              !r.date.isAfter(DateTime.utc(2026, 9, 22)),
        ),
        isTrue,
      );
    });

    test('getAttendanceRecords filters by status', () async {
      final records = await repository.getAttendanceRecords(status: 'On Leave');

      expect(records.isNotEmpty, isTrue);
      expect(records.every((r) => r.attendanceStatus == 'On Leave'), isTrue);
    });

    test('getAttendanceById returns record if found and null if not', () async {
      final found = await repository.getAttendanceById('att_101');
      expect(found, isNotNull);
      expect(found!.id, equals('att_101'));
      expect(found.employeeId, equals('emp_1'));

      final notFound = await repository.getAttendanceById('att_unknown');
      expect(notFound, isNull);
    });

    test('getAttendanceForDate returns records for specific date', () async {
      final date = DateTime.utc(2026, 9, 21);
      final records = await repository.getAttendanceForDate(date);

      expect(records.length, equals(3)); // emp_1, emp_2, emp_3
      expect(records.every((r) => r.isSameDay(date)), isTrue);
    });

    test('recordAttendance adds a new record with copy isolation', () async {
      final newRecord = AttendanceRecord(
        id: '',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 30),
        attendanceStatus: 'Present',
        remarks: 'Test new record',
      );

      final saved = await repository.recordAttendance(newRecord);

      expect(saved.id, isNotEmpty);
      expect(saved.employeeId, equals('emp_1'));
      expect(saved.attendanceStatus, equals('Present'));

      final fetched = await repository.getAttendanceById(saved.id);
      expect(fetched, isNotNull);
      expect(fetched!.remarks, equals('Test new record'));
    });

    test('manual attendance keeps raw logs and updates daily record', () async {
      final saved = await repository.recordManualAttendance(
        ManualAttendanceInput(
          employeeId: 'emp_4',
          date: DateTime(2026, 10, 12),
          checkIn: DateTime(2026, 10, 12, 9),
          checkOut: DateTime(2026, 10, 12, 18),
          status: AttendanceDailyStatus.present,
          reason: 'Biometric device was offline',
          recordedBy: 'usr_admin',
        ),
      );

      expect(saved.attendanceStatus, 'Present');
      expect(saved.remarks, contains('Biometric device was offline'));
      final logs = await repository.getAttendanceLogs(
        employeeId: 'emp_4',
        date: DateTime(2026, 10, 12),
      );
      expect(logs, hasLength(2));
      expect(logs.map((log) => log.type), {
        AttendancePunchType.checkIn,
        AttendancePunchType.checkOut,
      });
      expect(
        logs.every((log) => log.source == AttendanceSource.manual),
        isTrue,
      );
      expect(logs.every((log) => log.recordedBy == 'usr_admin'), isTrue);
    });

    test('manual attendance requires an audit reason', () async {
      expect(
        () => repository.recordManualAttendance(
          ManualAttendanceInput(
            employeeId: 'emp_4',
            date: DateTime(2026, 10, 12),
            status: AttendanceDailyStatus.absent,
            reason: '  ',
            recordedBy: 'usr_admin',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
