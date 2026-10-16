enum AttendanceDailyStatus {
  present,
  absent,
  halfDay,
  leave,
  holiday,
  weekOff,
  onDuty,
}

/// Backend-computed day result. Calculation fields are displayed, never derived
/// by widgets, so mobile, web, payroll, and reports remain consistent.
class AttendanceDaily {
  final String id;
  final String employeeId;
  final DateTime date;
  final String? shiftId;
  final DateTime? firstIn;
  final DateTime? lastOut;
  final Duration totalHours;
  final Duration breakHours;
  final AttendanceDailyStatus status;
  final int lateMinutes;
  final int earlyExitMinutes;
  final int overtimeMinutes;
  final bool isLocked;

  const AttendanceDaily({
    required this.id,
    required this.employeeId,
    required this.date,
    this.shiftId,
    this.firstIn,
    this.lastOut,
    this.totalHours = Duration.zero,
    this.breakHours = Duration.zero,
    required this.status,
    this.lateMinutes = 0,
    this.earlyExitMinutes = 0,
    this.overtimeMinutes = 0,
    this.isLocked = false,
  });
}
