import '../../../../features/auth/domain/entities/crm_module.dart';

/// Unambiguous relational reference pointing to an underlying target HR record.
///
/// Invariants:
/// - Target is uniquely identified by [targetModule], [targetEntityType], and [targetEntityId].
/// - [targetEntityId] must be a stable domain identifier (e.g. `period_2026_01`, `att_001`, `emp_1`),
///   never a UI row index, employee name, or transient reference.
/// - Does not store sensitive raw payroll or PII payloads.
class HrApprovalTarget {
  final CrmModule targetModule;
  final String targetEntityType;
  final String targetEntityId;

  const HrApprovalTarget({
    required this.targetModule,
    required this.targetEntityType,
    required this.targetEntityId,
  }) : assert(targetEntityType.length > 0, 'targetEntityType cannot be empty'),
       assert(targetEntityId.length > 0, 'targetEntityId cannot be empty');

  /// Helper factory creating a target reference for a Payroll Period.
  factory HrApprovalTarget.payrollPeriod(String periodId) {
    return HrApprovalTarget(
      targetModule: CrmModule.hrPayroll,
      targetEntityType: 'payroll_period',
      targetEntityId: periodId,
    );
  }

  /// Helper factory creating a target reference for an Attendance Record.
  factory HrApprovalTarget.attendanceRecord(String recordId) {
    return HrApprovalTarget(
      targetModule: CrmModule.hrPayroll,
      targetEntityType: 'attendance_record',
      targetEntityId: recordId,
    );
  }

  /// Helper factory creating a target reference for an Employee Document.
  factory HrApprovalTarget.employeeDocument(String documentId) {
    return HrApprovalTarget(
      targetModule: CrmModule.hrPayroll,
      targetEntityType: 'employee_document',
      targetEntityId: documentId,
    );
  }

  /// Creates a copy of this target reference with updated fields.
  HrApprovalTarget copyWith({
    CrmModule? targetModule,
    String? targetEntityType,
    String? targetEntityId,
  }) {
    return HrApprovalTarget(
      targetModule: targetModule ?? this.targetModule,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      targetEntityId: targetEntityId ?? this.targetEntityId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HrApprovalTarget &&
          runtimeType == other.runtimeType &&
          targetModule == other.targetModule &&
          targetEntityType == other.targetEntityType &&
          targetEntityId == other.targetEntityId;

  @override
  int get hashCode => Object.hash(targetModule, targetEntityType, targetEntityId);

  @override
  String toString() =>
      'HrApprovalTarget(module: ${targetModule.name}, entityType: $targetEntityType, entityId: $targetEntityId)';
}
