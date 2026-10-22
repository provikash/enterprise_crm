import '../entities/current_user.dart';
import '../entities/otp_dispatch_result.dart';

/// Domain repository contract for CRM authentication and session management.
abstract interface class AuthRepository {
  /// Authenticates with user credentials.
  ///
  /// Throws [AuthException] on invalid credentials or failure.
  Future<CurrentUser> login({required String userId, required String password});

  /// Logs out the current user and clears session state.
  Future<void> logout();

  /// The currently authenticated user in memory, or `null` if unauthenticated.
  CurrentUser? get currentUser;

  /// Generates and dispatches a 6-digit OTP code to the registered corporate email.
  ///
  /// Throws [AuthException] if user is not found or account is disabled.
  Future<OtpDispatchResult> sendPasswordResetOtp({required String identifier});

  /// Validates the provided 6-digit OTP code against the active session.
  ///
  /// Throws [AuthException] on invalid or expired code.
  Future<bool> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  });

  /// Completes the password reset process after OTP verification.
  ///
  /// Throws [AuthException] if session invalid, expired, or password criteria unmet.
  Future<void> completePasswordResetWithOtp({
    required String identifier,
    required String otpCode,
    required String newPassword,
  });
}

/// Represents a domain-level authentication error.
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
