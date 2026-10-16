abstract final class EmployeeValidators {
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9][0-9\s().-]{6,19}$');

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, 'Email address');
    if (required != null) return required;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    final required = requiredText(value, 'Phone number');
    if (required != null) return required;
    final trimmed = value!.trim();
    if (!_phonePattern.hasMatch(trimmed)) {
      return 'Please enter a valid mobile number';
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Mobile number must contain 7 to 15 digits';
    }
    return null;
  }
}
