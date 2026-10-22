import 'package:enterprise_crm/features/leads/presentation/utils/lead_field_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidOptionalLeadEmail', () {
    test('returns true for null', () {
      expect(isValidOptionalLeadEmail(null), isTrue);
    });

    test('returns true for empty string', () {
      expect(isValidOptionalLeadEmail(''), isTrue);
    });

    test('returns true for whitespace-only string', () {
      expect(isValidOptionalLeadEmail('   '), isTrue);
      expect(isValidOptionalLeadEmail('\t\n'), isTrue);
    });

    test('returns true for valid email containing @ and .', () {
      expect(isValidOptionalLeadEmail('alice@example.com'), isTrue);
      expect(isValidOptionalLeadEmail('a@b.co'), isTrue);
      expect(isValidOptionalLeadEmail('user.name@domain.co.in'), isTrue);
    });

    test('returns true when whitespace-padded email contains @ and .', () {
      expect(isValidOptionalLeadEmail('  alice@example.com  '), isTrue);
    });

    test('returns false when missing @', () {
      expect(isValidOptionalLeadEmail('alice.example.com'), isFalse);
    });

    test('returns false when missing dot', () {
      expect(isValidOptionalLeadEmail('alice@examplecom'), isFalse);
    });

    test('returns false when missing both @ and dot', () {
      expect(isValidOptionalLeadEmail('plainaddress'), isFalse);
    });
  });

  group('isValidOptionalLeadPhone', () {
    test('returns true for null or empty/whitespace', () {
      expect(isValidOptionalLeadPhone(null), isTrue);
      expect(isValidOptionalLeadPhone(''), isTrue);
      expect(isValidOptionalLeadPhone('   '), isTrue);
      expect(isValidOptionalLeadPhone('\t\n'), isTrue);
    });

    test('returns true for valid 10-15 digit mobile numbers in various formats', () {
      expect(isValidOptionalLeadPhone('+91 9876543210'), isTrue);
      expect(isValidOptionalLeadPhone('9876543210'), isTrue);
      expect(isValidOptionalLeadPhone('+919876543210'), isTrue);
      expect(isValidOptionalLeadPhone('+1 (555) 123-4567'), isTrue);
      expect(isValidOptionalLeadPhone('+44 7911 123456'), isTrue);
      expect(isValidOptionalLeadPhone('  +91 9876543210  '), isTrue);
      expect(isValidOptionalLeadPhone('98765-43210'), isTrue);
      expect(isValidOptionalLeadPhone('123456789012345'), isTrue); // 15 digits
    });

    test('returns false for numbers with fewer than 10 digits', () {
      expect(isValidOptionalLeadPhone('12345'), isFalse);
      expect(isValidOptionalLeadPhone('+91 1234'), isFalse);
      expect(isValidOptionalLeadPhone('987654321'), isFalse); // 9 digits
    });

    test('returns false for numbers with more than 15 digits', () {
      expect(isValidOptionalLeadPhone('1234567890123456'), isFalse); // 16 digits
    });

    test('returns false for strings containing invalid characters', () {
      expect(isValidOptionalLeadPhone('98765abcde'), isFalse);
      expect(isValidOptionalLeadPhone('+91 9876543210#'), isFalse);
      expect(isValidOptionalLeadPhone('call-me-now'), isFalse);
    });
  });
}

