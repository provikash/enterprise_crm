/// Immutable value object representing a monetary amount in the Enterprise CRM HR module.
///
/// Follows HR-7.2 and HR-7.3 financial domain principles:
/// - Stored internally as a 64-bit integer count of minor units (e.g., paisa for INR, cents for USD)
///   to strictly avoid floating-point binary representation drift (e.g. 0.1 + 0.2 != 0.3).
/// - Encapsulates an explicit ISO-4217 currency code (defaults to 'INR').
/// - Prevents cross-currency arithmetic without explicit conversion.
/// - Distinguishes explicit zero from absent/missing data.
/// - Relies strictly on standard Dart without external dependencies.
class Money implements Comparable<Money> {
  /// Default currency code used across Enterprise CRM HR module.
  static const String defaultCurrency = 'INR';

  /// Amount stored in exact minor units (e.g., 50000 paisa = ₹500.00).
  final int minorUnits;

  /// ISO-4217 currency code (e.g., 'INR', 'USD').
  final String currency;

  /// Creates a [Money] value object with exact [minorUnits] and optional [currency].
  const Money({
    required this.minorUnits,
    this.currency = defaultCurrency,
  });

  /// Creates a [Money] instance representing zero in the given [currency].
  const Money.zero({String currency = defaultCurrency})
      : this(minorUnits: 0, currency: currency);

  /// Creates a [Money] instance from a major unit number (e.g., 500.50 -> 50050 minor units).
  ///
  /// Uses standard half-up midpoint rounding to resolve fractional minor units.
  factory Money.fromMajorUnits(num amount, {String currency = defaultCurrency}) {
    final minor = (amount * 100).round();
    return Money(minorUnits: minor, currency: currency);
  }

  /// Creates a [Money] instance from exact paisa (alias for minorUnits).
  factory Money.fromPaisa(int paisa, {String currency = defaultCurrency}) {
    return Money(minorUnits: paisa, currency: currency);
  }

  /// Returns the amount in major currency units as a double (e.g., 50050 minor units -> 500.50).
  double get majorUnits => minorUnits / 100.0;

  /// Whether this amount is exactly zero.
  bool get isZero => minorUnits == 0;

  /// Whether this amount is strictly positive (> 0).
  bool get isPositive => minorUnits > 0;

  /// Whether this amount is strictly negative (< 0).
  bool get isNegative => minorUnits < 0;

  /// Adds [other] to this amount. Throws [ArgumentError] if currencies differ.
  Money operator +(Money other) {
    _assertSameCurrency(other, '+');
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currency: currency,
    );
  }

  /// Subtracts [other] from this amount. Throws [ArgumentError] if currencies differ.
  Money operator -(Money other) {
    _assertSameCurrency(other, '-');
    return Money(
      minorUnits: minorUnits - other.minorUnits,
      currency: currency,
    );
  }

  /// Multiplies this amount by a scalar [multiplier] with half-up rounding to nearest minor unit.
  Money operator *(num multiplier) {
    return Money(
      minorUnits: (minorUnits * multiplier).round(),
      currency: currency,
    );
  }

  /// Returns the absolute value of this monetary amount.
  Money abs() {
    return Money(minorUnits: minorUnits.abs(), currency: currency);
  }

  /// Formatted string representing the currency and amount (e.g. '₹50,000.00').
  String get formatted {
    final absMajor = majorUnits.abs();
    final parts = absMajor.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final sign = minorUnits < 0 ? '-' : '';
    final symbol = currency == 'INR'
        ? '₹'
        : (currency == 'USD' ? '\$' : '$currency ');
    return '$sign$symbol$whole.${parts[1]}';
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other, 'compareTo');
    return minorUnits.compareTo(other.minorUnits);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  void _assertSameCurrency(Money other, String operation) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot perform $operation on different currencies: $currency and ${other.currency}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          minorUnits == other.minorUnits &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits $currency)';
}
