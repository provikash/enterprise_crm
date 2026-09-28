import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollRecord Entity Tests (HR-6.2)', () {
    final validPayment = DateTime.utc(2026, 1, 31);
    final created = DateTime.utc(2026, 1, 15, 10, 0);
    final updated = DateTime.utc(2026, 1, 20, 12, 0);

    test('preserves all approved fields correctly', () {
      final record = PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 75000.0,
        netSalary: 65000.0,
        totalAllowances: 10000.0,
        totalDeductions: 20000.0,
        currency: 'INR',
        paymentStatus: 'Paid',
        paymentDate: validPayment,
        remarks: 'Processed on time',
        createdAt: created,
        updatedAt: updated,
      );

      expect(record.id, 'pay_rec_101');
      expect(record.employeeId, 'emp_1');
      expect(record.payrollPeriodId, 'period_2026_01');
      expect(record.grossSalary, 75000.0);
      expect(record.netSalary, 65000.0);
      expect(record.totalAllowances, 10000.0);
      expect(record.totalDeductions, 20000.0);
      expect(record.currency, 'INR');
      expect(record.paymentStatus, 'Paid');
      expect(record.paymentDate, DateTime.utc(2026, 1, 31));
      expect(record.remarks, 'Processed on time');
      expect(record.createdAt, created);
      expect(record.updatedAt, updated);
    });

    test('allows all optional fields to be null', () {
      final record = PayrollRecord(
        id: 'pay_rec_minimal',
        employeeId: 'emp_2',
        payrollPeriodId: 'period_2026_01',
      );

      expect(record.grossSalary, isNull);
      expect(record.netSalary, isNull);
      expect(record.totalAllowances, isNull);
      expect(record.totalDeductions, isNull);
      expect(record.currency, isNull);
      expect(record.paymentStatus, isNull);
      expect(record.paymentDate, isNull);
      expect(record.formattedPaymentDate, isNull);
      expect(record.remarks, isNull);
      expect(record.createdAt, isNull);
      expect(record.updatedAt, isNull);
    });

    test('distinguishes between null amount and zero amount', () {
      final nullRecord = PayrollRecord(
        id: 'pay_rec_null',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        netSalary: null,
      );

      final zeroRecord = PayrollRecord(
        id: 'pay_rec_zero',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        netSalary: 0.0,
      );

      expect(nullRecord.netSalary, isNull);
      expect(zeroRecord.netSalary, 0.0);
      expect(nullRecord.netSalary, isNot(equals(zeroRecord.netSalary)));
    });

    test('normalizes paymentDate to UTC midnight', () {
      final localDate = DateTime(2026, 1, 31, 18, 30, 45);

      final record = PayrollRecord(
        id: 'pay_rec_date',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        paymentDate: localDate,
      );

      expect(record.paymentDate, DateTime.utc(2026, 1, 31));
      expect(record.paymentDate!.hour, 0);
      expect(record.paymentDate!.minute, 0);
      expect(record.paymentDate!.isUtc, isTrue);
      expect(record.formattedPaymentDate, '2026-01-31');
    });

    test('throws ArgumentError on empty or whitespace id', () {
      expect(
        () => PayrollRecord(
          id: '',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_2026_01',
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollRecord(
          id: '   ',
          employeeId: 'emp_1',
          payrollPeriodId: 'period_2026_01',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on empty or whitespace employeeId', () {
      expect(
        () => PayrollRecord(
          id: 'pay_1',
          employeeId: '',
          payrollPeriodId: 'period_2026_01',
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollRecord(
          id: 'pay_1',
          employeeId: '   ',
          payrollPeriodId: 'period_2026_01',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on empty or whitespace payrollPeriodId', () {
      expect(
        () => PayrollRecord(
          id: 'pay_1',
          employeeId: 'emp_1',
          payrollPeriodId: '',
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollRecord(
          id: 'pay_1',
          employeeId: 'emp_1',
          payrollPeriodId: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('preserves employeeId referencing Employee.id without inference', () {
      const stableEmployeeId = 'emp_42';
      final record = PayrollRecord(
        id: 'pay_rec_rel',
        employeeId: stableEmployeeId,
        payrollPeriodId: 'period_2026_01',
      );

      expect(record.employeeId, stableEmployeeId);
      expect(record.employeeId, isNot(contains('@')));
      expect(record.employeeId, isNot(contains(' ')));
    });

    test('preserves payrollPeriodId referencing PayrollPeriod.id', () {
      const stablePeriodId = 'period_2026_01';
      final record = PayrollRecord(
        id: 'pay_rec_period',
        employeeId: 'emp_1',
        payrollPeriodId: stablePeriodId,
      );

      expect(record.payrollPeriodId, stablePeriodId);
    });

    test('copyWith preserves unchanged values', () {
      final original = PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 80000.0,
        netSalary: 70000.0,
        totalAllowances: 10000.0,
        totalDeductions: 20000.0,
        currency: 'USD',
        paymentStatus: 'Pending',
        paymentDate: validPayment,
        remarks: 'Original remark',
        createdAt: created,
        updatedAt: updated,
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(copy.id, original.id);
      expect(copy.employeeId, original.employeeId);
      expect(copy.payrollPeriodId, original.payrollPeriodId);
      expect(copy.grossSalary, original.grossSalary);
      expect(copy.netSalary, original.netSalary);
      expect(copy.totalAllowances, original.totalAllowances);
      expect(copy.totalDeductions, original.totalDeductions);
      expect(copy.currency, original.currency);
      expect(copy.paymentStatus, original.paymentStatus);
      expect(copy.paymentDate, original.paymentDate);
      expect(copy.remarks, original.remarks);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('copyWith updates specified fields', () {
      final original = PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        paymentStatus: 'Pending',
      );

      final updatedRecord = original.copyWith(
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 2, 1),
        netSalary: 62000.0,
      );

      expect(updatedRecord.id, 'pay_rec_101');
      expect(updatedRecord.paymentStatus, 'Paid');
      expect(updatedRecord.paymentDate, DateTime.utc(2026, 2, 1));
      expect(updatedRecord.netSalary, 62000.0);
      expect(updatedRecord.employeeId, 'emp_1');
    });

    test('copyWith supports explicit clearing of nullable fields', () {
      final original = PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 80000.0,
        netSalary: 70000.0,
        totalAllowances: 5000.0,
        totalDeductions: 15000.0,
        currency: 'INR',
        paymentStatus: 'Paid',
        paymentDate: validPayment,
        remarks: 'Bonus included',
      );

      final cleared = original.copyWith(
        clearGrossSalary: true,
        clearNetSalary: true,
        clearTotalAllowances: true,
        clearTotalDeductions: true,
        clearCurrency: true,
        clearPaymentStatus: true,
        clearPaymentDate: true,
        clearRemarks: true,
      );

      expect(cleared.grossSalary, isNull);
      expect(cleared.netSalary, isNull);
      expect(cleared.totalAllowances, isNull);
      expect(cleared.totalDeductions, isNull);
      expect(cleared.currency, isNull);
      expect(cleared.paymentStatus, isNull);
      expect(cleared.paymentDate, isNull);
      expect(cleared.remarks, isNull);
      // Non-cleared required fields preserved
      expect(cleared.id, 'pay_rec_101');
      expect(cleared.employeeId, 'emp_1');
      expect(cleared.payrollPeriodId, 'period_2026_01');
    });

    test('equality and hashCode contract', () {
      final recordA = PayrollRecord(
        id: 'pay_rec_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        netSalary: 50000.0,
        paymentStatus: 'Paid',
      );

      final recordB = PayrollRecord(
        id: 'pay_rec_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        netSalary: 50000.0,
        paymentStatus: 'Paid',
      );

      final recordDifferent = PayrollRecord(
        id: 'pay_rec_2',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        netSalary: 50000.0,
        paymentStatus: 'Paid',
      );

      expect(recordA, equals(recordB));
      expect(recordA.hashCode, equals(recordB.hashCode));
      expect(recordA, isNot(equals(recordDifferent)));
    });

    test('toString contains descriptive identifiers', () {
      final record = PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 75000.0,
        netSalary: 65000.0,
        paymentStatus: 'Paid',
      );

      final str = record.toString();
      expect(str, contains('pay_rec_101'));
      expect(str, contains('emp_1'));
      expect(str, contains('period_2026_01'));
      expect(str, contains('75000.0'));
      expect(str, contains('65000.0'));
      expect(str, contains('Paid'));
    });
  });
}
