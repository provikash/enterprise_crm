import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

/// State machine managing the 3-step Email OTP password recovery flow:
/// 1. [ForgotPasswordIdentifyState] - Account identification
/// 2. [ForgotPasswordVerifyOtpState] - OTP verification & resend cooldown
/// 3. [ForgotPasswordSetNewPasswordState] - New credential establishment
/// 4. [ForgotPasswordSuccessState] - Confirmation & dismissal
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repository;
  Timer? _cooldownTimer;

  ForgotPasswordCubit({
    required AuthRepository repository,
    String initialIdentifier = '',
  }) : _repository = repository,
       super(
         ForgotPasswordIdentifyState(
           identifier: initialIdentifier.trim(),
         ),
       );

  /// Updates the User ID / Email identifier on Step 1.
  void updateIdentifier(String value) {
    final current = state;
    if (current is ForgotPasswordIdentifyState) {
      emit(current.copyWith(identifier: value, clearError: true));
    }
  }

  /// Returns from Step 2 back to Step 1 to allow changing the account identifier.
  void goToIdentifyStep() {
    _cooldownTimer?.cancel();
    final current = state;
    String id = '';
    if (current is ForgotPasswordVerifyOtpState) {
      id = current.identifier;
    } else if (current is ForgotPasswordSetNewPasswordState) {
      id = current.identifier;
    }
    emit(ForgotPasswordIdentifyState(identifier: id));
  }

  /// Submits the identifier on Step 1 to request a 6-digit OTP code.
  Future<void> sendOtp() async {
    final current = state;
    if (current is! ForgotPasswordIdentifyState || current.isSubmitting) return;

    final id = current.identifier.trim();
    if (id.isEmpty) {
      emit(
        current.copyWith(
          errorMessage: 'Please enter your User ID or corporate email.',
        ),
      );
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final result = await _repository.sendPasswordResetOtp(identifier: id);

      emit(
        ForgotPasswordVerifyOtpState(
          identifier: result.identifier,
          maskedEmail: result.maskedEmail,
          cooldownSecondsRemaining: result.cooldownSeconds,
          debugOtpCode: result.debugOtpCode,
        ),
      );

      _startCooldownTimer(result.cooldownSeconds);
    } on AuthException catch (e) {
      emit(current.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'Unable to dispatch verification code. Please try again.',
        ),
      );
    }
  }

  /// Updates the 6-digit OTP code as the user types on Step 2.
  void updateOtpCode(String code) {
    final current = state;
    if (current is ForgotPasswordVerifyOtpState) {
      emit(current.copyWith(otpCode: code, clearError: true));
    }
  }

  /// Requests a fresh 6-digit OTP code when the cooldown reaches 0.
  Future<void> resendOtp() async {
    final current = state;
    if (current is! ForgotPasswordVerifyOtpState || !current.canResend) return;

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final result = await _repository.sendPasswordResetOtp(
        identifier: current.identifier,
      );

      emit(
        current.copyWith(
          isSubmitting: false,
          maskedEmail: result.maskedEmail,
          cooldownSecondsRemaining: result.cooldownSeconds,
          debugOtpCode: result.debugOtpCode,
          clearError: true,
        ),
      );

      _startCooldownTimer(result.cooldownSeconds);
    } on AuthException catch (e) {
      emit(current.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to resend code. Please try again.',
        ),
      );
    }
  }

  /// Verifies the entered 6-digit OTP code on Step 2.
  Future<void> verifyOtp() async {
    final current = state;
    if (current is! ForgotPasswordVerifyOtpState || current.isSubmitting) return;

    final trimmedCode = current.otpCode.trim();
    if (trimmedCode.length != 6) {
      emit(
        current.copyWith(
          errorMessage: 'Please enter a valid 6-digit verification code.',
        ),
      );
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final isValid = await _repository.verifyPasswordResetOtp(
        identifier: current.identifier,
        otpCode: trimmedCode,
      );

      if (isValid) {
        _cooldownTimer?.cancel();
        emit(
          ForgotPasswordSetNewPasswordState(
            identifier: current.identifier,
            otpCode: trimmedCode,
          ),
        );
      }
    } on AuthException catch (e) {
      emit(current.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'Verification failed. Please check the code and try again.',
        ),
      );
    }
  }

  /// Establishes the new password on Step 3 and finishes the flow.
  Future<void> completeReset({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = state;
    if (current is! ForgotPasswordSetNewPasswordState || current.isSubmitting) {
      return;
    }

    final trimmedPass = newPassword.trim();
    final trimmedConfirm = confirmPassword.trim();

    if (trimmedPass.isEmpty) {
      emit(current.copyWith(errorMessage: 'Password cannot be empty.'));
      return;
    }

    if (trimmedPass.length < 6) {
      emit(
        current.copyWith(
          errorMessage: 'Password must be at least 6 characters.',
        ),
      );
      return;
    }

    if (trimmedPass != trimmedConfirm) {
      emit(current.copyWith(errorMessage: 'Passwords do not match.'));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      await _repository.completePasswordResetWithOtp(
        identifier: current.identifier,
        otpCode: current.otpCode,
        newPassword: trimmedPass,
      );

      _cooldownTimer?.cancel();

      emit(
        ForgotPasswordSuccessState(
          identifier: current.identifier,
        ),
      );
    } on AuthException catch (e) {
      emit(current.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to reset password. Please try again.',
        ),
      );
    }
  }

  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    int remaining = seconds;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (isClosed) {
        timer.cancel();
        return;
      }

      final current = state;
      if (current is ForgotPasswordVerifyOtpState) {
        emit(current.copyWith(cooldownSecondsRemaining: remaining));
      }

      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
