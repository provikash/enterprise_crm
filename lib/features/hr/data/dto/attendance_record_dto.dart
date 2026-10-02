import '../../domain/entities/attendance_record.dart';

/// Data Transfer Object representing an employee Attendance record in backend communications.
///
/// Established in HR-10.6 as the serialization and domain mapping boundary.
///
/// Invariants:
/// - [id], [employeeId], [date], and [status] are mandatory.
/// - [date] is normalized to UTC calendar date (midnight UTC).
/// - Missing attendance records are NEVER fabricated as 'Absent'.
/// - Payroll calculations, overtime pay, and deduction formulas are strictly excluded.
class AttendanceRecordDto {
  final String id;
  final String employeeId;
  final DateTime date;
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? remarks;
  final String? recordedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecordDto({
    required this.id,
    required this.employeeId,
    required DateTime date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.remarks,
    this.recordedBy,
    this.createdAt,
    this.updatedAt,
  }) : date = DateTime.utc(date.year, date.month, date.day);

  /// Parses a backend JSON map into a validated [AttendanceRecordDto].
  ///
  /// Throws [FormatException] if mandatory fields ([id], [employee_id], [date]) are absent.
  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('AttendanceRecordDto: missing or empty required field "id".');
    }

    final rawEmpId = (json['employee_id'] ?? json['employeeId'])?.toString().trim();
    if (rawEmpId == null || rawEmpId.isEmpty) {
      throw const FormatException('AttendanceRecordDto: missing or empty required field "employee_id".');
    }

    final rawDateStr = json['date']?.toString().trim();
    if (rawDateStr == null || rawDateStr.isEmpty) {
      throw const FormatException('AttendanceRecordDto: missing or empty required field "date".');
    }
    final parsedDate = DateTime.tryParse(rawDateStr);
    if (parsedDate == null) {
      throw FormatException('AttendanceRecordDto: invalid date format "$rawDateStr".');
    }

    final rawStatus = (json['status'] ?? json['attendance_status'] ?? json['attendanceStatus'])?.toString().trim() ?? 'Present';
    final rawRemarks = json['remarks']?.toString().trim();
    final rawRecordedBy = (json['recorded_by'] ?? json['recordedBy'])?.toString().trim();

    DateTime? parsedCheckIn;
    final rawCheckIn = json['check_in'] ?? json['checkIn'];
    if (rawCheckIn != null && rawCheckIn.toString().trim().isNotEmpty) {
      parsedCheckIn = DateTime.tryParse(rawCheckIn.toString().trim());
    }

    DateTime? parsedCheckOut;
    final rawCheckOut = json['check_out'] ?? json['checkOut'];
    if (rawCheckOut != null && rawCheckOut.toString().trim().isNotEmpty) {
      parsedCheckOut = DateTime.tryParse(rawCheckOut.toString().trim());
    }

    DateTime? parsedCreatedAt;
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    if (rawCreatedAt != null && rawCreatedAt.toString().trim().isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString().trim());
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = json['updated_at'] ?? json['updatedAt'];
    if (rawUpdatedAt != null && rawUpdatedAt.toString().trim().isNotEmpty) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt.toString().trim());
    }

    return AttendanceRecordDto(
      id: rawId,
      employeeId: rawEmpId,
      date: parsedDate,
      status: rawStatus.isNotEmpty ? rawStatus : 'Present',
      checkIn: parsedCheckIn,
      checkOut: parsedCheckOut,
      remarks: (rawRemarks != null && rawRemarks.isNotEmpty) ? rawRemarks : null,
      recordedBy: (rawRecordedBy != null && rawRecordedBy.isNotEmpty) ? rawRecordedBy : null,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Creates a DTO from an existing [AttendanceRecord] domain entity.
  factory AttendanceRecordDto.fromDomain(AttendanceRecord record) {
    return AttendanceRecordDto(
      id: record.id,
      employeeId: record.employeeId,
      date: record.date,
      status: record.attendanceStatus,
      checkIn: record.checkIn,
      checkOut: record.checkOut,
      remarks: record.remarks,
      recordedBy: record.recordedBy,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  /// Converts this DTO into an immutable [AttendanceRecord] domain entity.
  AttendanceRecord toDomain() {
    return AttendanceRecord(
      id: id,
      employeeId: employeeId,
      date: date,
      attendanceStatus: status,
      checkIn: checkIn,
      checkOut: checkOut,
      remarks: remarks,
      recordedBy: recordedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serializes this DTO to a backend-compatible JSON map.
  Map<String, dynamic> toJson() {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return {
      'id': id,
      'employee_id': employeeId,
      'date': '$y-$m-$d',
      'status': status,
      if (checkIn != null) 'check_in': checkIn!.toUtc().toIso8601String(),
      if (checkOut != null) 'check_out': checkOut!.toUtc().toIso8601String(),
      if (remarks != null) 'remarks': remarks,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }
}
