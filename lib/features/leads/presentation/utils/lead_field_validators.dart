/// Utility functions for validating Lead input fields across manual entry and import.
library;

/// Validates whether an optional email is well-formed.
///
/// Returns `true` if [email] is `null` or blank after trimming.
/// If non-empty, requires both '@' and '.' characters, consistent with manual Lead entry.
bool isValidOptionalLeadEmail(String? email) {
  if (email == null) return true;
  final trimmed = email.trim();
  if (trimmed.isEmpty) return true;
  return trimmed.contains('@') && trimmed.contains('.');
}

/// Validates whether an optional mobile phone number is well-formed.
///
/// Returns `true` if [phone] is `null` or blank after trimming.
/// If non-empty, checks:
/// - Only valid phone characters are allowed (digits, +, spaces, -, (, ), .).
/// - Contains between 10 and 15 digits (standard E.164 mobile number length).
bool isValidOptionalLeadPhone(String? phone) {
  if (phone == null) return true;
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return true;

  final validCharsPattern = RegExp(r'^[+]?[0-9\s\-().]+$');
  if (!validCharsPattern.hasMatch(trimmed)) {
    return false;
  }

  final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
  return digitsOnly.length >= 10 && digitsOnly.length <= 15;
}

