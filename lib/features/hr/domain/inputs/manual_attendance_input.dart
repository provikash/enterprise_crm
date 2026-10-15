import '../entities/attendance_daily.dart';

class ManualAttendanceInput {
  final String employeeId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final AttendanceDailyStatus status;
  final String reason;
  final String recordedBy;

  const ManualAttendanceInput({
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.reason,
    required this.recordedBy,
  });
}
