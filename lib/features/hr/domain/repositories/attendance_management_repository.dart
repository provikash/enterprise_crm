import '../entities/attendance_log.dart';
import '../entities/attendance_record.dart';
import '../inputs/manual_attendance_input.dart';

/// Mutation/read contract for raw attendance logs. Production implementations
/// map this to authenticated backend APIs; the frontend does not calculate pay.
abstract interface class AttendanceManagementRepository {
  Future<List<AttendanceLog>> getAttendanceLogs({
    String? employeeId,
    DateTime? date,
  });

  Future<AttendanceRecord> recordManualAttendance(ManualAttendanceInput input);
}
