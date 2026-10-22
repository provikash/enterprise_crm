import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:enterprise_crm/features/auth/domain/repositories/auth_repository.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_account_store.dart';

void main() {
  group('MockAuthRepository OTP Tests (Phase 1)', () {
    late MockAccountStore store;
    late MockAuthRepository repository;

    setUp(() {
      store = MockAccountStore.seeded();
      repository = MockAuthRepository(accountStore: store);
    });

    test('sendPasswordResetOtp throws on empty or whitespace identifier', () async {
      expect(
        () => repository.sendPasswordResetOtp(identifier: '   '),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Please enter your User ID'),
          ),
        ),
      );
    });

    test('sendPasswordResetOtp throws on unknown user identifier', () async {
      expect(
        () => repository.sendPasswordResetOtp(identifier: 'non_existent_user'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('No account found'),
          ),
        ),
      );
    });

    test('sendPasswordResetOtp throws when account is disabled', () async {
      expect(
        () => repository.sendPasswordResetOtp(identifier: 'disabled_user'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Account is disabled'),
          ),
        ),
      );
    });

    test('sendPasswordResetOtp generates OTP and masks email for active user', () async {
      final result = await repository.sendPasswordResetOtp(identifier: 'admin');

      expect(result.identifier, equals('admin'));
      expect(result.maskedEmail, equals('ad***@enterprise-crm.internal'));
      expect(result.debugOtpCode, equals('123456'));
      expect(result.cooldownSeconds, equals(60));
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('sendPasswordResetOtp resolves full corporate email identifier correctly', () async {
      final result = await repository.sendPasswordResetOtp(
        identifier: 'user@enterprise-crm.internal',
      );

      expect(result.identifier, equals('user'));
      expect(result.maskedEmail, equals('us***@enterprise-crm.internal'));
      expect(result.debugOtpCode, equals('123456'));
    });

    test('verifyPasswordResetOtp validates code and decrements attempts on mismatch', () async {
      await repository.sendPasswordResetOtp(identifier: 'admin');

      // Attempt 1: wrong code
      expect(
        () => repository.verifyPasswordResetOtp(
          identifier: 'admin',
          otpCode: '000000',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('2 attempts remaining'),
          ),
        ),
      );

      // Attempt 2: correct code
      final verified = await repository.verifyPasswordResetOtp(
        identifier: 'admin',
        otpCode: '123456',
      );
      expect(verified, isTrue);
    });

    test('verifyPasswordResetOtp locks session after 3 consecutive incorrect attempts', () async {
      await repository.sendPasswordResetOtp(identifier: 'admin');

      // 1st wrong attempt
      try {
        await repository.verifyPasswordResetOtp(identifier: 'admin', otpCode: '111111');
      } catch (_) {}

      // 2nd wrong attempt
      try {
        await repository.verifyPasswordResetOtp(identifier: 'admin', otpCode: '222222');
      } catch (_) {}

      // 3rd wrong attempt: locks session
      expect(
        () => repository.verifyPasswordResetOtp(identifier: 'admin', otpCode: '333333'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Too many incorrect attempts'),
          ),
        ),
      );

      // Subsequent attempt fails as session was invalidated
      expect(
        () => repository.verifyPasswordResetOtp(identifier: 'admin', otpCode: '123456'),
        throwsA(isA<AuthException>()),
      );
    });

    test('verifyPasswordResetOtp rejects expired codes', () async {
      final shortLivedRepo = MockAuthRepository(
        accountStore: store,
        otpExpiryDuration: const Duration(milliseconds: 1),
      );

      await shortLivedRepo.sendPasswordResetOtp(identifier: 'admin');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        () => shortLivedRepo.verifyPasswordResetOtp(identifier: 'admin', otpCode: '123456'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
    });

    test('completePasswordResetWithOtp updates password and allows login with new credential', () async {
      await repository.sendPasswordResetOtp(identifier: 'user');
      await repository.verifyPasswordResetOtp(identifier: 'user', otpCode: '123456');

      // Reject passwords that are too short
      expect(
        () => repository.completePasswordResetWithOtp(
          identifier: 'user',
          otpCode: '123456',
          newPassword: '123',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('at least 6 characters'),
          ),
        ),
      );

      // Valid new password
      await repository.completePasswordResetWithOtp(
        identifier: 'user',
        otpCode: '123456',
        newPassword: 'NewSecurePassword123!',
      );

      // Old password no longer works
      expect(
        () => repository.login(userId: 'user', password: 'user123'),
        throwsA(isA<AuthException>()),
      );

      // New password works cleanly
      final user = await repository.login(
        userId: 'user',
        password: 'NewSecurePassword123!',
      );
      expect(user.id, equals('user'));
    });
  });
}
