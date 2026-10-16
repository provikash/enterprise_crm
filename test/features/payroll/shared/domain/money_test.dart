import 'package:enterprise_crm/features/payroll/shared/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parses paise without floating point', () {
      expect(Money.parse('₹1,23,456.78').paise, 12345678);
      expect(Money.parse('-0.05').paise, -5);
      expect(Money.parse('42').paise, 4200);
    });

    test('formats Indian grouping and negatives', () {
      expect(const Money(123456789).format(), '₹12,34,567.89');
      expect(const Money(-501).format(), '-₹5.01');
    });

    test('rejects excess precision and unsafe range', () {
      expect(() => Money.parse('1.001'), throwsFormatException);
      expect(() => Money.parse('90071992547410.00'), throwsFormatException);
    });

    test('adds and subtracts exactly', () {
      expect((const Money(101) + const Money(202)).paise, 303);
      expect((const Money(101) - const Money(202)).paise, -101);
    });
  });
}
