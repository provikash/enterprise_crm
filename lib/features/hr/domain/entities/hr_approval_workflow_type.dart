/// Represents the specific category of HR approval workflow.
///
/// Invariants:
/// - Explicit typed representation of confirmed/candidate HR approval operations.
/// - Unrecognized workflows are strictly rejected to prevent invalid transitions.
enum HrApprovalWorkflowType {
  /// Approval required to finalize and lock an entire monthly payroll period.
  payrollFinalization('hr.payroll_finalization', 'Payroll Period Finalization'),

  /// Approval required to adjust or correct a historical attendance log.
  attendanceCorrection('hr.attendance_correction', 'Attendance Correction'),

  /// Approval required to verify or certify an employee compliance document.
  documentVerification('hr.document_verification', 'Employee Document Verification');

  final String identifier;
  final String displayName;

  const HrApprovalWorkflowType(this.identifier, this.displayName);

  /// Resolves an [HrApprovalWorkflowType] from its string identifier.
  static HrApprovalWorkflowType? fromIdentifier(String? identifier) {
    if (identifier == null) return null;
    final normalized = identifier.trim().toLowerCase();
    for (final type in HrApprovalWorkflowType.values) {
      if (type.identifier == normalized) return type;
    }
    return null;
  }
}
