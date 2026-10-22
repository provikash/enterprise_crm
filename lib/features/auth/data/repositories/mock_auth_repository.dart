import '../../../../features/user_management/data/mock/mock_account_store.dart';
import '../../domain/entities/current_user.dart';
import '../../domain/entities/otp_dispatch_result.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory mock authentication repository backed by a shared [MockAccountStore].
class MockAuthRepository implements AuthRepository {
  final MockAccountStore _accountStore;
  final String Function()? _otpCodeGenerator;
  final Duration _otpExpiryDuration;
  final Map<String, _MockOtpSession> _otpSessions = {};
  CurrentUser? _currentUser;

  MockAuthRepository({
    required MockAccountStore accountStore,
    CurrentUser? initialUser,
    String Function()? otpCodeGenerator,
    Duration otpExpiryDuration = const Duration(minutes: 5),
  }) : _accountStore = accountStore,
       _currentUser = initialUser,
       _otpCodeGenerator = otpCodeGenerator,
       _otpExpiryDuration = otpExpiryDuration;

  @override
  CurrentUser? get currentUser => _currentUser;

  @override
  Future<CurrentUser> login({
    required String userId,
    required String password,
  }) async {
    await Future<void>.delayed(Duration.zero);

    final managedUser = _accountStore.authenticate(
      userId: userId,
      password: password,
    );

    if (managedUser == null) {
      throw const AuthException('Invalid User ID or password.');
    }

    final user = CurrentUser(
      id: managedUser.userId,
      displayName: managedUser.displayName,
      accountType: managedUser.accountType,
      modules: managedUser.modules,
      permissions: managedUser.permissions,
    );

    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(Duration.zero);
    _currentUser = null;
  }

  @override
  Future<OtpDispatchResult> sendPasswordResetOtp({
    required String identifier,
  }) async {
    await Future<void>.delayed(Duration.zero);

    final userId = _normalizeIdentifier(identifier);
    if (userId.isEmpty) {
      throw const AuthException('Please enter your User ID or corporate email.');
    }

    final user = _accountStore.findUserByUserId(userId);
    if (user == null) {
      throw AuthException('No account found for "$identifier".');
    }

    if (!user.isActive) {
      throw const AuthException(
        'Account is disabled. Please contact your administrator.',
      );
    }

    final code = _otpCodeGenerator?.call() ?? '123456';
    final expiresAt = DateTime.now().add(_otpExpiryDuration);
    final maskedEmail = _maskCorporateEmail(user.userId);

    _otpSessions[user.userId.toLowerCase()] = _MockOtpSession(
      userId: user.userId,
      targetInternalId: user.id,
      code: code,
      expiresAt: expiresAt,
    );

    return OtpDispatchResult(
      identifier: user.userId,
      maskedEmail: maskedEmail,
      expiresAt: expiresAt,
      cooldownSeconds: 60,
      debugOtpCode: code,
    );
  }

  @override
  Future<bool> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    await Future<void>.delayed(Duration.zero);

    final userId = _normalizeIdentifier(identifier);
    final session = _otpSessions[userId];

    if (session == null) {
      throw const AuthException(
        'No active OTP session found. Please request a verification code.',
      );
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      _otpSessions.remove(userId);
      throw const AuthException(
        'Verification code has expired. Please request a new one.',
      );
    }

    if (session.attemptsRemaining <= 0) {
      _otpSessions.remove(userId);
      throw const AuthException(
        'Too many incorrect attempts. Please request a new code.',
      );
    }

    final trimmedInput = otpCode.trim();
    if (trimmedInput != session.code) {
      session.attemptsRemaining--;
      if (session.attemptsRemaining <= 0) {
        _otpSessions.remove(userId);
        throw const AuthException(
          'Too many incorrect attempts. Please request a new code.',
        );
      }
      throw AuthException(
        'Invalid verification code. (${session.attemptsRemaining} attempts remaining)',
      );
    }

    session.isVerified = true;
    return true;
  }

  @override
  Future<void> completePasswordResetWithOtp({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    await Future<void>.delayed(Duration.zero);

    final userId = _normalizeIdentifier(identifier);
    final session = _otpSessions[userId];

    if (session == null || !session.isVerified) {
      throw const AuthException('Verification code has not been verified.');
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      _otpSessions.remove(userId);
      throw const AuthException(
        'Verification code has expired. Please start over.',
      );
    }

    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    _accountStore.resetPassword(
      id: session.targetInternalId,
      newPassword: trimmedPassword,
    );

    // Consume session upon successful password reset
    _otpSessions.remove(userId);
  }

  String _normalizeIdentifier(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.contains('@')) {
      return trimmed.split('@').first.trim();
    }
    return trimmed;
  }

  String _maskCorporateEmail(String userId) {
    if (userId.length <= 2) {
      return '${userId.substring(0, 1)}***@enterprise-crm.internal';
    }
    return '${userId.substring(0, 2)}***@enterprise-crm.internal';
  }
}

class _MockOtpSession {
  final String userId;
  final String targetInternalId;
  final String code;
  final DateTime expiresAt;
  int attemptsRemaining = 3;
  bool isVerified = false;

  _MockOtpSession({
    required this.userId,
    required this.targetInternalId,
    required this.code,
    required this.expiresAt,
  });
}
