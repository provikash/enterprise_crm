import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/security/auth_token_vault.dart';
import 'package:enterprise_crm/core/security/secure_storage_service.dart';

void main() {
  group('AuthTokenVault Tests', () {
    late SecureStorageService storage;
    late AuthTokenVault vault;

    setUp(() {
      storage = InMemorySecureStorageService();
      vault = AuthTokenVault(storage: storage);
    });

    test('saves and retrieves valid session token data', () async {
      final expiry = DateTime.now().toUtc().add(const Duration(hours: 4));
      await vault.saveSession(
        accessToken: 'jwt_access_abc',
        refreshToken: 'jwt_refresh_xyz',
        expiresAt: expiry,
        userId: 'USR-101',
      );

      final session = await vault.getSession();
      expect(session, isNotNull);
      expect(session!.accessToken, 'jwt_access_abc');
      expect(session.refreshToken, 'jwt_refresh_xyz');
      expect(session.userId, 'USR-101');
      expect(session.isExpired, isFalse);

      expect(await vault.getAccessToken(), 'jwt_access_abc');
      expect(await vault.getRefreshToken(), 'jwt_refresh_xyz');
      expect(await vault.hasActiveSession(), isTrue);
    });

    test('detects expired session correctly', () async {
      final pastExpiry = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      await vault.saveSession(
        accessToken: 'expired_token',
        expiresAt: pastExpiry,
      );

      final session = await vault.getSession();
      expect(session, isNotNull);
      expect(session!.isExpired, isTrue);
      expect(await vault.hasActiveSession(), isFalse);
    });

    test('detects token expiring soon with buffer', () async {
      final soonExpiry = DateTime.now().toUtc().add(const Duration(minutes: 2));
      final session = SessionTokenData(
        accessToken: 'soon_token',
        expiresAt: soonExpiry,
      );

      expect(session.isExpiringSoon(buffer: const Duration(minutes: 5)), isTrue);
      expect(session.isExpiringSoon(buffer: const Duration(minutes: 1)), isFalse);
    });

    test('clearSession purges stored session completely', () async {
      await vault.saveSession(
        accessToken: 'token_to_purge',
        userId: 'USR-999',
      );
      expect(await vault.hasActiveSession(), isTrue);

      await vault.clearSession();
      expect(await vault.getSession(), isNull);
      expect(await vault.getAccessToken(), isNull);
      expect(await vault.hasActiveSession(), isFalse);
    });

    test('handles corrupted storage gracefully by clearing session', () async {
      await storage.write(key: 'crm_auth_session_token', value: 'NOT_VALID_JSON{[');

      final session = await vault.getSession();
      expect(session, isNull);
      expect(await vault.hasActiveSession(), isFalse);
      expect(await storage.read(key: 'crm_auth_session_token'), isNull);
    });
  });
}

