import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/security/secure_storage_service.dart';
import 'package:enterprise_crm/core/storage/local_cache_service.dart';

void main() {
  group('LocalCacheService Offline State Tests', () {
    late SecureStorageService storage;
    late LocalCacheService cache;

    setUp(() {
      storage = InMemorySecureStorageService();
      cache = LocalCacheService(storage: storage);
    });

    test('stores and retrieves data from in-memory cache', () async {
      await cache.put(key: 'user_pref', data: {'theme': 'dark', 'density': 'compact'});

      final result = await cache.get<Map<String, dynamic>>(key: 'user_pref');
      expect(result, isNotNull);
      expect(result!['theme'], 'dark');
      expect(result['density'], 'compact');
    });

    test('persists and restores data through persistent storage', () async {
      await cache.put<String>(
        key: 'cached_token',
        data: 'token_abc_123',
        toJson: (data) => data,
      );

      // Create new cache instance sharing same backing storage
      final newCache = LocalCacheService(storage: storage);
      final restored = await newCache.get<String>(
        key: 'cached_token',
        fromJson: (json) => json as String,
      );

      expect(restored, 'token_abc_123');
    });

    test('expires entry when TTL has elapsed', () async {
      await cache.put<String>(
        key: 'transient_lead',
        data: 'Lead_999',
        ttl: const Duration(milliseconds: 10),
      );

      // Verify immediate retrieval works
      expect(await cache.get<String>(key: 'transient_lead'), 'Lead_999');

      // Wait for TTL expiry
      await Future<void>.delayed(const Duration(milliseconds: 25));

      final expired = await cache.get<String>(key: 'transient_lead');
      expect(expired, isNull);
    });

    test('evicts key from memory and persistent storage', () async {
      await cache.put<String>(
        key: 'evict_me',
        data: 'val',
        toJson: (v) => v,
      );

      await cache.evict('evict_me');
      final result = await cache.get<String>(
        key: 'evict_me',
        fromJson: (j) => j as String,
      );
      expect(result, isNull);
    });
  });
}

