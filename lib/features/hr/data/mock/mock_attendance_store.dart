import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_daily.dart';
import '../../domain/entities/attendance_log.dart';
import '../../domain/inputs/manual_attendance_input.dart';
import '../../domain/repositories/attendance_repository.dart';

/// In-memory thread-safe mock store for employee attendance records.
///
/// Follows HR-4 architectural constraints:
/// - Deterministic initial seed data across stable employee identifiers.
/// - Full copy isolation so mutations in tests or runtime do not leak.
/// - Normalized calendar dates (UTC midnight).
class MockAttendanceStore {
  final Map<String, AttendanceRecord> _records = {};
  final List<AttendanceLog> _logs = [];
  int _idCounter = 100;

  MockAttendanceStore({bool seedInitialData = true}) {
    if (seedInitialData) {
      _seed();
    }
  }

  void _seed() {
    final seeds = [
      // emp_1: Alice Johnson
      AttendanceRecord(
        id: 'att_101',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 21),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 21, 9, 2),
        checkOut: DateTime.utc(2026, 9, 21, 18, 5),
        remarks: 'On time',
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 21, 18, 6),
      ),
      AttendanceRecord(
        id: 'att_102',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 22),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 22, 8, 58),
        checkOut: DateTime.utc(2026, 9, 22, 18, 0),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 22, 18, 1),
      ),
      AttendanceRecord(
        id: 'att_103',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 23),
        attendanceStatus: 'Half-day',
        checkIn: DateTime.utc(2026, 9, 23, 9, 15),
        checkOut: DateTime.utc(2026, 9, 23, 13, 30),
        remarks: 'Doctor appointment afternoon',
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 23, 13, 35),
      ),
      AttendanceRecord(
        id: 'att_104',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 24),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 24, 9, 5),
        checkOut: DateTime.utc(2026, 9, 24, 18, 10),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 24, 18, 12),
      ),
      AttendanceRecord(
        id: 'att_105',
        employeeId: 'emp_1',
        date: DateTime.utc(2026, 9, 25),
        attendanceStatus: 'On Leave',
        checkIn: null,
        checkOut: null,
        remarks: 'Approved casual leave',
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 25, 9, 0),
      ),

      // emp_2: Bob Smith
      AttendanceRecord(
        id: 'att_201',
        employeeId: 'emp_2',
        date: DateTime.utc(2026, 9, 21),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 21, 9, 30),
        checkOut: DateTime.utc(2026, 9, 21, 18, 30),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 21, 18, 31),
      ),
      AttendanceRecord(
        id: 'att_202',
        employeeId: 'emp_2',
        date: DateTime.utc(2026, 9, 22),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 22, 9, 15),
        checkOut: DateTime.utc(2026, 9, 22, 18, 15),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 22, 18, 16),
      ),
      AttendanceRecord(
        id: 'att_203',
        employeeId: 'emp_2',
        date: DateTime.utc(2026, 9, 23),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 23, 9, 0),
        checkOut: DateTime.utc(2026, 9, 23, 18, 0),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 23, 18, 1),
      ),
      AttendanceRecord(
        id: 'att_204',
        employeeId: 'emp_2',
        date: DateTime.utc(2026, 9, 24),
        attendanceStatus: 'Absent',
        checkIn: null,
        checkOut: null,
        remarks: 'Unreported absence',
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 24, 18, 0),
      ),
      AttendanceRecord(
        id: 'att_205',
        employeeId: 'emp_2',
        date: DateTime.utc(2026, 9, 25),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 25, 9, 10),
        checkOut: DateTime.utc(2026, 9, 25, 18, 20),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 25, 18, 21),
      ),

      // emp_3: Carol Williams
      AttendanceRecord(
        id: 'att_301',
        employeeId: 'emp_3',
        date: DateTime.utc(2026, 9, 21),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 21, 9, 0),
        checkOut: DateTime.utc(2026, 9, 21, 17, 30),
        remarks: null,
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 21, 17, 31),
      ),
      AttendanceRecord(
        id: 'att_302',
        employeeId: 'emp_3',
        date: DateTime.utc(2026, 9, 22),
        attendanceStatus: 'On Leave',
        checkIn: null,
        checkOut: null,
        remarks: 'Sick leave',
        recordedBy: 'usr_admin',
        createdAt: DateTime.utc(2026, 9, 22, 9, 0),
      ),
    ];

    for (final record in seeds) {
      _records[record.id] = record;
    }
  }

  /// Retrieves cloned attendance records with optional filtering.
  List<AttendanceRecord> getAttendanceRecords({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    var results = _records.values.toList();

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      final normalizedId = employeeId.trim();
      results = results.where((r) => r.employeeId == normalizedId).toList();
    }

    if (startDate != null) {
      final normalizedStart = DateTime.utc(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      results = results
          .where((r) => !r.date.isBefore(normalizedStart))
          .toList();
    }

    if (endDate != null) {
      final normalizedEnd = DateTime.utc(
        endDate.year,
        endDate.month,
        endDate.day,
      );
      results = results.where((r) => !r.date.isAfter(normalizedEnd)).toList();
    }

    if (status != null && status.trim().isNotEmpty) {
      final normalizedStatus = status.trim().toLowerCase();
      results = results
          .where(
            (r) => r.attendanceStatus.trim().toLowerCase() == normalizedStatus,
          )
          .toList();
    }

    // Sort by date descending, then employeeId ascending
    results.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return a.employeeId.compareTo(b.employeeId);
    });

    return results.map(_cloneRecord).toList();
  }

  /// Retrieves an individual attendance record by [id].
  AttendanceRecord? getAttendanceById(String id) {
    final record = _records[id];
    return record != null ? _cloneRecord(record) : null;
  }

  /// Retrieves all records for an [employeeId].
  List<AttendanceRecord> getAttendanceForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getAttendanceRecords(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Retrieves all records for a specific calendar [date].
  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return getAttendanceRecords(startDate: normalized, endDate: normalized);
  }

  /// Records or updates an attendance record in the store.
  AttendanceRecord recordAttendance(AttendanceRecord record) {
    final effectiveId = record.id.trim().isNotEmpty
        ? record.id.trim()
        : 'att_${++_idCounter}';
    final now = DateTime.now().toUtc();

    final saved = record.copyWith(
      id: effectiveId,
      createdAt: record.createdAt ?? now,
      updatedAt: now,
    );

    _records[effectiveId] = saved;
    return _cloneRecord(saved);
  }

  List<AttendanceLog> getAttendanceLogs({String? employeeId, DateTime? date}) {
    var result = _logs.where((log) {
      if (employeeId != null && log.employeeId != employeeId) return false;
      if (date != null &&
          (log.timestamp.year != date.year ||
              log.timestamp.month != date.month ||
              log.timestamp.day != date.day)) {
        return false;
      }
      return true;
    }).toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(result);
  }

  AttendanceRecord recordManualAttendance(ManualAttendanceInput input) {
    final reason = input.reason.trim();
    if (reason.isEmpty) {
      throw const AttendanceException(
        'A reason is required for manual attendance.',
        code: 'manual_reason_required',
      );
    }
    if (input.checkIn != null &&
        input.checkOut != null &&
        !input.checkOut!.isAfter(input.checkIn!)) {
      throw const AttendanceException(
        'Check-out must be later than check-in.',
        code: 'invalid_punch_order',
      );
    }

    final normalizedDate = DateTime.utc(
      input.date.year,
      input.date.month,
      input.date.day,
    );
    final existing = getAttendanceRecords(
      employeeId: input.employeeId,
      startDate: normalizedDate,
      endDate: normalizedDate,
    );
    if (existing.any((record) => record.id.startsWith('locked_'))) {
      throw const AttendanceException(
        'Attendance is locked for this payroll period.',
        code: 'period_locked',
      );
    }

    void appendLog(DateTime timestamp, AttendancePunchType type) {
      _logs.add(
        AttendanceLog(
          id: 'log_${++_idCounter}',
          employeeId: input.employeeId,
          timestamp: timestamp,
          type: type,
          source: AttendanceSource.manual,
          isValid: true,
          remarks: reason,
          recordedBy: input.recordedBy,
        ),
      );
    }

    if (input.checkIn != null) {
      appendLog(input.checkIn!, AttendancePunchType.checkIn);
    }
    if (input.checkOut != null) {
      appendLog(input.checkOut!, AttendancePunchType.checkOut);
    }

    final status = switch (input.status) {
      AttendanceDailyStatus.present => 'Present',
      AttendanceDailyStatus.absent => 'Absent',
      AttendanceDailyStatus.halfDay => 'Half-day',
      AttendanceDailyStatus.leave => 'On Leave',
      AttendanceDailyStatus.holiday => 'Holiday',
      AttendanceDailyStatus.weekOff => 'Week Off',
      AttendanceDailyStatus.onDuty => 'On Duty',
    };
    final previous = existing.firstOrNull;
    return recordAttendance(
      AttendanceRecord(
        id: previous?.id ?? '',
        employeeId: input.employeeId,
        date: normalizedDate,
        attendanceStatus: status,
        checkIn: input.checkIn,
        checkOut: input.checkOut,
        remarks: 'Manual: $reason',
        recordedBy: input.recordedBy,
        createdAt: previous?.createdAt,
      ),
    );
  }

  AttendanceRecord _cloneRecord(AttendanceRecord r) {
    return r.copyWith();
  }
}
