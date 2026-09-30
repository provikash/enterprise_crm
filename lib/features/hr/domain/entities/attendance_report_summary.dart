import 'package:flutter/foundation.dart';

import 'attendance_report_row.dart';

/// Immutable domain summary metrics for an evaluated Attendance Report.
///
/// Follows HR-8.4 aggregation rules:
/// - Provides exact integer counts of matching attendance statuses.
/// - Strictly prohibits invented 'attendance percentages' or punctuality scores.
/// - Preserves missing attendance integrity: unrecorded days are NOT counted as absent.
@immutable
class AttendanceReportSummary {
  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int halfDayCount;
  final int onLeaveCount;

  const AttendanceReportSummary({
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.halfDayCount,
    required this.onLeaveCount,
  });

  /// Factory computing authoritative counts directly from evaluated [rows].
  factory AttendanceReportSummary.fromRows(List<AttendanceReportRow> rows) {
    int present = 0;
    int absent = 0;
    int halfDay = 0;
    int onLeave = 0;

    for (final row in rows) {
      final s = row.attendanceStatus.trim().toLowerCase();
      if (s == 'present') {
        present++;
      } else if (s == 'absent') {
        absent++;
      } else if (s == 'half-day' || s == 'halfday') {
        halfDay++;
      } else if (s == 'on leave' || s == 'leave') {
        onLeave++;
      }
    }

    return AttendanceReportSummary(
      totalRecords: rows.length,
      presentCount: present,
      absentCount: absent,
      halfDayCount: halfDay,
      onLeaveCount: onLeave,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceReportSummary &&
          runtimeType == other.runtimeType &&
          totalRecords == other.totalRecords &&
          presentCount == other.presentCount &&
          absentCount == other.absentCount &&
          halfDayCount == other.halfDayCount &&
          onLeaveCount == other.onLeaveCount;

  @override
  int get hashCode => Object.hash(
        totalRecords,
        presentCount,
        absentCount,
        halfDayCount,
        onLeaveCount,
      );

  @override
  String toString() =>
      'AttendanceReportSummary(total: $totalRecords, present: $presentCount, absent: $absentCount, halfDay: $halfDayCount, onLeave: $onLeaveCount)';
}
