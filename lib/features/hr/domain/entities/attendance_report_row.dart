import 'package:flutter/foundation.dart';

import 'attendance_record.dart';

/// Immutable domain entity representing a single row in an Attendance Report.
///
/// Follows HR-8.4 business requirements:
/// - Stably associated with [attendanceId] and [employeeId].
/// - [attendanceDate] is normalized to UTC calendar date.
/// - Authoritative [attendanceStatus] preserves domain values without fabrication.
/// - Check-in and check-out timestamps preserved as nullable values without synthesis.
/// - Display metadata ([employeeName], [employeeCode]) resolved from authoritative sources.
@immutable
class AttendanceReportRow {
  final String attendanceId;
  final String employeeId;
  final String? employeeCode;
  final String employeeName;
  final DateTime attendanceDate;
  final String attendanceStatus;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? remarks;

  AttendanceReportRow({
    required this.attendanceId,
    required this.employeeId,
    this.employeeCode,
    required this.employeeName,
    required DateTime attendanceDate,
    required this.attendanceStatus,
    this.checkIn,
    this.checkOut,
    this.remarks,
  }) : attendanceDate = DateTime.utc(
          attendanceDate.year,
          attendanceDate.month,
          attendanceDate.day,
        );

  /// Factory constructor transforming an authoritative [AttendanceRecord] into a report row.
  factory AttendanceReportRow.fromAttendanceRecord(
    AttendanceRecord record, {
    String? employeeCode,
    required String employeeName,
  }) {
    return AttendanceReportRow(
      attendanceId: record.id,
      employeeId: record.employeeId,
      employeeCode: employeeCode,
      employeeName: employeeName,
      attendanceDate: record.date,
      attendanceStatus: record.attendanceStatus,
      checkIn: record.checkIn,
      checkOut: record.checkOut,
      remarks: record.remarks,
    );
  }

  /// Formatted date in 'YYYY-MM-DD' format.
  String get formattedDate {
    final y = attendanceDate.year.toString().padLeft(4, '0');
    final m = attendanceDate.month.toString().padLeft(2, '0');
    final d = attendanceDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formatted check-in time in 'HH:mm' format, or null if absent.
  String? get formattedCheckIn {
    if (checkIn == null) return null;
    final h = checkIn!.hour.toString().padLeft(2, '0');
    final m = checkIn!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formatted check-out time in 'HH:mm' format, or null if absent.
  String? get formattedCheckOut {
    if (checkOut == null) return null;
    final h = checkOut!.hour.toString().padLeft(2, '0');
    final m = checkOut!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceReportRow &&
          runtimeType == other.runtimeType &&
          attendanceId == other.attendanceId &&
          employeeId == other.employeeId &&
          employeeCode == other.employeeCode &&
          employeeName == other.employeeName &&
          attendanceDate == other.attendanceDate &&
          attendanceStatus == other.attendanceStatus &&
          checkIn == other.checkIn &&
          checkOut == other.checkOut &&
          remarks == other.remarks;

  @override
  int get hashCode => Object.hash(
        attendanceId,
        employeeId,
        employeeCode,
        employeeName,
        attendanceDate,
        attendanceStatus,
        checkIn,
        checkOut,
        remarks,
      );

  @override
  String toString() =>
      'AttendanceReportRow($attendanceId, $employeeId, $attendanceDate, $attendanceStatus)';
}
