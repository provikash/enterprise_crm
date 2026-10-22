/// Helper service to clean and normalize common contact data fields across channels.
class LeadFieldNormalizer {
  const LeadFieldNormalizer._();

  /// Cleans and formats phone numbers (e.g. keeping + and digits).
  static String? normalizePhone(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Replace non-numeric characters except leading plus
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (i == 0 && char == '+') {
        buffer.write('+');
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      }
    }
    final result = buffer.toString();
    return result.isNotEmpty ? result : trimmed;
  }

  /// Normalizes an email address to trimmed lowercase.
  static String? normalizeEmail(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isNotEmpty ? trimmed.toLowerCase() : null;
  }

  /// Normalizes names by stripping redundant internal spaces and capitalizing.
  static String? normalizeName(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final words = trimmed.split(RegExp(r'\s+'));
    return words
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}'
            : '')
        .join(' ');
  }
}
