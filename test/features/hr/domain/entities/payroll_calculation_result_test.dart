import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_result.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/calculation_validation_issue.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollCalculationResult Entity Tests (HR-7.3)', () {
    final base = const Money(minorUnits: 5000000);   // ₹50,000.00
    final gross = const Money(minorUnits: 7500000);  // ₹75,000.00
    final ded = const Money(minorUnits: 500000);     // ₹5,000.00
    final net = const Money(minorUnits: 7000000);    // ₹70,000.00

    test('constructs valid result with preview defaults', () {
      final result = PayrollCalculationResult(
        calculationId: 'calc_res_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
      );

      expect(result.calculationId, equals('calc_res_101'));
      expect(result.employeeId, equals('emp_1'));
      expect(result.payrollPeriodId, equals('period_2026_01'));
      expect(result.baseSalary, equals(base));
      expect(result.grossEarnings, equals(gross));
      expect(result.totalDeductions, equals(ded));
      expect(result.netPayable, equals(net));
      expect(result.isPreview, isTrue);
      expect(result.ruleVersion, equals('RULE_SET_V1_MOCK'));
      expect(result.validationIssues, isEmpty);
      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isFalse);
    });

    test('validates non-empty identifiers', () {
      expect(
        () => PayrollCalculationResult(
          calculationId: '',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: base,
          grossEarnings: gross,
          totalDeductions: ded,
          netPayable: net,
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollCalculationResult(
          calculationId: 'calc_1',
          employeeId: '   ',
          payrollPeriodId: 'period_1',
          baseSalary: base,
          grossEarnings: gross,
          totalDeductions: ded,
          netPayable: net,
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollCalculationResult(
          calculationId: 'calc_1',
          employeeId: 'emp_1',
          payrollPeriodId: '',
          baseSalary: base,
          grossEarnings: gross,
          totalDeductions: ded,
          netPayable: net,
        ),
        throwsArgumentError,
      );
    });

    test('enforces currency consistency across all financial components', () {
      final usdGross = const Money(minorUnits: 7500000, currency: 'USD');

      expect(
        () => PayrollCalculationResult(
          calculationId: 'calc_1',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: base, // INR
          grossEarnings: usdGross, // USD
          totalDeductions: ded,
          netPayable: net,
        ),
        throwsArgumentError,
      );
    });

    test('evaluates validation issue severity accurately', () {
      final warningResult = PayrollCalculationResult(
        calculationId: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        validationIssues: const [
          CalculationValidationIssue(
            code: 'NON_FATAL_NOTICE',
            message: 'Informational note',
            severity: CalculationIssueSeverity.warning,
          ),
        ],
      );

      expect(warningResult.hasWarnings, isTrue);
      expect(warningResult.hasErrors, isFalse);
      expect(warningResult.isValid, isTrue);

      final errorResult = warningResult.copyWith(
        validationIssues: const [
          CalculationValidationIssue(
            code: 'FATAL_ERROR',
            message: 'Calculated value failed integrity check',
            severity: CalculationIssueSeverity.error,
          ),
        ],
      );

      expect(errorResult.hasErrors, isTrue);
      expect(errorResult.isValid, isFalse);
    });

    test('validationIssues list is defensively unmodifiable', () {
      final mutableList = <CalculationValidationIssue>[];
      final result = PayrollCalculationResult(
        calculationId: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        validationIssues: mutableList,
      );

      expect(
        () => (result.validationIssues as dynamic).add(
          const CalculationValidationIssue(
            code: 'TEST',
            message: 'Test',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('value equality and hashCode behavior', () {
      final fixedDate = DateTime.utc(2026, 1, 15, 12, 0);
      final r1 = PayrollCalculationResult(
        calculationId: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        calculatedAt: fixedDate,
      );
      final r2 = PayrollCalculationResult(
        calculationId: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        calculatedAt: fixedDate,
      );
      final r3 = PayrollCalculationResult(
        calculationId: 'calc_2',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        calculatedAt: fixedDate,
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });

    test('accepts itemized components and provides earnings and deductions getters', () {
      final earning = PayrollComponent.earning(
        id: 'comp_hra',
        name: 'HRA',
        amount: const Money(minorUnits: 2500000),
      );
      final deduction = PayrollComponent.deduction(
        id: 'comp_pf',
        name: 'PF',
        amount: const Money(minorUnits: 180000),
      );

      final result = PayrollCalculationResult(
        calculationId: 'calc_res_comp',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
        components: [earning, deduction],
      );

      expect(result.components.length, equals(2));
      expect(result.earnings.length, equals(1));
      expect(result.earnings.first.id, equals('comp_hra'));
      expect(result.deductions.length, equals(1));
      expect(result.deductions.first.id, equals('comp_pf'));
    });

    test('validates currency consistency between baseSalary and attached components in result', () {
      final usdComp = PayrollComponent.earning(
        id: 'comp_usd',
        name: 'USD Allowance',
        amount: const Money(minorUnits: 10000, currency: 'USD'),
      );

      expect(
        () => PayrollCalculationResult(
          calculationId: 'calc_res_curr',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: base, // INR
          grossEarnings: gross, // INR
          totalDeductions: ded, // INR
          netPayable: net, // INR
          components: [usdComp],
        ),
        throwsArgumentError,
      );
    });

    test('toString maintains privacy and does not expose itemized details', () {
      final result = PayrollCalculationResult(
        calculationId: 'calc_res_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: base,
        grossEarnings: gross,
        totalDeductions: ded,
        netPayable: net,
      );
      expect(result.toString(), contains('calc_res_1'));
      expect(result.toString(), contains('emp_1'));
      expect(result.toString(), contains('valid: true'));
    });
  });
}
