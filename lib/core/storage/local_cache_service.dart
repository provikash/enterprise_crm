import 'dart:convert';
import '../logging/crm_logger.dart';
import '../security/secure_storage_service.dart';

/// Entry holding cached value with optional time-to-live.
class CacheEntry<T> {
  final T data;
  final DateTime storedAt;
  final Duration? ttl;

  const CacheEntry({
    required this.data,
    required this.storedAt,
    this.ttl,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().toUtc().isAfter(storedAt.add(ttl!));
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => {
        'stored_at': storedAt.toIso8601String(),
        'ttl_ms': ttl?.inMilliseconds,
        'data': toJsonT(data),
      };

  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final storedStr = json['stored_at'] as String;
    final ttlMs = json['ttl_ms'] as int?;
    return CacheEntry(
      storedAt: DateTime.parse(storedStr),
      ttl: ttlMs != null ? Duration(milliseconds: ttlMs) : null,
      data: fromJsonT(json['data']),
    );
  }
}

/// Enterprise Local Cache Service for offline-first caching and state hydration.
class LocalCacheService {
  final SecureStorageService _storage;
  final Map<String, CacheEntry<dynamic>> _memoryCache = {};

  LocalCacheService({SecureStorageService? storage})
      : _storage = storage ?? InMemorySecureStorageService();

  /// Stores data in memory and persists to storage with optional TTL.
  Future<void> put<T>({
    required String key,
    required T data,
    Duration? ttl,
    Object? Function(T)? toJson,
  }) async {
    final entry = CacheEntry<T>(
      data: data,
      storedAt: DateTime.now().toUtc(),
      ttl: ttl,
    );
    _memoryCache[key] = entry;

    if (toJson != null) {
      try {
        final serialized = jsonEncode(entry.toJson(toJson));
        await _storage.write(key: 'cache_$key', value: serialized);
      } catch (e, st) {
        CrmLogger.warning('LocalCacheService', 'Failed to persist cache key $key', e, st);
      }
    }
  }

  /// Retrieves cached value from memory or persistent storage if valid.
  Future<T?> get<T>({
    required String key,
    T Function(Object? json)? fromJson,
  }) async {
    // Check in-memory cache first
    final memEntry = _memoryCache[key];
    if (memEntry != null) {
      if (!memEntry.isExpired) {
        return memEntry.data as T;
      }
      _memoryCache.remove(key);
    }

    // Fall back to persistent storage
    if (fromJson != null) {
      try {
        final raw = await _storage.read(key: 'cache_$key');
        if (raw != null) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final entry = CacheEntry<T>.fromJson(decoded, fromJson);
          if (!entry.isExpired) {
            _memoryCache[key] = entry;
            return entry.data;
          } else {
            await _storage.delete(key: 'cache_$key');
          }
        }
      } catch (e, st) {
        CrmLogger.warning('LocalCacheService', 'Failed to read cache key $key', e, st);
      }
    }

    return null;
  }

  /// Evicts a specific key from both memory and persistent cache.
  Future<void> evict(String key) async {
    _memoryCache.remove(key);
    await _storage.delete(key: 'cache_$key');
  }

  /// Clears all entries from memory cache.
  void clearMemory() {
    _memoryCache.clear();
  }
}

