import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/security/secure_storage_service.dart';

void main() {
  group('InMemorySecureStorageService Tests', () {
    late SecureStorageService storage;

    setUp(() {
      storage = InMemorySecureStorageService();
    });

    test('writes and reads key-value pair', () async {
      await storage.write(key: 'auth_token', value: 'secret_123');
      final value = await storage.read(key: 'auth_token');
      expect(value, 'secret_123');
    });

    test('returns null for missing key', () async {
      final value = await storage.read(key: 'non_existent');
      expect(value, isNull);
    });

    test('deletes specific key', () async {
      await storage.write(key: 'temp_key', value: 'temp_val');
      expect(await storage.containsKey(key: 'temp_key'), isTrue);

      await storage.delete(key: 'temp_key');
      expect(await storage.containsKey(key: 'temp_key'), isFalse);
      expect(await storage.read(key: 'temp_key'), isNull);
    });

    test('deleteAll purges entire storage', () async {
      await storage.write(key: 'k1', value: 'v1');
      await storage.write(key: 'k2', value: 'v2');
      await storage.write(key: 'k3', value: 'v3');

      expect(await storage.containsKey(key: 'k1'), isTrue);
      expect(await storage.containsKey(key: 'k2'), isTrue);

      await storage.deleteAll();

      expect(await storage.containsKey(key: 'k1'), isFalse);
      expect(await storage.containsKey(key: 'k2'), isFalse);
      expect(await storage.containsKey(key: 'k3'), isFalse);
    });

    test('overwrites existing key seamlessly', () async {
      await storage.write(key: 'token', value: 'initial');
      await storage.write(key: 'token', value: 'updated');
      expect(await storage.read(key: 'token'), 'updated');
    });
  });
}

