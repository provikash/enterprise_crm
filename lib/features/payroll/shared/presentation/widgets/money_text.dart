import 'package:flutter/material.dart';

import '../../domain/money.dart';

class MoneyText extends StatelessWidget {
  final Money? value;
  final bool masked;
  final TextStyle? style;
  final String unavailableLabel;

  const MoneyText({
    super.key,
    required this.value,
    this.masked = false,
    this.style,
    this.unavailableLabel = '—',
  });

  @override
  Widget build(BuildContext context) {
    final money = value;
    final label = money == null
        ? unavailableLabel
        : masked
        ? '₹••••••'
        : money.format();
    final effectiveStyle = (style ?? Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(
          color: money != null && money.paise < 0 && !masked
              ? Theme.of(context).colorScheme.error
              : style?.color,
        );
    return Semantics(
      label: money == null
          ? 'Amount unavailable'
          : masked
          ? 'Amount hidden'
          : label,
      child: Text(label, style: effectiveStyle),
    );
  }
}
