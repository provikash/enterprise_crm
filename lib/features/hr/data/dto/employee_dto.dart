import '../../domain/entities/employee.dart';
import '../../domain/entities/employment_status.dart';

/// Data Transfer Object representing an Employee record in backend communication.
///
/// Established in HR-10.3 as the strict parsing and serialization boundary
/// between the instructor backend JSON contracts and the immutable [Employee] domain entity.
///
/// Invariants:
/// - [id] and [fullName] are mandatory; missing values in JSON raise [FormatException].
/// - [status] string is mapped defensively into [EmploymentStatus].
/// - Date strings (ISO 8601 or YYYY-MM-DD) are parsed safely into UTC [DateTime].
/// - Plaintext passwords or sensitive payroll details are strictly prohibited from this DTO.
class EmployeeDto {
  final String id;
  final String? employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? department;
  final String? designation;
  final String status;
  final DateTime? joiningDate;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmployeeDto({
    required this.id,
    this.employeeCode,
    required this.fullName,
    this.email,
    this.phone,
    this.department,
    this.designation,
    this.status = 'active',
    this.joiningDate,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// Parses a backend JSON map into a validated [EmployeeDto].
  ///
  /// Throws [FormatException] if mandatory fields ([id], [fullName]) are absent or malformed.
  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('EmployeeDto.fromJson: missing or empty required field "id".');
    }

    final rawName = (json['full_name'] ?? json['name'] ?? json['fullName'])?.toString().trim();
    if (rawName == null || rawName.isEmpty) {
      throw const FormatException('EmployeeDto.fromJson: missing or empty required field "full_name".');
    }

    final rawCode = (json['employee_code'] ?? json['employeeCode'])?.toString().trim();
    final rawEmail = json['email']?.toString().trim();
    final rawPhone = json['phone']?.toString().trim();
    final rawDept = json['department']?.toString().trim();
    final rawDesig = json['designation']?.toString().trim();
    final rawStatus = (json['status'] ?? json['employment_status'])?.toString().trim() ?? 'active';
    final rawUserId = (json['user_id'] ?? json['userId'])?.toString().trim();

    DateTime? parsedJoiningDate;
    final rawJoiningDate = json['joining_date'] ?? json['joiningDate'];
    if (rawJoiningDate != null) {
      parsedJoiningDate = DateTime.tryParse(rawJoiningDate.toString());
    }

    DateTime? parsedCreatedAt;
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    if (rawCreatedAt != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString());
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = json['updated_at'] ?? json['updatedAt'];
    if (rawUpdatedAt != null) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt.toString());
    }

    return EmployeeDto(
      id: rawId,
      employeeCode: (rawCode != null && rawCode.isNotEmpty) ? rawCode : null,
      fullName: rawName,
      email: (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : null,
      phone: (rawPhone != null && rawPhone.isNotEmpty) ? rawPhone : null,
      department: (rawDept != null && rawDept.isNotEmpty) ? rawDept : null,
      designation: (rawDesig != null && rawDesig.isNotEmpty) ? rawDesig : null,
      status: rawStatus.isNotEmpty ? rawStatus : 'active',
      joiningDate: parsedJoiningDate,
      userId: (rawUserId != null && rawUserId.isNotEmpty) ? rawUserId : null,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Creates an [EmployeeDto] from an existing immutable [Employee] domain entity.
  factory EmployeeDto.fromDomain(Employee employee) {
    return EmployeeDto(
      id: employee.id,
      employeeCode: employee.employeeCode,
      fullName: employee.fullName,
      email: employee.email,
      phone: employee.phone,
      department: employee.department,
      designation: employee.designation,
      status: employee.employmentStatus.value,
      joiningDate: employee.joiningDate,
      userId: employee.userId,
      createdAt: employee.createdAt,
      updatedAt: employee.updatedAt,
    );
  }

  /// Converts this DTO into an immutable [Employee] domain entity.
  Employee toDomain() {
    return Employee(
      id: id,
      employeeCode: employeeCode,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department,
      designation: designation,
      employmentStatus: EmploymentStatus.fromString(status),
      joiningDate: joiningDate,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serializes this DTO to a backend-compatible JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (employeeCode != null) 'employee_code': employeeCode,
      'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (designation != null) 'designation': designation,
      'status': status,
      if (joiningDate != null)
        'joining_date':
            '${joiningDate!.year.toString().padLeft(4, '0')}-${joiningDate!.month.toString().padLeft(2, '0')}-${joiningDate!.day.toString().padLeft(2, '0')}',
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }
}
