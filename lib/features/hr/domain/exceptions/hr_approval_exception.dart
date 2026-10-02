/// Exception thrown when an operational or domain failure occurs in an HR approval workflow.
///
/// Invariants:
/// - Error messages must be sanitized and must never leak sensitive compensation or PII data.
class HrApprovalWorkflowException implements Exception {
  final String message;
  final String? code;

  const HrApprovalWorkflowException(this.message, {this.code});

  // Predefined standard error codes
  static const String invalidTransition = 'INVALID_TRANSITION';
  static const String unauthorizedActor = 'UNAUTHORIZED_ACTOR';
  static const String requestNotFound = 'REQUEST_NOT_FOUND';
  static const String unsupportedWorkflow = 'UNSUPPORTED_WORKFLOW';
  static const String duplicateDecision = 'DUPLICATE_DECISION';
  static const String validationError = 'VALIDATION_ERROR';

  @override
  String toString() =>
      'HrApprovalWorkflowException: $message${code != null ? ' (code: $code)' : ''}';
}
