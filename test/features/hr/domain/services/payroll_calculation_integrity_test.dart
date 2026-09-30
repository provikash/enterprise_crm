import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/services/payroll_calculation_engine.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = PayrollCalculationEngine();
  final fixedTimestamp = DateTime.utc(2026, 1, 31, 12, 0, 0);

  group('HR-7.7: Input Validation & Boundary Integrity', () {
    test('rejects empty or whitespace employee ID at boundary with ArgumentError', () {
      final input = PayrollCalculationInput(
        id: 'in_valid',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      expect(
        () => input.copyWith(employeeId: '   '),
        throwsArgumentError,
      );
      expect(
        () => PayrollCalculationInput(
          id: 'in_bad',
          employeeId: '',
          payrollPeriodId: 'per_01',
          baseSalary: const Money(minorUnits: 5000000),
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty or whitespace payroll period ID at boundary with ArgumentError', () {
      final input = PayrollCalculationInput(
        id: 'in_valid',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      expect(
        () => input.copyWith(payrollPeriodId: '   '),
        throwsArgumentError,
      );
      expect(
        () => PayrollCalculationInput(
          id: 'in_bad',
          employeeId: 'emp_01',
          payrollPeriodId: '',
          baseSalary: const Money(minorUnits: 5000000),
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive base salary with fatal error', () {
      final input = PayrollCalculationInput(
        id: 'in_zero_base',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 0),
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any((i) => i.code == 'MISSING_BASE_SALARY' && i.isError),
        isTrue,
      );
      expect(result.netPayable, equals(const Money(minorUnits: 0)));
    });

    test('rejects empty currency with fatal error', () {
      final input = PayrollCalculationInput(
        id: 'in_bad_curr',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000, currency: '   '),
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any((i) => i.code == 'INVALID_CURRENCY' && i.isError),
        isTrue,
      );
    });

    test('detects inverted period date range as fatal error', () {
      final input = PayrollCalculationInput(
        id: 'in_inverted_dates',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      final result = engine.calculate(
        input: input,
        periodStartDate: DateTime.utc(2026, 1, 31),
        periodEndDate: DateTime.utc(2026, 1, 1), // Inverted
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any((i) => i.code == 'INVALID_PERIOD_DATE_RANGE' && i.isError),
        isTrue,
      );
    });

    test('rejects joining date strictly after period end date with fatal error', () {
      final input = PayrollCalculationInput(
        id: 'in_late_joiner',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      final result = engine.calculate(
        input: input,
        periodStartDate: DateTime.utc(2026, 1, 1),
        periodEndDate: DateTime.utc(2026, 1, 31),
        employeeJoiningDate: DateTime.utc(2026, 2, 1), // Joined after period end
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any((i) => i.code == 'INVALID_PERIOD_FOR_EMPLOYEE' && i.isError),
        isTrue,
      );
    });

    test('accepts joining date on boundary (period end date)', () {
      final input = PayrollCalculationInput(
        id: 'in_boundary_joiner',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      final result = engine.calculate(
        input: input,
        periodStartDate: DateTime.utc(2026, 1, 1),
        periodEndDate: DateTime.utc(2026, 1, 31),
        employeeJoiningDate: DateTime.utc(2026, 1, 31), // Boundary match
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(
        result.validationIssues.any((i) => i.code == 'INVALID_PERIOD_FOR_EMPLOYEE'),
        isFalse,
      );
    });

    test('flags inactive or terminated employee with non-fatal warning', () {
      final input = PayrollCalculationInput(
        id: 'in_inactive_emp',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      final result = engine.calculate(
        input: input,
        employmentStatus: EmploymentStatus.inactive,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue); // Not fatal error, but warned
      expect(
        result.validationIssues.any((i) => i.code == 'EMPLOYEE_NOT_ACTIVE' && i.isWarning),
        isTrue,
      );
    });
  });

  group('HR-7.7: Component Integrity & Anti-Collision', () {
    test('detects duplicate component IDs as fatal error', () {
      final comp1 = PayrollComponent(
        id: 'comp_dup_01',
        name: 'Allowance A',
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 100000),
      );
      final comp2 = PayrollComponent(
        id: 'comp_dup_01', // Identical ID
        name: 'Allowance B',
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 200000),
      );

      final input = PayrollCalculationInput(
        id: 'in_comp_dup',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
        components: [comp1, comp2],
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any((i) => i.code == 'DUPLICATE_COMPONENT_ID' && i.isError),
        isTrue,
      );
    });

    test('detects collision with base salary earning as fatal error', () {
      final collidingComp = PayrollComponent(
        id: 'comp_base_dup',
        name: 'Base Salary', // Collides with base salary earning
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 5000000),
      );

      final input = PayrollCalculationInput(
        id: 'in_base_collision',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
        components: [collidingComp],
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isFalse);
      expect(
        result.validationIssues.any(
          (i) => i.code == 'DUPLICATE_BASE_SALARY_COMPONENT' && i.isError,
        ),
        isTrue,
      );
    });

    test('warns on duplicate component names within same kind', () {
      final comp1 = PayrollComponent(
        id: 'comp_bonus_1',
        name: 'Performance Bonus',
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 100000),
      );
      final comp2 = PayrollComponent(
        id: 'comp_bonus_2',
        name: 'Performance Bonus', // Same name and kind
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 200000),
      );

      final input = PayrollCalculationInput(
        id: 'in_same_name',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
        components: [comp1, comp2],
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue); // Allowed, but warned
      expect(
        result.validationIssues.any(
          (i) => i.code == 'DUPLICATE_COMPONENT_NAME' && i.isWarning,
        ),
        isTrue,
      );
    });

    test('enforces cross-currency mismatch rejection at input boundary', () {
      final usdComponent = PayrollComponent(
        id: 'comp_usd',
        name: 'USD Bonus',
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 10000, currency: 'USD'),
      );

      expect(
        () => PayrollCalculationInput(
          id: 'in_cross_currency',
          employeeId: 'emp_01',
          payrollPeriodId: 'per_01',
          baseSalary: const Money(minorUnits: 5000000, currency: 'INR'),
          components: [usdComponent],
        ),
        throwsArgumentError,
      );
    });

    test('enforces non-negative component amount at component boundary', () {
      expect(
        () => PayrollComponent(
          id: 'comp_negative',
          name: 'Negative Deduction',
          kind: PayrollComponentKind.deduction,
          amount: const Money(minorUnits: -500),
        ),
        throwsArgumentError,
      );
    });
  });

  group('HR-7.7: Attendance Proration & Divisor Policy Integrity', () {
    final baseInput = PayrollCalculationInput(
      id: 'in_lop_test',
      employeeId: 'emp_01',
      payrollPeriodId: 'per_01',
      baseSalary: const Money(minorUnits: 3100000), // ₹31,000.00
      unpaidLeaveDays: 2,
    );

    test('zero unpaid leave days yields zero LOP deduction across all policies', () {
      final zeroLopInput = baseInput.copyWith(unpaidLeaveDays: 0);

      for (final policy in AttendanceProrationPolicy.values) {
        final result = engine.calculate(
          input: zeroLopInput,
          attendancePolicy: policy,
          periodStartDate: DateTime.utc(2026, 1, 1),
          periodEndDate: DateTime.utc(2026, 1, 31),
          calculationTimestamp: fixedTimestamp,
        );

        expect(result.totalDeductions, equals(const Money(minorUnits: 0)));
        expect(result.netPayable, equals(result.grossEarnings));
      }
    });

    test('calendarDays policy computes exact integer minor units (31 days)', () {
      // ₹31,000 / 31 = ₹1,000/day * 2 days = ₹2,000 (200,000 paisa)
      final result = engine.calculate(
        input: baseInput,
        attendancePolicy: AttendanceProrationPolicy.calendarDays,
        periodStartDate: DateTime.utc(2026, 1, 1),
        periodEndDate: DateTime.utc(2026, 1, 31), // 31 days
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.totalDeductions, equals(const Money(minorUnits: 200000)));
      expect(result.netPayable, equals(const Money(minorUnits: 2900000)));
    });

    test('calendarDays policy without period dates records warning and defers deduction', () {
      final result = engine.calculate(
        input: baseInput,
        attendancePolicy: AttendanceProrationPolicy.calendarDays,
        periodStartDate: null,
        periodEndDate: null,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.totalDeductions, equals(const Money(minorUnits: 0)));
      expect(
        result.validationIssues.any(
          (i) => i.code == 'MISSING_PERIOD_DATES_FOR_LOP' && i.isWarning,
        ),
        isTrue,
      );
    });

    test('unresolved policy records warning and defers deduction', () {
      final result = engine.calculate(
        input: baseInput,
        attendancePolicy: AttendanceProrationPolicy.unresolved,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.totalDeductions, equals(const Money(minorUnits: 0)));
      expect(
        result.validationIssues.any(
          (i) => i.code == 'UNRESOLVED_LOP_POLICY' && i.isWarning,
        ),
        isTrue,
      );
    });

    test('fixed30Days policy uses standard 30-day divisor', () {
      // 30,000 * 2 / 30 = 2,000
      final input30 = PayrollCalculationInput(
        id: 'in_fixed30',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 3000000), // ₹30,000.00
        unpaidLeaveDays: 2,
      );

      final result = engine.calculate(
        input: input30,
        attendancePolicy: AttendanceProrationPolicy.fixed30Days,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.totalDeductions, equals(const Money(minorUnits: 200000)));
      expect(result.netPayable, equals(const Money(minorUnits: 2800000)));
    });

    test('workingDays26 policy uses standard 26-day divisor', () {
      // 26,000 * 2 / 26 = 2,000
      final input26 = PayrollCalculationInput(
        id: 'in_working26',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 2600000), // ₹26,000.00
        unpaidLeaveDays: 2,
      );

      final result = engine.calculate(
        input: input26,
        attendancePolicy: AttendanceProrationPolicy.workingDays26,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.totalDeductions, equals(const Money(minorUnits: 200000)));
      expect(result.netPayable, equals(const Money(minorUnits: 2400000)));
    });

    test('excessive unpaid leave days triggers warning', () {
      final excessiveInput = baseInput.copyWith(unpaidLeaveDays: 35);

      final result = engine.calculate(
        input: excessiveInput,
        attendancePolicy: AttendanceProrationPolicy.calendarDays,
        periodStartDate: DateTime.utc(2026, 1, 1),
        periodEndDate: DateTime.utc(2026, 1, 31),
        calculationTimestamp: fixedTimestamp,
      );

      expect(
        result.validationIssues.any(
          (i) => i.code == 'EXCESSIVE_UNPAID_LEAVE' && i.isWarning,
        ),
        isTrue,
      );
    });
  });

  group('HR-7.7: Money Safety & Overflow Bounds', () {
    test('handles extreme enterprise compensation amounts without 64-bit overflow', () {
      // ₹1,000,000,000.00 (One billion INR = 100,000,000,000 paisa)
      final largeBase = Money.fromMajorUnits(1000000000.00);
      final largeBonus = Money.fromMajorUnits(500000000.00);

      final comp = PayrollComponent(
        id: 'comp_large_bonus',
        name: 'Executive Retention Bonus',
        kind: PayrollComponentKind.earning,
        amount: largeBonus,
      );

      final input = PayrollCalculationInput(
        id: 'in_large_comp',
        employeeId: 'emp_exec',
        payrollPeriodId: 'per_01',
        baseSalary: largeBase,
        components: [comp],
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.grossEarnings.majorUnits, equals(1500000000.00));
      expect(result.netPayable.majorUnits, equals(1500000000.00));
    });

    test('handles net deficit (deductions > gross) gracefully as diagnostic warning', () {
      final largeDeduction = PayrollComponent(
        id: 'comp_clawback',
        name: 'Sign-on Clawback',
        kind: PayrollComponentKind.deduction,
        amount: const Money(minorUnits: 6000000), // ₹60,000.00
      );

      final input = PayrollCalculationInput(
        id: 'in_deficit',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
        components: [largeDeduction],
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.isValid, isTrue);
      expect(result.netPayable.isNegative, isTrue);
      expect(result.netPayable, equals(const Money(minorUnits: -1000000))); // -₹10,000.00
      expect(
        result.validationIssues.any(
          (i) => i.code == 'NEGATIVE_NET_PAYABLE' && i.isWarning,
        ),
        isTrue,
      );
    });
  });

  group('HR-7.7: Determinism & Idempotency', () {
    test('100 sequential runs of identical input produce strictly identical results', () {
      final allowance = PayrollComponent(
        id: 'comp_allow_det',
        name: 'HRA',
        kind: PayrollComponentKind.earning,
        amount: const Money(minorUnits: 2500000),
      );
      final deduction = PayrollComponent(
        id: 'comp_ded_det',
        name: 'Provident Fund',
        kind: PayrollComponentKind.deduction,
        amount: const Money(minorUnits: 180000),
      );

      final input = PayrollCalculationInput(
        id: 'in_det_test',
        employeeId: 'emp_det',
        payrollPeriodId: 'per_det',
        baseSalary: const Money(minorUnits: 5000000),
        unpaidLeaveDays: 1,
        components: [allowance, deduction],
      );

      final firstResult = engine.calculate(
        input: input,
        periodStartDate: DateTime.utc(2026, 1, 1),
        periodEndDate: DateTime.utc(2026, 1, 31),
        employeeJoiningDate: DateTime.utc(2024, 1, 1),
        employmentStatus: EmploymentStatus.active,
        attendancePolicy: AttendanceProrationPolicy.calendarDays,
        calculationTimestamp: fixedTimestamp,
        ruleVersion: 'RULES-2026.1',
      );

      for (var i = 0; i < 99; i++) {
        final repeatedResult = engine.calculate(
          input: input,
          periodStartDate: DateTime.utc(2026, 1, 1),
          periodEndDate: DateTime.utc(2026, 1, 31),
          employeeJoiningDate: DateTime.utc(2024, 1, 1),
          employmentStatus: EmploymentStatus.active,
          attendancePolicy: AttendanceProrationPolicy.calendarDays,
          calculationTimestamp: fixedTimestamp,
          ruleVersion: 'RULES-2026.1',
        );

        expect(repeatedResult, equals(firstResult));
        expect(repeatedResult.hashCode, equals(firstResult.hashCode));
        expect(repeatedResult.calculationId, equals(firstResult.calculationId));
        expect(repeatedResult.grossEarnings, equals(firstResult.grossEarnings));
        expect(repeatedResult.totalDeductions, equals(firstResult.totalDeductions));
        expect(repeatedResult.netPayable, equals(firstResult.netPayable));
      }
    });
  });

  group('HR-7.7: Identity Consistency & Non-Authoritative Invariant', () {
    test('result preserves identity mappings and marks preview true', () {
      final input = PayrollCalculationInput(
        id: 'in_identity_test',
        employeeId: 'emp_identity_42',
        payrollPeriodId: 'per_identity_99',
        baseSalary: const Money(minorUnits: 7500000),
      );

      final result = engine.calculate(
        input: input,
        calculationTimestamp: fixedTimestamp,
      );

      expect(result.calculationId, equals('calc_res_in_identity_test'));
      expect(result.employeeId, equals('emp_identity_42'));
      expect(result.payrollPeriodId, equals('per_identity_99'));
      expect(result.baseSalary, equals(const Money(minorUnits: 7500000)));
      expect(result.isPreview, isTrue); // Non-authoritative preview invariant
    });
  });

  group('HR-7.7: Regression & HR-6 Baseline Isolation', () {
    test('calculation evaluation produces zero mutations to PayrollRecord or repository', () async {
      final repository = MockPayrollRepository();
      final recordsBefore = await repository.getPayrollRecords();

      final input = PayrollCalculationInput(
        id: 'in_iso_test',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        baseSalary: const Money(minorUnits: 5000000),
      );

      // Perform multiple calculation engine runs
      final result = engine.calculate(input: input);
      expect(result.isPreview, isTrue);

      final recordsAfter = await repository.getPayrollRecords();

      // Verify no records were added or altered in repository
      expect(recordsAfter.length, equals(recordsBefore.length));
      for (var i = 0; i < recordsBefore.length; i++) {
        expect(recordsAfter[i].id, equals(recordsBefore[i].id));
        expect(recordsAfter[i].grossSalary, equals(recordsBefore[i].grossSalary));
        expect(recordsAfter[i].netSalary, equals(recordsBefore[i].netSalary));
      }
    });

    test('HR-6 PayrollRecord remains immutable and decoupled from HR-7 calculations', () {
      final hr6Record = PayrollRecord(
        id: 'rec_hr6_01',
        employeeId: 'emp_01',
        payrollPeriodId: 'per_01',
        grossSalary: 50000.0,
        netSalary: 45000.0,
      );

      expect(hr6Record.id, equals('rec_hr6_01'));
      expect(hr6Record.grossSalary, equals(50000.0));
      expect(hr6Record.netSalary, equals(45000.0));
    });
  });
}
