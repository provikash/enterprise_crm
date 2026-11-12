import 'package:flutter/material.dart';
import '../security/secure_storage_service.dart';
import 'crm_localizations.dart';

/// Centralized Controller for managing enterprise CRM language and locale.
class LocaleController extends ValueNotifier<Locale> {
  static const String _storageKey = 'crm_user_locale_pref';
  static final LocaleController instance = LocaleController._();

  SecureStorageService? _storage;

  LocaleController._() : super(const Locale('en'));

  /// Initializes the controller with optional persistent storage.
  Future<void> initialize({SecureStorageService? storage}) async {
    _storage = storage;
    if (_storage != null) {
      final code = await _storage!.read(key: _storageKey);
      if (code != null && code.isNotEmpty) {
        final matched = CrmLocalizations.supportedLocales.firstWhere(
          (l) => l.languageCode == code,
          orElse: () => const Locale('en'),
        );
        value = matched;
      }
    }
  }

  /// Updates the current locale across all application widgets.
  Future<void> setLocale(Locale newLocale) async {
    if (!CrmLocalizations.supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) {
      return;
    }
    value = newLocale;
    if (_storage != null) {
      await _storage!.write(key: _storageKey, value: newLocale.languageCode);
    }
  }

  /// Sets language by language code (e.g. 'en', 'es', 'hi', 'de').
  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code));
  }
}

