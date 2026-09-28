import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollPeriod Entity Tests (HR-6.2)', () {
    final validStart = DateTime.utc(2026, 1, 1);
    final validEnd = DateTime.utc(2026, 1, 31);
    final validPayment = DateTime.utc(2026, 1, 31);
    final created = DateTime.utc(2026, 1, 1, 9, 0);
    final updated = DateTime.utc(2026, 1, 15, 14, 30);

    test('preserves all approved fields correctly', () {
      final period = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
        createdAt: created,
        updatedAt: updated,
      );

      expect(period.id, 'period_2026_01');
      expect(period.name, 'January 2026');
      expect(period.startDate, DateTime.utc(2026, 1, 1));
      expect(period.endDate, DateTime.utc(2026, 1, 31));
      expect(period.paymentDate, DateTime.utc(2026, 1, 31));
      expect(period.createdAt, created);
      expect(period.updatedAt, updated);
    });

    test('normalizes start, end, and payment dates to UTC midnight', () {
      final localStart = DateTime(2026, 2, 1, 15, 45, 30);
      final localEnd = DateTime(2026, 2, 28, 23, 59, 59);
      final localPayment = DateTime(2026, 3, 1, 10, 0, 0);

      final period = PayrollPeriod(
        id: 'period_2026_02',
        name: 'February 2026',
        startDate: localStart,
        endDate: localEnd,
        paymentDate: localPayment,
      );

      expect(period.startDate, DateTime.utc(2026, 2, 1));
      expect(period.startDate.hour, 0);
      expect(period.startDate.minute, 0);
      expect(period.startDate.second, 0);
      expect(period.startDate.isUtc, isTrue);

      expect(period.endDate, DateTime.utc(2026, 2, 28));
      expect(period.endDate.hour, 0);
      expect(period.endDate.isUtc, isTrue);

      expect(period.paymentDate, DateTime.utc(2026, 3, 1));
      expect(period.paymentDate!.hour, 0);
      expect(period.paymentDate!.isUtc, isTrue);
    });

    test('allows paymentDate to be null', () {
      final period = PayrollPeriod(
        id: 'period_2026_03',
        name: 'March 2026',
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 3, 31),
      );

      expect(period.paymentDate, isNull);
      expect(period.formattedPaymentDate, isNull);
    });

    test('allows startDate equal to endDate (single-day period)', () {
      final singleDay = DateTime.utc(2026, 4, 15);
      final period = PayrollPeriod(
        id: 'period_single',
        name: 'Mid-Month Adjustment',
        startDate: singleDay,
        endDate: singleDay,
      );

      expect(period.startDate, period.endDate);
      expect(period.formattedPeriod, '2026-04-15 – 2026-04-15');
    });

    test('throws ArgumentError when startDate is after endDate', () {
      expect(
        () => PayrollPeriod(
          id: 'invalid_period',
          name: 'Invalid Period',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 1, 1),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on empty or whitespace id', () {
      expect(
        () => PayrollPeriod(
          id: '',
          name: 'January 2026',
          startDate: validStart,
          endDate: validEnd,
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollPeriod(
          id: '   ',
          name: 'January 2026',
          startDate: validStart,
          endDate: validEnd,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on empty or whitespace name', () {
      expect(
        () => PayrollPeriod(
          id: 'period_01',
          name: '',
          startDate: validStart,
          endDate: validEnd,
        ),
        throwsArgumentError,
      );

      expect(
        () => PayrollPeriod(
          id: 'period_01',
          name: '   ',
          startDate: validStart,
          endDate: validEnd,
        ),
        throwsArgumentError,
      );
    });

    test('formattedPeriod returns correct YYYY-MM-DD range format', () {
      final period = PayrollPeriod(
        id: 'period_test',
        name: 'Q1',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 3, 31),
      );

      expect(period.formattedPeriod, '2026-01-01 – 2026-03-31');
    });

    test('formattedPaymentDate returns YYYY-MM-DD format', () {
      final period = PayrollPeriod(
        id: 'period_test',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: DateTime.utc(2026, 2, 5),
      );

      expect(period.formattedPaymentDate, '2026-02-05');
    });

    test('copyWith preserves unchanged values', () {
      final original = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
        createdAt: created,
        updatedAt: updated,
      );

      final copy = original.copyWith();

      expect(copy, equals(original));
      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.startDate, original.startDate);
      expect(copy.endDate, original.endDate);
      expect(copy.paymentDate, original.paymentDate);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
    });

    test('copyWith updates specified fields', () {
      final original = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
      );

      final updatedPeriod = original.copyWith(
        name: 'January 2026 Final',
        paymentDate: DateTime.utc(2026, 2, 2),
      );

      expect(updatedPeriod.id, 'period_2026_01');
      expect(updatedPeriod.name, 'January 2026 Final');
      expect(updatedPeriod.paymentDate, DateTime.utc(2026, 2, 2));
      expect(updatedPeriod.startDate, validStart);
    });

    test('copyWith clearPaymentDate sets paymentDate to null', () {
      final original = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
      );

      final cleared = original.copyWith(clearPaymentDate: true);

      expect(cleared.paymentDate, isNull);
    });

    test('equality and hashCode contract', () {
      final periodA = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
      );

      final periodB = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
      );

      final periodDifferent = PayrollPeriod(
        id: 'period_2026_02',
        name: 'February 2026',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 2, 28),
      );

      expect(periodA, equals(periodB));
      expect(periodA.hashCode, equals(periodB.hashCode));
      expect(periodA, isNot(equals(periodDifferent)));
    });

    test('toString contains descriptive identifiers', () {
      final period = PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: validStart,
        endDate: validEnd,
        paymentDate: validPayment,
      );

      final str = period.toString();
      expect(str, contains('period_2026_01'));
      expect(str, contains('January 2026'));
      expect(str, contains('2026-01-01 – 2026-01-31'));
      expect(str, contains('2026-01-31'));
    });
  });
}
