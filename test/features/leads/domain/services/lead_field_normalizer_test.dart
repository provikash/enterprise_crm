import 'package:enterprise_crm/features/leads/domain/services/lead_field_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeadFieldNormalizer', () {
    test('normalizePhone formats numbers correctly', () {
      expect(LeadFieldNormalizer.normalizePhone(null), isNull);
      expect(LeadFieldNormalizer.normalizePhone(''), isNull);
      expect(LeadFieldNormalizer.normalizePhone('+91 98765-43210'), '+919876543210');
      expect(LeadFieldNormalizer.normalizePhone('(022) 2411-9988'), '02224119988');
    });

    test('normalizeEmail lowercases and trims', () {
      expect(LeadFieldNormalizer.normalizeEmail(null), isNull);
      expect(LeadFieldNormalizer.normalizeEmail('   '), isNull);
      expect(
        LeadFieldNormalizer.normalizeEmail('  John.Doe@Example.COM  '),
        'john.doe@example.com',
      );
    });

    test('normalizeName capitalizes and cleans spaces', () {
      expect(LeadFieldNormalizer.normalizeName(null), isNull);
      expect(LeadFieldNormalizer.normalizeName('  '), isNull);
      expect(
        LeadFieldNormalizer.normalizeName('  vinay   kumar  chaudhary '),
        'Vinay Kumar Chaudhary',
      );
    });
  });
}
