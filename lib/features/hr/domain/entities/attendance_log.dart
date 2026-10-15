enum AttendancePunchType { checkIn, checkOut }

enum AttendanceSource { web, mobile, biometric, manual, regularization }

/// Immutable raw punch. Raw logs are append-only; daily summaries are derived.
class AttendanceLog {
  final String id;
  final String employeeId;
  final DateTime timestamp;
  final AttendancePunchType type;
  final AttendanceSource source;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? deviceId;
  final String? ipAddress;
  final bool isValid;
  final String? remarks;
  final String? recordedBy;

  const AttendanceLog({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.type,
    required this.source,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.deviceId,
    this.ipAddress,
    required this.isValid,
    this.remarks,
    this.recordedBy,
  });
}
