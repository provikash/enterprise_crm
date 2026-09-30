import 'package:flutter/foundation.dart';

import 'employee.dart';
import 'employment_status.dart';

/// Immutable domain representation of an Employee row within the Employee Directory Report.
///
/// Follows HR-8.1 data privacy boundaries:
/// - Excludes sensitive personal fields (phone, personal email, linked credentials).
/// - Excludes confidential financial and payroll references.
/// - Preserves stable [id] and [employeeCode].
@immutable
class EmployeeReportRow {
  final String id;
  final String? employeeCode;
  final String fullName;
  final String? department;
  final String? designation;
  final EmploymentStatus employmentStatus;
  final DateTime? joiningDate;

  const EmployeeReportRow({
    required this.id,
    this.employeeCode,
    required this.fullName,
    this.department,
    this.designation,
    this.employmentStatus = EmploymentStatus.active,
    this.joiningDate,
  });

  /// Factory creating a report row from an authoritative [Employee] entity.
  factory EmployeeReportRow.fromEmployee(Employee employee) {
    return EmployeeReportRow(
      id: employee.id,
      employeeCode: employee.employeeCode,
      fullName: employee.fullName,
      department: employee.department,
      designation: employee.designation,
      employmentStatus: employee.employmentStatus,
      joiningDate: employee.joiningDate,
    );
  }

  /// User-facing display status.
  String get statusLabel => employmentStatus.value;

  /// Whether this employee record is currently active.
  bool get isActive => employmentStatus == EmploymentStatus.active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeReportRow &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          employeeCode == other.employeeCode &&
          fullName == other.fullName &&
          department == other.department &&
          designation == other.designation &&
          employmentStatus == other.employmentStatus &&
          joiningDate == other.joiningDate;

  @override
  int get hashCode => Object.hash(
        id,
        employeeCode,
        fullName,
        department,
        designation,
        employmentStatus,
        joiningDate,
      );

  @override
  String toString() =>
      'EmployeeReportRow(id: $id, code: $employeeCode, name: $fullName, dept: $department, status: ${employmentStatus.value})';
}
