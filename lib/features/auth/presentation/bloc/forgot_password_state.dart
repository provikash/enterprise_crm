sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

/// Step 1: User provides User ID or Corporate Email to locate their account.
class ForgotPasswordIdentifyState extends ForgotPasswordState {
  final String identifier;
  final bool isSubmitting;
  final String? errorMessage;

  const ForgotPasswordIdentifyState({
    this.identifier = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  ForgotPasswordIdentifyState copyWith({
    String? identifier,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordIdentifyState(
      identifier: identifier ?? this.identifier,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordIdentifyState &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          isSubmitting == other.isSubmitting &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(identifier, isSubmitting, errorMessage);
}

/// Step 2: 6-digit OTP code has been dispatched. User enters the verification code.
class ForgotPasswordVerifyOtpState extends ForgotPasswordState {
  final String identifier;
  final String maskedEmail;
  final String otpCode;
  final int cooldownSecondsRemaining;
  final bool isSubmitting;
  final String? errorMessage;
  final String? debugOtpCode;

  const ForgotPasswordVerifyOtpState({
    required this.identifier,
    required this.maskedEmail,
    this.otpCode = '',
    this.cooldownSecondsRemaining = 60,
    this.isSubmitting = false,
    this.errorMessage,
    this.debugOtpCode,
  });

  bool get canResend => cooldownSecondsRemaining <= 0 && !isSubmitting;

  ForgotPasswordVerifyOtpState copyWith({
    String? identifier,
    String? maskedEmail,
    String? otpCode,
    int? cooldownSecondsRemaining,
    bool? isSubmitting,
    String? errorMessage,
    String? debugOtpCode,
    bool clearError = false,
  }) {
    return ForgotPasswordVerifyOtpState(
      identifier: identifier ?? this.identifier,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      otpCode: otpCode ?? this.otpCode,
      cooldownSecondsRemaining:
          cooldownSecondsRemaining ?? this.cooldownSecondsRemaining,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      debugOtpCode: debugOtpCode ?? this.debugOtpCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordVerifyOtpState &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          maskedEmail == other.maskedEmail &&
          otpCode == other.otpCode &&
          cooldownSecondsRemaining == other.cooldownSecondsRemaining &&
          isSubmitting == other.isSubmitting &&
          errorMessage == other.errorMessage &&
          debugOtpCode == other.debugOtpCode;

  @override
  int get hashCode => Object.hash(
    identifier,
    maskedEmail,
    otpCode,
    cooldownSecondsRemaining,
    isSubmitting,
    errorMessage,
    debugOtpCode,
  );
}

/// Step 3: OTP verified. User enters and confirms their new password.
class ForgotPasswordSetNewPasswordState extends ForgotPasswordState {
  final String identifier;
  final String otpCode;
  final bool isSubmitting;
  final String? errorMessage;

  const ForgotPasswordSetNewPasswordState({
    required this.identifier,
    required this.otpCode,
    this.isSubmitting = false,
    this.errorMessage,
  });

  ForgotPasswordSetNewPasswordState copyWith({
    String? identifier,
    String? otpCode,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordSetNewPasswordState(
      identifier: identifier ?? this.identifier,
      otpCode: otpCode ?? this.otpCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordSetNewPasswordState &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          otpCode == other.otpCode &&
          isSubmitting == other.isSubmitting &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(identifier, otpCode, isSubmitting, errorMessage);
}

/// Step 4: Password reset successfully completed.
class ForgotPasswordSuccessState extends ForgotPasswordState {
  final String identifier;
  final String message;

  const ForgotPasswordSuccessState({
    required this.identifier,
    this.message = 'Password has been reset successfully. Please sign in.',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordSuccessState &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          message == other.message;

  @override
  int get hashCode => Object.hash(identifier, message);
}
