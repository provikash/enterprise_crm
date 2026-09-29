import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
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
