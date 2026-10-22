import 'package:flutter_test/flutter_test.dart';

import 'package:enterprise_crm/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:enterprise_crm/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:enterprise_crm/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_account_store.dart';

void main() {
  group('ForgotPasswordCubit Tests (Phase 2)', () {
    late MockAccountStore store;
    late MockAuthRepository repository;
    late ForgotPasswordCubit cubit;

    setUp(() {
      store = MockAccountStore.seeded();
      repository = MockAuthRepository(accountStore: store);
      cubit = ForgotPasswordCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ForgotPasswordIdentifyState with empty identifier', () {
      expect(cubit.state, isA<ForgotPasswordIdentifyState>());
      final state = cubit.state as ForgotPasswordIdentifyState;
      expect(state.identifier, isEmpty);
      expect(state.isSubmitting, isFalse);
    });

    test('initial state pre-populates identifier when passed in constructor', () {
      final seededCubit = ForgotPasswordCubit(
        repository: repository,
        initialIdentifier: 'admin',
      );
      expect(seededCubit.state, isA<ForgotPasswordIdentifyState>());
      final state = seededCubit.state as ForgotPasswordIdentifyState;
      expect(state.identifier, equals('admin'));
      seededCubit.close();
    });

    test('updateIdentifier updates state and clears errors', () {
      cubit.updateIdentifier('user');
      final state = cubit.state as ForgotPasswordIdentifyState;
      expect(state.identifier, equals('user'));
      expect(state.errorMessage, isNull);
    });

    test('sendOtp emits error when identifier is empty', () async {
      await cubit.sendOtp();
      final state = cubit.state as ForgotPasswordIdentifyState;
      expect(state.errorMessage, contains('Please enter your User ID'));
    });

    test('sendOtp emits error when user is not found', () async {
      cubit.updateIdentifier('unknown_user_999');
      await cubit.sendOtp();
      final state = cubit.state as ForgotPasswordIdentifyState;
      expect(state.errorMessage, contains('No account found'));
    });

    test('sendOtp transitions to ForgotPasswordVerifyOtpState on success', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();

      expect(cubit.state, isA<ForgotPasswordVerifyOtpState>());
      final otpState = cubit.state as ForgotPasswordVerifyOtpState;
      expect(otpState.identifier, equals('admin'));
      expect(otpState.maskedEmail, equals('ad***@enterprise-crm.internal'));
      expect(otpState.debugOtpCode, equals('123456'));
      expect(otpState.cooldownSecondsRemaining, equals(60));
      expect(otpState.canResend, isFalse);
    });

    test('goToIdentifyStep transitions back to Step 1 preserving identifier', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();
      expect(cubit.state, isA<ForgotPasswordVerifyOtpState>());

      cubit.goToIdentifyStep();
      expect(cubit.state, isA<ForgotPasswordIdentifyState>());
      final state = cubit.state as ForgotPasswordIdentifyState;
      expect(state.identifier, equals('admin'));
    });

    test('verifyOtp validates code length', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();

      cubit.updateOtpCode('123');
      await cubit.verifyOtp();

      final state = cubit.state as ForgotPasswordVerifyOtpState;
      expect(state.errorMessage, contains('valid 6-digit'));
    });

    test('verifyOtp rejects incorrect code and reflects remaining attempts', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();

      cubit.updateOtpCode('000000');
      await cubit.verifyOtp();

      final state = cubit.state as ForgotPasswordVerifyOtpState;
      expect(state.errorMessage, contains('2 attempts remaining'));
    });

    test('verifyOtp transitions to ForgotPasswordSetNewPasswordState on valid code', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();

      cubit.updateOtpCode('123456');
      await cubit.verifyOtp();

      expect(cubit.state, isA<ForgotPasswordSetNewPasswordState>());
      final passState = cubit.state as ForgotPasswordSetNewPasswordState;
      expect(passState.identifier, equals('admin'));
      expect(passState.otpCode, equals('123456'));
    });

    test('completeReset validates password match and minimum length', () async {
      cubit.updateIdentifier('admin');
      await cubit.sendOtp();
      cubit.updateOtpCode('123456');
      await cubit.verifyOtp();

      // Mismatch
      await cubit.completeReset(
        newPassword: 'Password123',
        confirmPassword: 'Password456',
      );
      var state = cubit.state as ForgotPasswordSetNewPasswordState;
      expect(state.errorMessage, contains('Passwords do not match'));

      // Too short
      await cubit.completeReset(
        newPassword: '123',
        confirmPassword: '123',
      );
      state = cubit.state as ForgotPasswordSetNewPasswordState;
      expect(state.errorMessage, contains('at least 6 characters'));
    });

    test('completeReset transitions to ForgotPasswordSuccessState and updates credentials', () async {
      cubit.updateIdentifier('user');
      await cubit.sendOtp();
      cubit.updateOtpCode('123456');
      await cubit.verifyOtp();

      await cubit.completeReset(
        newPassword: 'BrandNewSecurePassword123!',
        confirmPassword: 'BrandNewSecurePassword123!',
      );

      expect(cubit.state, isA<ForgotPasswordSuccessState>());
      final successState = cubit.state as ForgotPasswordSuccessState;
      expect(successState.identifier, equals('user'));

      // Verify that the new credentials are live in AuthRepository
      final loggedInUser = await repository.login(
        userId: 'user',
        password: 'BrandNewSecurePassword123!',
      );
      expect(loggedInUser.id, equals('user'));
    });
  });
}
