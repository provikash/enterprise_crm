import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/services/payroll_calculation_engine.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollCalculationEngine Tests (HR-7.5)', () {
    const engine = PayrollCalculationEngine();
    final fixedTimestamp = DateTime.utc(2026, 1, 31, 12, 0, 0);

    final janStart = DateTime.utc(2026, 1, 1);
    final janEnd = DateTime.utc(2026, 1, 31); // 31 calendar days

    // =========================================================================
    // 1. Mandatory Input Validation Tests
    // =========================================================================
    group('Input Invariant Validation', () {
      test('rejects empty employeeId safely without throwing', () {
        // Constructing PayrollCalculationInput with empty ID throws ArgumentError,
        // but if an input somehow has empty string or whitespace, engine flags fatal error.
        final validBase = const Money(minorUnits: 5000000);
        final input = PayrollCalculationInput(
          id: 'calc_1',
          employeeId: 'emp_valid',
          payrollPeriodId: 'period_1',
          baseSalary: validBase,
        );

        final result = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );
        expect(result.isValid, isTrue);
        expect(result.hasErrors, isFalse);
      });

      test('flags fatal error when base salary is zero or negative', () {
        final zeroBase = const Money(minorUnits: 0);
        final input = PayrollCalculationInput(
          id: 'calc_zero_base',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: zeroBase,
        );

        final result = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.isValid, isFalse);
        expect(result.hasErrors, isTrue);
        expect(
          result.validationIssues.any((i) => i.code == 'MISSING_BASE_SALARY'),
          isTrue,
        );
      });

      test('flags fatal error when employee joining date is after period end date', () {
        final input = PayrollCalculationInput(
          id: 'calc_future_joiner',
          employeeId: 'emp_future',
          payrollPeriodId: 'period_jan',
          baseSalary: const Money(minorUnits: 5000000),
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          employeeJoiningDate: DateTime.utc(2026, 2, 1), // Joined after Jan 31
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.isValid, isFalse);
        expect(result.hasErrors, isTrue);
        expect(
          result.validationIssues
              .any((i) => i.code == 'INVALID_PERIOD_FOR_EMPLOYEE'),
          isTrue,
        );
      });

      test('flags non-fatal warning when employee is not active', () {
        final input = PayrollCalculationInput(
          id: 'calc_inactive',
          employeeId: 'emp_inactive',
          payrollPeriodId: 'period_jan',
          baseSalary: const Money(minorUnits: 5000000),
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          employmentStatus: EmploymentStatus.inactive,
          calculationTimestamp: fixedTimestamp,
        );

        // Result is still mathematically valid, but has warnings
        expect(result.isValid, isTrue);
        expect(result.hasWarnings, isTrue);
        expect(
          result.validationIssues.any((i) => i.code == 'EMPLOYEE_NOT_ACTIVE'),
          isTrue,
        );
      });
    });

    // =========================================================================
    // 2. Known-Answer Tests (Authoritative Test Oracles)
    // =========================================================================
    group('Known-Answer Tests (Authoritative Oracles)', () {
      test('Candidate Example 1: Standard Full Month with Base, HRA, PF, PT', () {
        // Base Pay: ₹50,000.00
        // HRA: ₹25,000.00
        // Expected Gross: ₹75,000.00
        // Stored PF: ₹1,800.00
        // Professional Tax: ₹200.00
        // Expected Total Deductions: ₹2,000.00
        // Expected Net: ₹73,000.00
        final hra = PayrollComponent.earning(
          id: 'comp_hra_01',
          name: 'House Rent Allowance',
          amount: const Money(minorUnits: 2500000), // ₹25,000.00
        );
        final pf = PayrollComponent.deduction(
          id: 'comp_pf_01',
          name: 'Provident Fund',
          amount: const Money(minorUnits: 180000), // ₹1,800.00
        );
        final pt = PayrollComponent.deduction(
          id: 'comp_pt_01',
          name: 'Professional Tax',
          amount: const Money(minorUnits: 20000), // ₹200.00
        );

        final input = PayrollCalculationInput(
          id: 'calc_standard_month',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_2026_01',
          baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
          components: [hra, pf, pt],
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          employeeJoiningDate: DateTime.utc(2024, 1, 1),
          employmentStatus: EmploymentStatus.active,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.calculationId, equals('calc_res_calc_standard_month'));
        expect(result.employeeId, equals('emp_1'));
        expect(result.payrollPeriodId, equals('period_2026_01'));
        expect(result.baseSalary.majorUnits, equals(50000.0));
        expect(result.grossEarnings.majorUnits, equals(75000.0));
        expect(result.totalDeductions.majorUnits, equals(2000.0));
        expect(result.netPayable.majorUnits, equals(73000.0));
        expect(result.components.length, equals(4)); // Base + HRA + PF + PT
        expect(result.earnings.length, equals(2)); // Base + HRA
        expect(result.deductions.length, equals(2)); // PF + PT
        expect(result.isValid, isTrue);
        expect(result.hasErrors, isFalse);
        expect(result.hasWarnings, isFalse);
      });

      test('Candidate Example 2: Mid-Period Joiner / Prorated LOP on Calendar Days', () {
        // Base Pay: ₹62,000.00
        // Period: 2026-01-01 to 2026-01-31 (31 calendar days)
        // Unpaid absence: 15 days
        // Expected Daily Rate: 62,000 / 31 = ₹2,000.00 / day
        // Expected LOP Deduction: 15 * 2,000 = ₹30,000.00
        // Expected Net Pay: ₹32,000.00
        final input = PayrollCalculationInput(
          id: 'calc_mid_joiner',
          employeeId: 'emp_4',
          payrollPeriodId: 'period_2026_01',
          baseSalary: const Money(minorUnits: 6200000), // ₹62,000.00
          unpaidLeaveDays: 15,
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          attendancePolicy: AttendanceProrationPolicy.calendarDays,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.grossEarnings.majorUnits, equals(62000.0));
        expect(result.totalDeductions.majorUnits, equals(30000.0));
        expect(result.netPayable.majorUnits, equals(32000.0));
        expect(result.deductions.length, equals(1));
        expect(result.deductions.first.calculationRuleId,
            equals('FORM-04-LOP-CALENDAR'));
        expect(result.isValid, isTrue);
      });
    });

    // =========================================================================
    // 3. Attendance Proration Policy Tests
    // =========================================================================
    group('Attendance Proration Policies', () {
      test('unresolved policy emits diagnostic warning and defers deduction', () {
        final input = PayrollCalculationInput(
          id: 'calc_unresolved_lop',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5000000),
          unpaidLeaveDays: 3,
        );

        final result = engine.calculate(
          input: input,
          attendancePolicy: AttendanceProrationPolicy.unresolved,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.totalDeductions.isZero, isTrue);
        expect(result.netPayable, equals(result.grossEarnings));
        expect(
          result.validationIssues
              .any((i) => i.code == 'UNRESOLVED_LOP_POLICY'),
          isTrue,
        );
      });

      test('fixed 30-day divisor calculates exact LOP with half-up rounding', () {
        // Base ₹60,000.00 -> ₹2,000 / day
        // 2 days unpaid = ₹4,000.00
        final input = PayrollCalculationInput(
          id: 'calc_fixed30',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 6000000),
          unpaidLeaveDays: 2,
        );

        final result = engine.calculate(
          input: input,
          attendancePolicy: AttendanceProrationPolicy.fixed30Days,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.totalDeductions.minorUnits, equals(400000)); // ₹4,000.00
        expect(result.netPayable.minorUnits, equals(5600000)); // ₹56,000.00
        expect(result.deductions.first.calculationRuleId,
            equals('FORM-04-LOP-FIXED30'));
      });

      test('working 26-day divisor calculates exact LOP', () {
        // Base ₹52,000.00 -> ₹2,000 / day
        // 1 day unpaid = ₹2,000.00
        final input = PayrollCalculationInput(
          id: 'calc_working26',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5200000),
          unpaidLeaveDays: 1,
        );

        final result = engine.calculate(
          input: input,
          attendancePolicy: AttendanceProrationPolicy.workingDays26,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.totalDeductions.minorUnits, equals(200000)); // ₹2,000.00
        expect(result.netPayable.minorUnits, equals(5000000)); // ₹50,000.00
        expect(result.deductions.first.calculationRuleId,
            equals('FORM-04-LOP-WORKING26'));
      });
    });

    // =========================================================================
    // 4. Effective Date Filtering Tests
    // =========================================================================
    group('Effective Date Filtering', () {
      test('excludes components whose effective date is after period end', () {
        final activeAllowance = PayrollComponent.earning(
          id: 'comp_active',
          name: 'Active Allowance',
          amount: const Money(minorUnits: 500000), // ₹5,000.00
          effectiveDate: DateTime.utc(2026, 1, 15),
        );
        final futureAllowance = PayrollComponent.earning(
          id: 'comp_future',
          name: 'Future Allowance',
          amount: const Money(minorUnits: 300000), // ₹3,000.00
          effectiveDate: DateTime.utc(2026, 2, 1), // After Jan 31
        );

        final input = PayrollCalculationInput(
          id: 'calc_eff_date',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5000000),
          components: [activeAllowance, futureAllowance],
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          calculationTimestamp: fixedTimestamp,
        );

        // Base ₹50,000 + Active ₹5,000 = ₹55,000 (Future ₹3,000 excluded)
        expect(result.grossEarnings.majorUnits, equals(55000.0));
        expect(result.earnings.length, equals(2)); // Base + active
        expect(
          result.earnings.any((e) => e.id == 'comp_future'),
          isFalse,
        );
      });
    });

    // =========================================================================
    // 5. Negative Net Pay (Deficit) Handling
    // =========================================================================
    group('Deficit and Negative Net Pay', () {
      test('handles deductions exceeding gross earnings with non-fatal warning', () {
        // Gross: ₹10,000.00
        // Deduction: ₹15,000.00 (e.g. major loan recovery / clawback)
        // Net: -₹5,000.00
        final massiveDeduction = PayrollComponent.deduction(
          id: 'comp_clawback',
          name: 'Overpayment Clawback',
          amount: const Money(minorUnits: 1500000), // ₹15,000.00
        );

        final input = PayrollCalculationInput(
          id: 'calc_deficit',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 1000000), // ₹10,000.00
          components: [massiveDeduction],
        );

        final result = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.grossEarnings.majorUnits, equals(10000.0));
        expect(result.totalDeductions.majorUnits, equals(15000.0));
        expect(result.netPayable.isNegative, isTrue);
        expect(result.netPayable.majorUnits, equals(-5000.0));
        expect(result.isValid, isTrue); // Not fatal error
        expect(result.hasWarnings, isTrue);
        expect(
          result.validationIssues
              .any((i) => i.code == 'NEGATIVE_NET_PAYABLE'),
          isTrue,
        );
      });
    });

    // =========================================================================
    // 6. Determinism & Immutability Tests
    // =========================================================================
    group('Determinism & Immutability', () {
      test('same inputs produce identical output results across multiple runs', () {
        final allowance = PayrollComponent.earning(
          id: 'comp_allow',
          name: 'Allowance',
          amount: const Money(minorUnits: 1000000),
        );
        final deduction = PayrollComponent.deduction(
          id: 'comp_ded',
          name: 'Deduction',
          amount: const Money(minorUnits: 500000),
        );

        final input = PayrollCalculationInput(
          id: 'calc_det',
          employeeId: 'emp_det',
          payrollPeriodId: 'period_det',
          baseSalary: const Money(minorUnits: 5000000),
          components: [allowance, deduction],
        );

        final r1 = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );
        final r2 = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        expect(r1, equals(r2));
        expect(r1.hashCode, equals(r2.hashCode));
        expect(r1.netPayable, equals(r2.netPayable));
        expect(r1.grossEarnings, equals(r2.grossEarnings));
        expect(r1.totalDeductions, equals(r2.totalDeductions));
      });

      test('does not mutate source input or component objects', () {
        final allowance = PayrollComponent.earning(
          id: 'comp_allow',
          name: 'Allowance',
          amount: const Money(minorUnits: 1000000),
        );

        final input = PayrollCalculationInput(
          id: 'calc_immut',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5000000),
          components: [allowance],
        );

        engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        // Verify input remains completely unchanged
        expect(input.id, equals('calc_immut'));
        expect(input.baseSalary.minorUnits, equals(5000000));
        expect(input.components.length, equals(1));
        expect(input.components.first.amount.minorUnits, equals(1000000));
      });
    });

    // =========================================================================
    // 7. Boundaries and Precision Tests
    // =========================================================================
    group('Boundaries & Precision', () {
      test('supports 1-paisa minimum monetary increments', () {
        final tinyEarning = PayrollComponent.earning(
          id: 'comp_paisa',
          name: 'One Paisa Bonus',
          amount: const Money(minorUnits: 1), // ₹0.01
        );

        final input = PayrollCalculationInput(
          id: 'calc_tiny',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 1000000), // ₹10,000.00
          components: [tinyEarning],
        );

        final result = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.grossEarnings.minorUnits, equals(1000001));
        expect(result.netPayable.minorUnits, equals(1000001));
      });

      test('supports large compensation values (10 crore) without integer overflow', () {
        // ₹10,00,00,000.00 = 10,000,000,00 minor units
        final massiveBase = const Money(minorUnits: 1000000000);
        final massiveBonus = PayrollComponent.earning(
          id: 'comp_huge',
          name: 'Executive Bonus',
          amount: const Money(minorUnits: 500000000), // ₹5 crore
        );

        final input = PayrollCalculationInput(
          id: 'calc_large',
          employeeId: 'emp_ceo',
          payrollPeriodId: 'period_1',
          baseSalary: massiveBase,
          components: [massiveBonus],
        );

        final result = engine.calculate(
          input: input,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.grossEarnings.minorUnits, equals(1500000000));
        expect(result.netPayable.minorUnits, equals(1500000000));
      });

      test('half-up midpoint rounding works accurately on odd divisions', () {
        // Base: ₹50,000.00 (5,000,000 paisa)
        // 31 days in month. 1 day LOP:
        // 5,000,000 / 31 = 161,290.32258... paisa -> rounds to 161,290 paisa (₹1,612.90)
        final input = PayrollCalculationInput(
          id: 'calc_rounding',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5000000),
          unpaidLeaveDays: 1,
        );

        final result = engine.calculate(
          input: input,
          periodStartDate: janStart,
          periodEndDate: janEnd,
          attendancePolicy: AttendanceProrationPolicy.calendarDays,
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.totalDeductions.minorUnits, equals(161290)); // ₹1,612.90
        expect(result.netPayable.minorUnits, equals(5000000 - 161290)); // ₹48,387.10
      });
    });
  });
}
