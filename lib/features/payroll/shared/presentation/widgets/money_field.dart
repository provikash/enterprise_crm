import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/money.dart';

class MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool allowNegative;
  final bool enabled;
  final ValueChanged<Money?>? onChanged;
  final String? Function(Money? value)? validator;

  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.allowNegative = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final pattern = allowNegative
        ? RegExp(r'^-?\d*(?:\.\d{0,2})?$')
        : RegExp(r'^\d*(?:\.\d{0,2})?$');
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          return pattern.hasMatch(newValue.text) ? newValue : oldValue;
        }),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) => onChanged?.call(_tryParse(text)),
      validator: (text) {
        if (text == null || text.trim().isEmpty) {
          return validator?.call(null);
        }
        final parsed = _tryParse(text);
        if (parsed == null) {
          return 'Enter a valid amount with up to 2 decimals.';
        }
        return validator?.call(parsed);
      },
    );
  }

  Money? _tryParse(String text) {
    if (text.trim().isEmpty || text == '-') return null;
    try {
      return Money.parse(text);
    } on FormatException {
      return null;
    }
  }
}
