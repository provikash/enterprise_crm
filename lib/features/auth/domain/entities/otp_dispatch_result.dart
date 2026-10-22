/// Value object holding metadata about an OTP dispatch for password reset.
class OtpDispatchResult {
  /// The resolved user identifier.
  final String identifier;

  /// The masked corporate email (e.g. `ad***@enterprise-crm.internal`).
  final String maskedEmail;

  /// Expiry timestamp for the active OTP code.
  final DateTime expiresAt;

  /// Cooldown seconds before resend is allowed (defaults to 60).
  final int cooldownSeconds;

  /// Optional debug OTP code exposed for mock / development environments.
  final String? debugOtpCode;

  const OtpDispatchResult({
    required this.identifier,
    required this.maskedEmail,
    required this.expiresAt,
    this.cooldownSeconds = 60,
    this.debugOtpCode,
  });

  @override
  String toString() =>
      'OtpDispatchResult(identifier: $identifier, maskedEmail: $maskedEmail, expiresAt: $expiresAt, cooldownSeconds: $cooldownSeconds)';
}
