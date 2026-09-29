import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money Value Object Tests (HR-7.3)', () {
    test('constructs exact minor units with default currency (INR)', () {
      const money = Money(minorUnits: 5000000);
      expect(money.minorUnits, equals(5000000));
      expect(money.currency, equals('INR'));
      expect(money.majorUnits, equals(50000.0));
      expect(money.isPositive, isTrue);
      expect(money.isZero, isFalse);
      expect(money.isNegative, isFalse);
    });

    test('constructs from major units with exact half-up rounding', () {
      final m1 = Money.fromMajorUnits(100.50);
      expect(m1.minorUnits, equals(10050));
      expect(m1.majorUnits, equals(100.50));

      final m2 = Money.fromMajorUnits(100.555);
      expect(m2.minorUnits, equals(10056)); // rounds half-up

      final m3 = Money.fromMajorUnits(0);
      expect(m3.minorUnits, equals(0));
      expect(m3.isZero, isTrue);
    });

    test('constructs from paisa alias', () {
      final money = Money.fromPaisa(75000);
      expect(money.minorUnits, equals(75000));
      expect(money.majorUnits, equals(750.0));
    });

    test('zero constructor creates exact zero amount', () {
      const z1 = Money.zero();
      expect(z1.minorUnits, equals(0));
      expect(z1.currency, equals('INR'));
      expect(z1.isZero, isTrue);
      expect(z1.isPositive, isFalse);
      expect(z1.isNegative, isFalse);

      const z2 = Money.zero(currency: 'USD');
      expect(z2.minorUnits, equals(0));
      expect(z2.currency, equals('USD'));
    });

    test('addition adds minor units and preserves currency', () {
      const m1 = Money(minorUnits: 150000); // 1,500.00
      const m2 = Money(minorUnits: 50000);  // 500.00
      final result = m1 + m2;

      expect(result.minorUnits, equals(200000));
      expect(result.majorUnits, equals(2000.0));
      expect(result.currency, equals('INR'));
    });

    test('subtraction subtracts minor units and preserves currency', () {
      const m1 = Money(minorUnits: 150000);
      const m2 = Money(minorUnits: 50000);
      final result = m1 - m2;

      expect(result.minorUnits, equals(100000));
      expect(result.majorUnits, equals(1000.0));
      expect(result.currency, equals('INR'));
    });

    test('subtraction resulting in negative value flags isNegative', () {
      const m1 = Money(minorUnits: 50000);
      const m2 = Money(minorUnits: 150000);
      final result = m1 - m2;

      expect(result.minorUnits, equals(-100000));
      expect(result.isNegative, isTrue);
      expect(result.isPositive, isFalse);
      expect(result.abs().minorUnits, equals(100000));
    });

    test('multiplication multiplies minor units by scalar with rounding', () {
      const m = Money(minorUnits: 10000); // 100.00
      final doubled = m * 2;
      expect(doubled.minorUnits, equals(20000));

      final half = m * 0.5;
      expect(half.minorUnits, equals(5000));

      final third = m * 0.333333;
      expect(third.minorUnits, equals(3333));
    });

    test('cross-currency operations throw ArgumentError', () {
      const inr = Money(minorUnits: 10000, currency: 'INR');
      const usd = Money(minorUnits: 10000, currency: 'USD');

      expect(() => inr + usd, throwsArgumentError);
      expect(() => inr - usd, throwsArgumentError);
      expect(() => inr.compareTo(usd), throwsArgumentError);
    });

    test('comparisons work accurately on same currency', () {
      const m10 = Money(minorUnits: 1000);
      const m20 = Money(minorUnits: 2000);
      const m10Duplicate = Money(minorUnits: 1000);

      expect(m10 < m20, isTrue);
      expect(m10 <= m20, isTrue);
      expect(m20 > m10, isTrue);
      expect(m20 >= m10, isTrue);
      expect(m10 <= m10Duplicate, isTrue);
      expect(m10 >= m10Duplicate, isTrue);
    });

    test('value equality and hashCode behavior', () {
      const m1 = Money(minorUnits: 5000, currency: 'INR');
      const m2 = Money(minorUnits: 5000, currency: 'INR');
      const m3 = Money(minorUnits: 6000, currency: 'INR');
      const m4 = Money(minorUnits: 5000, currency: 'USD');

      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
      expect(m1, isNot(equals(m3)));
      expect(m1, isNot(equals(m4)));
    });

    test('formatted returns localized currency string', () {
      const inr = Money(minorUnits: 5000000, currency: 'INR'); // ₹50,000.00
      expect(inr.formatted, contains('50,000.00'));

      const usd = Money(minorUnits: 125000, currency: 'USD'); // $1,250.00
      expect(usd.formatted, contains('1,250.00'));
    });

    test('toString does not expose excessive personal info', () {
      const m = Money(minorUnits: 45000, currency: 'INR');
      expect(m.toString(), equals('Money(45000 INR)'));
    });
  });
}
