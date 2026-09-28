/// Immutable domain entity representing a Payroll Period in the Enterprise CRM HR module.
///
/// Follows HR-6.1 frozen business requirements:
/// - Stably identified by a unique [id].
/// - [startDate] and [endDate] are normalized to UTC calendar dates (midnight UTC).
/// - [name] provides a human-readable display label (e.g. 'January 2026').
/// - [paymentDate] is an optional normalized UTC date capturing the disbursement date.
/// - Strictly decoupled from UI and networking dependencies.
/// - No speculative month-generation logic or status state machines.
class PayrollPeriod {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? paymentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PayrollPeriod({
    required this.id,
    required this.name,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? paymentDate,
    this.createdAt,
    this.updatedAt,
  }) : startDate = DateTime.utc(startDate.year, startDate.month, startDate.day),
       endDate = DateTime.utc(endDate.year, endDate.month, endDate.day),
       paymentDate = paymentDate != null
           ? DateTime.utc(paymentDate.year, paymentDate.month, paymentDate.day)
           : null {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Payroll period ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Payroll period name cannot be empty',
      );
    }
    if (this.startDate.isAfter(this.endDate)) {
      throw ArgumentError('startDate cannot be after endDate');
    }
  }

  /// Formatted date range string in 'YYYY-MM-DD – YYYY-MM-DD' format.
  String get formattedPeriod {
    final sY = startDate.year.toString().padLeft(4, '0');
    final sM = startDate.month.toString().padLeft(2, '0');
    final sD = startDate.day.toString().padLeft(2, '0');
    final eY = endDate.year.toString().padLeft(4, '0');
    final eM = endDate.month.toString().padLeft(2, '0');
    final eD = endDate.day.toString().padLeft(2, '0');
    return '$sY-$sM-$sD – $eY-$eM-$eD';
  }

  /// Formatted payment date in 'YYYY-MM-DD' format, or `null` if not set.
  String? get formattedPaymentDate {
    if (paymentDate == null) return null;
    final y = paymentDate!.year.toString().padLeft(4, '0');
    final m = paymentDate!.month.toString().padLeft(2, '0');
    final d = paymentDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Creates a copy of this period with updated fields.
  PayrollPeriod copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollPeriod &&
        runtimeType == other.runtimeType &&
        other.id == id &&
        other.name == name &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.paymentDate == paymentDate;
  }

  @override
  int get hashCode => Object.hash(id, name, startDate, endDate, paymentDate);

  @override
  String toString() =>
      'PayrollPeriod(id: $id, name: $name, range: $formattedPeriod, paymentDate: $formattedPaymentDate)';
}
