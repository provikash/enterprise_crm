import 'dart:convert';
import 'secure_storage_service.dart';

/// Enterprise session security metadata.
class SessionTokenData {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? userId;

  const SessionTokenData({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.userId,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt!);
  }

  bool isExpiringSoon({Duration buffer = const Duration(minutes: 5)}) {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().add(buffer).isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt?.toIso8601String(),
        'user_id': userId,
      };

  factory SessionTokenData.fromJson(Map<String, dynamic> json) {
    final expiresStr = json['expires_at'] as String?;
    return SessionTokenData(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: expiresStr != null ? DateTime.tryParse(expiresStr) : null,
      userId: json['user_id'] as String?,
    );
  }
}

/// Enterprise Vault for cryptographic credential storage and token lifecycle.
class AuthTokenVault {
  static const String _sessionKey = 'crm_auth_session_token';
  final SecureStorageService _storage;

  AuthTokenVault({SecureStorageService? storage})
      : _storage = storage ?? FlutterSecureStorageService();

  /// Saves the active authenticated session into secure storage.
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? userId,
  }) async {
    final session = SessionTokenData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
    );
    final serialized = jsonEncode(session.toJson());
    await _storage.write(key: _sessionKey, value: serialized);
  }

  /// Retrieves the active session token data from secure storage.
  Future<SessionTokenData?> getSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return SessionTokenData.fromJson(decoded);
    } catch (_) {
      // Invalidate corrupted or tampered storage
      await clearSession();
      return null;
    }
  }

  /// Convenience getter for the raw bearer access token.
  Future<String?> getAccessToken() async {
    final session = await getSession();
    return session?.accessToken;
  }

  /// Convenience getter for the refresh token.
  Future<String?> getRefreshToken() async {
    final session = await getSession();
    return session?.refreshToken;
  }

  /// Securely purges all authentication tokens and session data (e.g. on logout).
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  /// Returns `true` if an unexpired session exists in secure storage.
  Future<bool> hasActiveSession() async {
    final session = await getSession();
    if (session == null) return false;
    return !session.isExpired;
  }
}

