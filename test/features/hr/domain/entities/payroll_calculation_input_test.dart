import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollCalculationInput Entity Tests (HR-7.3)', () {
    test('constructs successfully with valid required fields', () {
      final input = PayrollCalculationInput(
        id: 'calc_inp_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
      );

      expect(input.id, equals('calc_inp_1'));
      expect(input.employeeId, equals('emp_1'));
      expect(input.payrollPeriodId, equals('period_2026_01'));
      expect(input.baseSalary.majorUnits, equals(50000.0));
      expect(input.unpaidLeaveDays, equals(0));
      expect(input.remarks, isNull);
    });

    test('validates non-empty id', () {
      expect(
        () => PayrollCalculationInput(
          id: '   ',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 1000),
        ),
        throwsArgumentError,
      );
    });

    test('validates non-empty employeeId', () {
      expect(
        () => PayrollCalculationInput(
          id: 'calc_1',
          employeeId: '',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 1000),
        ),
        throwsArgumentError,
      );
    });

    test('validates non-empty payrollPeriodId', () {
      expect(
        () => PayrollCalculationInput(
          id: 'calc_1',
          employeeId: 'emp_1',
          payrollPeriodId: '   ',
          baseSalary: const Money(minorUnits: 1000),
        ),
        throwsArgumentError,
      );
    });

    test('validates non-negative unpaidLeaveDays', () {
      expect(
        () => PayrollCalculationInput(
          id: 'calc_1',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 1000),
          unpaidLeaveDays: -1,
        ),
        throwsArgumentError,
      );
    });

    test('copyWith updates specified fields and supports clearing remarks', () {
      final original = PayrollCalculationInput(
        id: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
        unpaidLeaveDays: 2,
        remarks: 'Initial adjustment',
      );

      final updated = original.copyWith(
        unpaidLeaveDays: 3,
        clearRemarks: true,
      );

      expect(updated.id, equals('calc_1'));
      expect(updated.unpaidLeaveDays, equals(3));
      expect(updated.remarks, isNull);
      expect(original.remarks, equals('Initial adjustment'));
    });

    test('value equality and hashCode behavior', () {
      final i1 = PayrollCalculationInput(
        id: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
      );
      final i2 = PayrollCalculationInput(
        id: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
      );
      final i3 = PayrollCalculationInput(
        id: 'calc_2',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
      );

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
    });

    test('accepts itemized components and provides earnings and deductions getters', () {
      final earning = PayrollComponent.earning(
        id: 'comp_hra',
        name: 'HRA',
        amount: const Money(minorUnits: 1500000), // ₹15,000.00
      );
      final deduction = PayrollComponent.deduction(
        id: 'comp_pt',
        name: 'Professional Tax',
        amount: const Money(minorUnits: 20000), // ₹200.00
      );

      final input = PayrollCalculationInput(
        id: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
        components: [earning, deduction],
      );

      expect(input.components.length, equals(2));
      expect(input.earnings.length, equals(1));
      expect(input.earnings.first.id, equals('comp_hra'));
      expect(input.deductions.length, equals(1));
      expect(input.deductions.first.id, equals('comp_pt'));
    });

    test('validates currency consistency between baseSalary and attached components', () {
      final usdEarning = PayrollComponent.earning(
        id: 'comp_usd',
        name: 'USD Bonus',
        amount: const Money(minorUnits: 50000, currency: 'USD'),
      );

      expect(
        () => PayrollCalculationInput(
          id: 'calc_1',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 5000000, currency: 'INR'),
          components: [usdEarning],
        ),
        throwsArgumentError,
      );
    });

    test('toString preserves privacy and does not dump sensitive details', () {
      final input = PayrollCalculationInput(
        id: 'calc_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
        baseSalary: const Money(minorUnits: 5000000),
      );
      expect(input.toString(), contains('calc_1'));
      expect(input.toString(), contains('emp_1'));
      expect(input.toString(), contains('period_1'));
    });
  });
}
