import '../../domain/entities/payroll_period.dart';

/// Data Transfer Object representing a Payroll Period from the backend API.
///
/// Established in HR-10.8 to handle serialization, deserialization, and strict validation
/// between the instructor backend JSON schemas and the immutable [PayrollPeriod] domain model.
///
/// Invariants:
/// - Rejects malformed JSON lacking required fields (`id`, `name`, `start_date`, `end_date`).
/// - Calendar dates are strictly normalized to UTC midnight.
/// - Period end dates cannot precede start dates.
class PayrollPeriodDto {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? paymentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PayrollPeriodDto({
    required this.id,
    required this.name,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? paymentDate,
    this.createdAt,
    this.updatedAt,
  })  : startDate = DateTime.utc(startDate.year, startDate.month, startDate.day),
        endDate = DateTime.utc(endDate.year, endDate.month, endDate.day),
        paymentDate = paymentDate != null
            ? DateTime.utc(paymentDate.year, paymentDate.month, paymentDate.day)
            : null;

  /// Constructs a [PayrollPeriodDto] from raw JSON map.
  ///
  /// Throws [FormatException] if any required fields are missing, invalid, or out of bounds.
  factory PayrollPeriodDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('Missing or empty "id" in PayrollPeriod JSON.');
    }

    final rawName = json['name']?.toString().trim();
    if (rawName == null || rawName.isEmpty) {
      throw const FormatException('Missing or empty "name" in PayrollPeriod JSON.');
    }

    final rawStart = (json['start_date'] ?? json['startDate'])?.toString().trim();
    if (rawStart == null || rawStart.isEmpty) {
      throw const FormatException('Missing or empty "start_date" in PayrollPeriod JSON.');
    }
    final parsedStart = DateTime.tryParse(rawStart);
    if (parsedStart == null) {
      throw FormatException('Invalid "start_date" date format: "$rawStart"');
    }

    final rawEnd = (json['end_date'] ?? json['endDate'])?.toString().trim();
    if (rawEnd == null || rawEnd.isEmpty) {
      throw const FormatException('Missing or empty "end_date" in PayrollPeriod JSON.');
    }
    final parsedEnd = DateTime.tryParse(rawEnd);
    if (parsedEnd == null) {
      throw FormatException('Invalid "end_date" date format: "$rawEnd"');
    }

    final normalizedStart = DateTime.utc(parsedStart.year, parsedStart.month, parsedStart.day);
    final normalizedEnd = DateTime.utc(parsedEnd.year, parsedEnd.month, parsedEnd.day);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const FormatException('Payroll period "end_date" cannot precede "start_date".');
    }

    final rawPayment = (json['payment_date'] ?? json['paymentDate'])?.toString().trim();
    final parsedPayment = rawPayment != null && rawPayment.isNotEmpty
        ? DateTime.tryParse(rawPayment)
        : null;
    final paymentDate = parsedPayment != null
        ? DateTime.utc(parsedPayment.year, parsedPayment.month, parsedPayment.day)
        : null;

    final rawCreatedAt = (json['created_at'] ?? json['createdAt'])?.toString().trim();
    final createdAt = rawCreatedAt != null && rawCreatedAt.isNotEmpty
        ? DateTime.tryParse(rawCreatedAt)?.toUtc()
        : null;

    final rawUpdatedAt = (json['updated_at'] ?? json['updatedAt'])?.toString().trim();
    final updatedAt = rawUpdatedAt != null && rawUpdatedAt.isNotEmpty
        ? DateTime.tryParse(rawUpdatedAt)?.toUtc()
        : null;

    return PayrollPeriodDto(
      id: rawId,
      name: rawName,
      startDate: normalizedStart,
      endDate: normalizedEnd,
      paymentDate: paymentDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Maps this DTO to an immutable domain [PayrollPeriod].
  PayrollPeriod toDomain() {
    return PayrollPeriod(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      paymentDate: paymentDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a DTO from an existing domain [PayrollPeriod].
  factory PayrollPeriodDto.fromDomain(PayrollPeriod domain) {
    return PayrollPeriodDto(
      id: domain.id,
      name: domain.name,
      startDate: domain.startDate,
      endDate: domain.endDate,
      paymentDate: domain.paymentDate,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
  }

  /// Serializes this DTO to standard backend JSON representation with snake_case keys.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
    };
    if (paymentDate != null) {
      map['payment_date'] = _formatDate(paymentDate!);
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
