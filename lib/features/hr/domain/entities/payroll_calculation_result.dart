import '../value_objects/calculation_validation_issue.dart';
import '../value_objects/money.dart';

/// Immutable domain entity representing the output of a payroll calculation
/// or simulation operation in the Enterprise CRM HR module.
///
/// Follows HR-7.2 and HR-7.3 domain contracts:
/// - Stably identified by [calculationId].
/// - Associated with [employeeId] and [payrollPeriodId].
/// - Preserves monetary integrity using exact [Money] value objects.
/// - Encapsulates any [validationIssues] (warnings or errors) discovered during calculation.
/// - Strictly marked as [isPreview] by default to prevent false finalization or overwriting
///   authoritative stored records in [PayrollRepository].
class PayrollCalculationResult {
  /// Unique identifier of this calculation result instance.
  final String calculationId;

  /// Identifier of the evaluated employee.
  final String employeeId;

  /// Identifier of the evaluated payroll period.
  final String payrollPeriodId;

  /// Contracted base salary used as the baseline for this calculation.
  final Money baseSalary;

  /// Total gross earnings calculated for this period.
  final Money grossEarnings;

  /// Total deductions calculated for this period.
  final Money totalDeductions;

  /// Final net take-home payable amount.
  final Money netPayable;

  /// List of validation warnings, errors, or diagnostic notices.
  final List<CalculationValidationIssue> validationIssues;

  /// Normalized UTC timestamp when this calculation was generated.
  final DateTime calculatedAt;

  /// Version or specification tag of the rules applied during calculation.
  final String ruleVersion;

  /// Whether this result is an interactive preview rather than an authoritative finalized run.
  final bool isPreview;

  PayrollCalculationResult({
    required this.calculationId,
    required this.employeeId,
    required this.payrollPeriodId,
    required this.baseSalary,
    required this.grossEarnings,
    required this.totalDeductions,
    required this.netPayable,
    List<CalculationValidationIssue>? validationIssues,
    DateTime? calculatedAt,
    this.ruleVersion = 'RULE_SET_V1_MOCK',
    this.isPreview = true,
  })  : validationIssues = List.unmodifiable(validationIssues ?? const []),
        calculatedAt = (calculatedAt ?? DateTime.now()).toUtc() {
    if (calculationId.trim().isEmpty) {
      throw ArgumentError.value(
        calculationId,
        'calculationId',
        'Calculation ID cannot be empty',
      );
    }
    if (employeeId.trim().isEmpty) {
      throw ArgumentError.value(
        employeeId,
        'employeeId',
        'Employee ID cannot be empty',
      );
    }
    if (payrollPeriodId.trim().isEmpty) {
      throw ArgumentError.value(
        payrollPeriodId,
        'payrollPeriodId',
        'Payroll period ID cannot be empty',
      );
    }
    if (grossEarnings.currency != baseSalary.currency ||
        totalDeductions.currency != baseSalary.currency ||
        netPayable.currency != baseSalary.currency) {
      throw ArgumentError(
        'All monetary components in a calculation result must share the same currency: '
        'base: ${baseSalary.currency}, gross: ${grossEarnings.currency}, '
        'deductions: ${totalDeductions.currency}, net: ${netPayable.currency}',
      );
    }
  }

  /// Whether this calculation produced any fatal errors.
  bool get hasErrors => validationIssues.any((issue) => issue.isError);

  /// Whether this calculation produced any non-fatal warnings.
  bool get hasWarnings => validationIssues.any((issue) => issue.isWarning);

  /// Whether this calculation is mathematically and logically valid (no fatal errors).
  bool get isValid => !hasErrors;

  /// Creates a copy of this calculation result with updated fields.
  PayrollCalculationResult copyWith({
    String? calculationId,
    String? employeeId,
    String? payrollPeriodId,
    Money? baseSalary,
    Money? grossEarnings,
    Money? totalDeductions,
    Money? netPayable,
    List<CalculationValidationIssue>? validationIssues,
    DateTime? calculatedAt,
    String? ruleVersion,
    bool? isPreview,
  }) {
    return PayrollCalculationResult(
      calculationId: calculationId ?? this.calculationId,
      employeeId: employeeId ?? this.employeeId,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      baseSalary: baseSalary ?? this.baseSalary,
      grossEarnings: grossEarnings ?? this.grossEarnings,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netPayable: netPayable ?? this.netPayable,
      validationIssues: validationIssues ?? this.validationIssues,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      isPreview: isPreview ?? this.isPreview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollCalculationResult &&
          runtimeType == other.runtimeType &&
          calculationId == other.calculationId &&
          employeeId == other.employeeId &&
          payrollPeriodId == other.payrollPeriodId &&
          baseSalary == other.baseSalary &&
          grossEarnings == other.grossEarnings &&
          totalDeductions == other.totalDeductions &&
          netPayable == other.netPayable &&
          calculatedAt == other.calculatedAt &&
          ruleVersion == other.ruleVersion &&
          isPreview == other.isPreview;

  @override
  int get hashCode => Object.hash(
        calculationId,
        employeeId,
        payrollPeriodId,
        baseSalary,
        grossEarnings,
        totalDeductions,
        netPayable,
        calculatedAt,
        ruleVersion,
        isPreview,
      );

  @override
  String toString() =>
      'PayrollCalculationResult(id: $calculationId, emp: $employeeId, period: $payrollPeriodId, net: $netPayable, valid: $isValid, preview: $isPreview)';
}
