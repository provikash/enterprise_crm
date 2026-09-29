/// Severity level of a calculation validation issue.
enum CalculationIssueSeverity {
  /// Fatal calculation issue preventing valid computation.
  error,

  /// Non-fatal warning or adjustment notice (e.g. negative net pay, inactive employee flag).
  warning,
}

/// Immutable value object representing a validation issue or diagnostic notice
/// produced during calculation input evaluation or calculation result generation.
class CalculationValidationIssue {
  /// Machine-readable issue code (e.g. 'MISSING_BASE_SALARY', 'NEGATIVE_NET_PAYABLE').
  final String code;

  /// Human-readable explanation suitable for display in calculation preview interfaces.
  final String message;

  /// Severity of this issue.
  final CalculationIssueSeverity severity;

  const CalculationValidationIssue({
    required this.code,
    required this.message,
    this.severity = CalculationIssueSeverity.error,
  });

  /// Whether this issue is a fatal error.
  bool get isError => severity == CalculationIssueSeverity.error;

  /// Whether this issue is a non-fatal warning.
  bool get isWarning => severity == CalculationIssueSeverity.warning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationValidationIssue &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(code, message, severity);

  @override
  String toString() => 'CalculationValidationIssue($code: $message [$severity])';
}
