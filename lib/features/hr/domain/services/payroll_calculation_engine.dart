import '../entities/employment_status.dart';
import '../entities/payroll_calculation_input.dart';
import '../entities/payroll_calculation_result.dart';
import '../entities/payroll_component.dart';
import '../value_objects/calculation_validation_issue.dart';
import '../value_objects/money.dart';

/// Policy governing the mathematical divisor for Loss of Pay (LOP) attendance proration.
enum AttendanceProrationPolicy {
  /// Attendance divisor is unconfirmed by business policy.
  /// The engine records an informative diagnostic warning and defers deduction.
  unresolved,

  /// Proration divisor based on exact total calendar days in the target period:
  /// dailyRate = baseSalary / totalDaysInPeriod
  calendarDays,

  /// Proration divisor based on standard fixed 30-day month:
  /// dailyRate = baseSalary / 30
  fixed30Days,

  /// Proration divisor based on standard fixed 26 working days:
  /// dailyRate = baseSalary / 26
  workingDays26,
}

/// Pure, deterministic domain calculation engine for the Enterprise CRM HR module.
///
/// Follows HR-7.1 through HR-7.5 architectural and financial specifications:
/// - Fully independent of Flutter widgets, BuildContext, Cubits, and repositories.
/// - Produces side-effect-free, deterministic calculation preview results.
/// - Preserves monetary integrity using exact 64-bit integer minor unit arithmetic ([Money]).
/// - Enforces explicit currency consistency across base salary and all attached components.
/// - Validates essential business invariants (positive base salary, period alignment, active status).
/// - Aggregates itemized earnings and deductions deterministically without arbitrary formulas.
/// - Gracefully reports negative net pay deficits as non-fatal diagnostic warnings.
/// - Does NOT mutate inputs or write to persistent storage.
class PayrollCalculationEngine {
  /// Default rule specification identifier.
  static const String defaultRuleVersion = 'RULE_SET_V1_MOCK';

  const PayrollCalculationEngine();

  /// Calculates a deterministic [PayrollCalculationResult] from the supplied [input]
  /// and optional context parameters.
  ///
  /// Parameters:
  /// - [input]: Validated calculation input containing base salary, employee ID,
  ///   period ID, unpaid leave days, and itemized components.
  /// - [periodStartDate]: Optional UTC start date of the period for effective date filtering.
  /// - [periodEndDate]: Optional UTC end date of the period for effective date filtering and calendar LOP.
  /// - [employeeJoiningDate]: Optional UTC joining date to validate that employee was hired on or before period end.
  /// - [employmentStatus]: Optional employment status to flag inactive/terminated employees.
  /// - [attendancePolicy]: Policy governing attendance Loss of Pay proration. Defaults to [AttendanceProrationPolicy.unresolved].
  /// - [calculationTimestamp]: Specific UTC timestamp to record on result (ensures 100% deterministic test fixtures).
  /// - [ruleVersion]: Rule set tag for calculation traceability.
  PayrollCalculationResult calculate({
    required PayrollCalculationInput input,
    DateTime? periodStartDate,
    DateTime? periodEndDate,
    DateTime? employeeJoiningDate,
    EmploymentStatus? employmentStatus,
    AttendanceProrationPolicy attendancePolicy =
        AttendanceProrationPolicy.unresolved,
    DateTime? calculationTimestamp,
    String ruleVersion = defaultRuleVersion,
  }) {
    final issues = <CalculationValidationIssue>[];
    final currency = input.baseSalary.currency;
    final nowUtc = (calculationTimestamp ?? DateTime.now()).toUtc();
    final calculationId = 'calc_res_${input.id}';

    // 1. Mandatory Input Invariant Validation
    if (currency.trim().isEmpty) {
      issues.add(
        const CalculationValidationIssue(
          code: 'INVALID_CURRENCY',
          message: 'Base salary currency code cannot be empty.',
          severity: CalculationIssueSeverity.error,
        ),
      );
    }

    if (input.employeeId.trim().isEmpty) {
      issues.add(
        const CalculationValidationIssue(
          code: 'EMPTY_EMPLOYEE_ID',
          message: 'Employee ID cannot be empty.',
          severity: CalculationIssueSeverity.error,
        ),
      );
    }

    if (input.payrollPeriodId.trim().isEmpty) {
      issues.add(
        const CalculationValidationIssue(
          code: 'EMPTY_PERIOD_ID',
          message: 'Payroll period ID cannot be empty.',
          severity: CalculationIssueSeverity.error,
        ),
      );
    }

    if (!input.baseSalary.isPositive) {
      issues.add(
        const CalculationValidationIssue(
          code: 'MISSING_BASE_SALARY',
          message:
              'Contracted base salary must be strictly positive (> 0.00).',
          severity: CalculationIssueSeverity.error,
        ),
      );
    }

    // Period date range consistency
    if (periodStartDate != null && periodEndDate != null) {
      final normalizedStart = DateTime.utc(
        periodStartDate.year,
        periodStartDate.month,
        periodStartDate.day,
      );
      final normalizedEnd = DateTime.utc(
        periodEndDate.year,
        periodEndDate.month,
        periodEndDate.day,
      );
      if (normalizedStart.isAfter(normalizedEnd)) {
        issues.add(
          CalculationValidationIssue(
            code: 'INVALID_PERIOD_DATE_RANGE',
            message:
                'Period start date ($normalizedStart) cannot be after period end date ($normalizedEnd).',
            severity: CalculationIssueSeverity.error,
          ),
        );
      }
    }

    // Component duplication and collision checks
    final seenComponentIds = <String>{};
    final seenKindName = <String>{};
    for (final comp in input.components) {
      // Unique ID check
      if (!seenComponentIds.add(comp.id)) {
        issues.add(
          CalculationValidationIssue(
            code: 'DUPLICATE_COMPONENT_ID',
            message:
                'Duplicate component ID detected: "${comp.id}". Each component must have a unique identifier.',
            severity: CalculationIssueSeverity.error,
          ),
        );
      }

      // Conflict with base salary earning
      final normName = comp.name.trim().toLowerCase();
      if (comp.isEarning &&
          (normName == 'base salary' || normName == 'basic salary')) {
        issues.add(
          CalculationValidationIssue(
            code: 'DUPLICATE_BASE_SALARY_COMPONENT',
            message:
                'Input includes an itemized earning "${comp.name}" which collides with the contracted base compensation.',
            severity: CalculationIssueSeverity.error,
          ),
        );
      }

      // Same kind and name warning
      final kindKey = '${comp.kind.name}:$normName';
      if (!seenKindName.add(kindKey)) {
        issues.add(
          CalculationValidationIssue(
            code: 'DUPLICATE_COMPONENT_NAME',
            message:
                'Multiple ${comp.kind.name} components named "${comp.name}" detected. Verify whether these should be combined.',
            severity: CalculationIssueSeverity.warning,
          ),
        );
      }
    }

    // Date range and joining date verification
    if (employeeJoiningDate != null && periodEndDate != null) {
      final normalizedJoining = DateTime.utc(
        employeeJoiningDate.year,
        employeeJoiningDate.month,
        employeeJoiningDate.day,
      );
      final normalizedPeriodEnd = DateTime.utc(
        periodEndDate.year,
        periodEndDate.month,
        periodEndDate.day,
      );
      if (normalizedJoining.isAfter(normalizedPeriodEnd)) {
        issues.add(
          CalculationValidationIssue(
            code: 'INVALID_PERIOD_FOR_EMPLOYEE',
            message:
                'Employee joining date ($normalizedJoining) is strictly after '
                'the payroll period end date ($normalizedPeriodEnd). Cannot pay prior to employment.',
            severity: CalculationIssueSeverity.error,
          ),
        );
      }
    }

    // Employment status review (Warning)
    if (employmentStatus != null &&
        employmentStatus != EmploymentStatus.active) {
      issues.add(
        CalculationValidationIssue(
          code: 'EMPLOYEE_NOT_ACTIVE',
          message:
              'Employee status is currently "$employmentStatus". Payroll preview generated, but requires administrative review.',
          severity: CalculationIssueSeverity.warning,
        ),
      );
    }

    // Excessive unpaid leave check
    if (input.unpaidLeaveDays > 0) {
      if (periodStartDate != null && periodEndDate != null) {
        final daysInPeriod =
            periodEndDate.difference(periodStartDate).inDays + 1;
        if (daysInPeriod > 0 && input.unpaidLeaveDays > daysInPeriod) {
          issues.add(
            CalculationValidationIssue(
              code: 'EXCESSIVE_UNPAID_LEAVE',
              message:
                  'Unpaid leave days (${input.unpaidLeaveDays}) exceeds total calendar days in period ($daysInPeriod).',
              severity: CalculationIssueSeverity.warning,
            ),
          );
        }
      } else if (attendancePolicy == AttendanceProrationPolicy.fixed30Days &&
          input.unpaidLeaveDays > 30) {
        issues.add(
          CalculationValidationIssue(
            code: 'EXCESSIVE_UNPAID_LEAVE',
            message:
                'Unpaid leave days (${input.unpaidLeaveDays}) exceeds standard 30-day divisor.',
            severity: CalculationIssueSeverity.warning,
          ),
        );
      } else if (attendancePolicy == AttendanceProrationPolicy.workingDays26 &&
          input.unpaidLeaveDays > 26) {
        issues.add(
          CalculationValidationIssue(
            code: 'EXCESSIVE_UNPAID_LEAVE',
            message:
                'Unpaid leave days (${input.unpaidLeaveDays}) exceeds standard 26 working days divisor.',
            severity: CalculationIssueSeverity.warning,
          ),
        );
      }
    }

    // If fatal validation errors exist, safely return an invalid calculation result
    if (issues.any((i) => i.isError)) {
      final fallbackMoney = input.baseSalary.isPositive
          ? input.baseSalary
          : Money.zero(currency: currency);
      return PayrollCalculationResult(
        calculationId: calculationId,
        employeeId: input.employeeId,
        payrollPeriodId: input.payrollPeriodId,
        baseSalary: input.baseSalary,
        grossEarnings: fallbackMoney,
        totalDeductions: Money.zero(currency: currency),
        netPayable: fallbackMoney,
        components: const [],
        validationIssues: issues,
        calculatedAt: nowUtc,
        ruleVersion: ruleVersion,
        isPreview: true,
      );
    }

    // 2. Filter applicable components for target period
    final applicableComponents = input.components.where((comp) {
      if (periodStartDate != null && periodEndDate != null) {
        return comp.isApplicableForPeriod(periodStartDate, periodEndDate);
      }
      return true;
    }).toList();

    // 3. Evaluate Earnings (FORM-01)
    // Base salary is the primary contracted earning
    final baseEarningComponent = PayrollComponent.earning(
      id: 'comp_base_${input.id}',
      name: 'Base Salary',
      amount: input.baseSalary,
      source: PayrollComponentSource.stored,
      effectiveDate: periodStartDate,
    );

    final itemizedEarnings =
        applicableComponents.where((c) => c.isEarning).toList();
    final evaluatedEarnings = [baseEarningComponent, ...itemizedEarnings];

    var totalGross = input.baseSalary;
    for (final earning in itemizedEarnings) {
      totalGross += earning.amount;
    }

    // 4. Evaluate Deductions (FORM-02)
    final evaluatedDeductions = <PayrollComponent>[];
    evaluatedDeductions.addAll(
      applicableComponents.where((c) => c.isDeduction),
    );

    // Attendance / Loss of Pay (LOP) Evaluation
    if (input.unpaidLeaveDays > 0) {
      switch (attendancePolicy) {
        case AttendanceProrationPolicy.unresolved:
          issues.add(
            CalculationValidationIssue(
              code: 'UNRESOLVED_LOP_POLICY',
              message:
                  'Employee has ${input.unpaidLeaveDays} unpaid leave day(s), but Loss of Pay proration policy is unconfirmed. Attendance deduction deferred.',
              severity: CalculationIssueSeverity.warning,
            ),
          );
          break;

        case AttendanceProrationPolicy.calendarDays:
          if (periodStartDate == null || periodEndDate == null) {
            issues.add(
              const CalculationValidationIssue(
                code: 'MISSING_PERIOD_DATES_FOR_LOP',
                message:
                    'Period start and end dates are required to calculate calendar-day LOP proration.',
                severity: CalculationIssueSeverity.warning,
              ),
            );
          } else {
            final daysInPeriod =
                periodEndDate.difference(periodStartDate).inDays + 1;
            if (daysInPeriod <= 0) {
              issues.add(
                const CalculationValidationIssue(
                  code: 'INVALID_PERIOD_DATE_RANGE',
                  message:
                      'Period start date must not be after period end date for LOP calculation.',
                  severity: CalculationIssueSeverity.warning,
                ),
              );
            } else {
              final lopMinor =
                  ((input.baseSalary.minorUnits * input.unpaidLeaveDays) /
                          daysInPeriod)
                      .round();
              final lopAmount = Money(
                minorUnits: lopMinor,
                currency: currency,
              );
              evaluatedDeductions.add(
                PayrollComponent.deduction(
                  id: 'comp_lop_${input.id}',
                  name: 'Loss of Pay (${input.unpaidLeaveDays} days)',
                  amount: lopAmount,
                  source: PayrollComponentSource.calculated,
                  calculationRuleId: 'FORM-04-LOP-CALENDAR',
                  remarks:
                      '${input.unpaidLeaveDays} / $daysInPeriod calendar days',
                ),
              );
            }
          }
          break;

        case AttendanceProrationPolicy.fixed30Days:
          final lopMinor =
              ((input.baseSalary.minorUnits * input.unpaidLeaveDays) / 30.0)
                  .round();
          final lopAmount = Money(
            minorUnits: lopMinor,
            currency: currency,
          );
          evaluatedDeductions.add(
            PayrollComponent.deduction(
              id: 'comp_lop_${input.id}',
              name: 'Loss of Pay (${input.unpaidLeaveDays} days)',
              amount: lopAmount,
              source: PayrollComponentSource.calculated,
              calculationRuleId: 'FORM-04-LOP-FIXED30',
              remarks: '${input.unpaidLeaveDays} / 30 standard days',
            ),
          );
          break;

        case AttendanceProrationPolicy.workingDays26:
          final lopMinor =
              ((input.baseSalary.minorUnits * input.unpaidLeaveDays) / 26.0)
                  .round();
          final lopAmount = Money(
            minorUnits: lopMinor,
            currency: currency,
          );
          evaluatedDeductions.add(
            PayrollComponent.deduction(
              id: 'comp_lop_${input.id}',
              name: 'Loss of Pay (${input.unpaidLeaveDays} days)',
              amount: lopAmount,
              source: PayrollComponentSource.calculated,
              calculationRuleId: 'FORM-04-LOP-WORKING26',
              remarks: '${input.unpaidLeaveDays} / 26 working days',
            ),
          );
          break;
      }
    }

    var totalDeductions = Money.zero(currency: currency);
    for (final deduction in evaluatedDeductions) {
      totalDeductions += deduction.amount;
    }

    // 5. Net Payable Formulation (FORM-03)
    final netPayable = totalGross - totalDeductions;
    if (netPayable.isNegative) {
      issues.add(
        CalculationValidationIssue(
          code: 'NEGATIVE_NET_PAYABLE',
          message:
              'Total deductions (${totalDeductions.formatted}) exceed gross earnings (${totalGross.formatted}). Net payable is deficit (${netPayable.formatted}).',
          severity: CalculationIssueSeverity.warning,
        ),
      );
    }

    // 6. Compile all evaluated components
    final allComponents = [...evaluatedEarnings, ...evaluatedDeductions];

    return PayrollCalculationResult(
      calculationId: calculationId,
      employeeId: input.employeeId,
      payrollPeriodId: input.payrollPeriodId,
      baseSalary: input.baseSalary,
      grossEarnings: totalGross,
      totalDeductions: totalDeductions,
      netPayable: netPayable,
      components: allComponents,
      validationIssues: issues,
      calculatedAt: nowUtc,
      ruleVersion: ruleVersion,
      isPreview: true,
    );
  }
}
