import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for secure, encrypted key-value credential and token storage.
abstract interface class SecureStorageService {
  /// Stores a key-value pair securely with encryption.
  Future<void> write({required String key, required String value});

  /// Reads a decrypted value for the specified key, or `null` if not found.
  Future<String?> read({required String key});

  /// Deletes the item matching the key.
  Future<void> delete({required String key});

  /// Deletes all stored secure values.
  Future<void> deleteAll();

  /// Returns `true` if the key exists in secure storage.
  Future<bool> containsKey({required String key});
}

/// Production implementation of [SecureStorageService] using platform-specific
/// secure hardware (Android Keystore / EncryptedSharedPreferences, Apple Keychain).
class FlutterSecureStorageService implements SecureStorageService {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }
}

/// Ephemeral, in-memory implementation of [SecureStorageService] for
/// headless test runners, local simulations, and CI environments.
class InMemorySecureStorageService implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _store.containsKey(key);
  }
}

