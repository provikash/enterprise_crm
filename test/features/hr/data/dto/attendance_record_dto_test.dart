import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/dto/attendance_record_dto.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';

void main() {
  group('AttendanceRecordDto - Parsing & Serialization', () {
    test('parses full valid JSON with snake_case keys', () {
      final json = {
        'id': 'att_001',
        'employee_id': 'emp_101',
        'date': '2026-09-25',
        'status': 'Present',
        'check_in': '2026-09-25T09:05:00Z',
        'check_out': '2026-09-25T18:10:00Z',
        'remarks': 'On time',
        'recorded_by': 'usr_admin',
        'created_at': '2026-09-25T18:11:00Z',
        'updated_at': '2026-09-25T18:12:00Z',
      };

      final dto = AttendanceRecordDto.fromJson(json);

      expect(dto.id, 'att_001');
      expect(dto.employeeId, 'emp_101');
      expect(dto.date, DateTime.utc(2026, 9, 25));
      expect(dto.status, 'Present');
      expect(dto.checkIn, DateTime.parse('2026-09-25T09:05:00Z'));
      expect(dto.checkOut, DateTime.parse('2026-09-25T18:10:00Z'));
      expect(dto.remarks, 'On time');
      expect(dto.recordedBy, 'usr_admin');
      expect(dto.createdAt, DateTime.parse('2026-09-25T18:11:00Z'));
      expect(dto.updatedAt, DateTime.parse('2026-09-25T18:12:00Z'));
    });

    test('parses camelCase keys gracefully (employeeId, attendanceStatus, checkIn, checkOut)', () {
      final json = {
        'id': 'att_002',
        'employeeId': 'emp_102',
        'date': '2026-09-26',
        'attendanceStatus': 'Half-day',
        'checkIn': '2026-09-26T09:30:00Z',
        'checkOut': '2026-09-26T13:30:00Z',
      };

      final dto = AttendanceRecordDto.fromJson(json);

      expect(dto.id, 'att_002');
      expect(dto.employeeId, 'emp_102');
      expect(dto.status, 'Half-day');
      expect(dto.checkIn, DateTime.parse('2026-09-26T09:30:00Z'));
      expect(dto.checkOut, DateTime.parse('2026-09-26T13:30:00Z'));
    });

    test('normalizes date to midnight UTC', () {
      final json = {
        'id': 'att_003',
        'employee_id': 'emp_103',
        'date': '2026-10-15T15:45:00Z',
        'status': 'Present',
      };

      final dto = AttendanceRecordDto.fromJson(json);

      expect(dto.date, DateTime.utc(2026, 10, 15));
      expect(dto.date.hour, 0);
      expect(dto.date.minute, 0);
      expect(dto.date.isUtc, isTrue);
    });

    test('throws FormatException when mandatory fields are missing', () {
      expect(
        () => AttendanceRecordDto.fromJson({
          'employee_id': 'emp_104',
          'date': '2026-09-25',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AttendanceRecordDto.fromJson({
          'id': 'att_004',
          'date': '2026-09-25',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AttendanceRecordDto.fromJson({
          'id': 'att_004',
          'employee_id': 'emp_104',
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => AttendanceRecordDto.fromJson({
          'id': 'att_004',
          'employee_id': 'emp_104',
          'date': 'invalid-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('converts DTO to domain AttendanceRecord accurately', () {
      final dto = AttendanceRecordDto(
        id: 'att_005',
        employeeId: 'emp_105',
        date: DateTime.utc(2026, 9, 27),
        status: 'On Leave',
        remarks: 'Casual leave',
        recordedBy: 'usr_admin',
      );

      final domain = dto.toDomain();

      expect(domain, isA<AttendanceRecord>());
      expect(domain.id, 'att_005');
      expect(domain.employeeId, 'emp_105');
      expect(domain.date, DateTime.utc(2026, 9, 27));
      expect(domain.attendanceStatus, 'On Leave');
      expect(domain.remarks, 'Casual leave');
      expect(domain.recordedBy, 'usr_admin');
    });

    test('serializes DTO to backend JSON map', () {
      final record = AttendanceRecord(
        id: 'att_006',
        employeeId: 'emp_106',
        date: DateTime.utc(2026, 9, 28),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 28, 9, 0),
        checkOut: DateTime.utc(2026, 9, 28, 18, 0),
      );

      final dto = AttendanceRecordDto.fromDomain(record);
      final json = dto.toJson();

      expect(json['id'], 'att_006');
      expect(json['employee_id'], 'emp_106');
      expect(json['date'], '2026-09-28');
      expect(json['status'], 'Present');
      expect(json['check_in'], '2026-09-28T09:00:00.000Z');
      expect(json['check_out'], '2026-09-28T18:00:00.000Z');
    });
  });
}
