abstract final class SensitiveDataRedactor {
  static const _sensitiveKeys = {
    'authorization',
    'password',
    'otp',
    'elevatedtoken',
    'salary',
    'salarypaise',
    'amount',
    'amountpaise',
    'bankaccount',
    'accountnumber',
    'ifsc',
    'pan',
    'aadhaar',
  };

  static Object? redact(Object? value, {String? key}) {
    if (key != null && _sensitiveKeys.contains(key.toLowerCase())) {
      return '[REDACTED]';
    }
    if (value is Map) {
      return value.map(
        (entryKey, entryValue) =>
            MapEntry(entryKey, redact(entryValue, key: entryKey.toString())),
      );
    }
    if (value is Iterable) {
      return value.map(redact).toList(growable: false);
    }
    return value;
  }
}
