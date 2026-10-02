/// Distinct types of notifications emitted by HR approval workflows.
///
/// Follows HR-9.1 and HR-9.7 specifications:
/// - Only confirmed or explicitly approved notification types are represented.
/// - Salary, deduction, and direct payment notifications are strictly omitted.
enum HrNotificationType {
  /// Emitted when a new approval request is submitted, notifying administrators.
  approvalRequestSubmitted('Approval Request Submitted'),

  /// Emitted when an authorized administrator records an approval or rejection decision.
  approvalDecisionRecorded('Approval Decision Recorded'),

  /// Emitted when an approval request is cancelled by its requester.
  approvalRequestCancelled('Approval Request Cancelled');

  final String label;

  const HrNotificationType(this.label);

  bool get isApprovalRelated => true;

  @override
  String toString() => label;
}
