import '../../domain/entities/attendance_record.dart';

enum AttendanceDashboardStatus { initial, loading, loaded, failure }

/// Immutable state for the date-scoped Attendance dashboard.
class AttendanceDashboardState {
  final AttendanceDashboardStatus status;
  final DateTime selectedDate;
  final List<AttendanceRecord> records;
  final String? errorMessage;

  AttendanceDashboardState({
    this.status = AttendanceDashboardStatus.initial,
    required DateTime selectedDate,
    this.records = const [],
    this.errorMessage,
  }) : selectedDate = DateTime.utc(
         selectedDate.year,
         selectedDate.month,
         selectedDate.day,
       );

  bool get isLoading => status == AttendanceDashboardStatus.loading;
  bool get isLoaded => status == AttendanceDashboardStatus.loaded;
  bool get isFailure => status == AttendanceDashboardStatus.failure;

  int countForStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return records
        .where(
          (record) =>
              record.attendanceStatus.trim().toLowerCase() == normalized,
        )
        .length;
  }

  int get presentCount => countForStatus('Present');
  int get absentCount => countForStatus('Absent');
  int get leaveCount => countForStatus('On Leave');
  int get halfDayCount => countForStatus('Half-day');

  AttendanceDashboardState copyWith({
    AttendanceDashboardStatus? status,
    DateTime? selectedDate,
    List<AttendanceRecord>? records,
    String? Function()? errorMessage,
  }) {
    return AttendanceDashboardState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      records: records ?? this.records,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}
