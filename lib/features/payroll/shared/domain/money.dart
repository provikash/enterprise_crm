import 'package:flutter/foundation.dart';

@immutable
class Money implements Comparable<Money> {
  static const int maxSafePaise = 9007199254740991;
  final int paise;

  const Money(this.paise)
    : assert(
        paise >= -maxSafePaise && paise <= maxSafePaise,
        'Money exceeds the web-safe integer range.',
      );

  const Money.zero() : paise = 0;

  factory Money.parse(String input) {
    final normalized = input
        .trim()
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .trim();
    final match = RegExp(r'^(-)?(\d+)(?:\.(\d{0,2}))?$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException(
        'Enter an amount with up to 2 decimal places.',
      );
    }
    final negative = match.group(1) != null;
    final rupees = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    final paisePart = fraction.isEmpty ? 0 : int.parse(fraction);
    final absolute = _checkedAdd(_checkedMultiply(rupees, 100), paisePart);
    return Money(negative ? -absolute : absolute);
  }

  String format({bool symbol = true, bool showPaise = true}) {
    final negative = paise < 0;
    final absolute = paise.abs();
    final rupees = absolute ~/ 100;
    final paisePart = absolute % 100;
    final grouped = _indianGroup(rupees.toString());
    final prefix = negative ? '-' : '';
    final currency = symbol ? '₹' : '';
    final decimals = showPaise
        ? '.${paisePart.toString().padLeft(2, '0')}'
        : '';
    return '$prefix$currency$grouped$decimals';
  }

  Money operator +(Money other) => Money(_checkedAdd(paise, other.paise));
  Money operator -(Money other) => Money(_checkedAdd(paise, -other.paise));
  Money operator -() => Money(-paise);

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();

  static String _indianGroup(String digits) {
    if (digits.length <= 3) return digits;
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return '${groups.join(',')},$tail';
  }

  static int _checkedMultiply(int value, int multiplier) {
    if (value > maxSafePaise ~/ multiplier) {
      throw const FormatException('Amount is too large.');
    }
    return value * multiplier;
  }

  static int _checkedAdd(int first, int second) {
    final result = first + second;
    if (result < -maxSafePaise || result > maxSafePaise) {
      throw const FormatException('Amount is too large.');
    }
    return result;
  }
}
