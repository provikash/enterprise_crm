import '../../domain/entities/employee_kpi.dart';

/// Data Transfer Object representing an Employee KPI record from the backend API.
///
/// Established in HR-10.7 to handle serialization, deserialization, and strict validation
/// between the instructor backend JSON schemas and the immutable [EmployeeKpi] domain model.
///
/// Invariants:
/// - Rejects malformed JSON lacking required fields (`id`, `employee_id`, `metric_name`, `period_start`, `period_end`, `target_value`, `actual_value`).
/// - Calendar dates are strictly normalized to UTC midnight.
/// - Metric names cannot be blank.
/// - Period end dates cannot precede period start dates.
/// - Stored scores are preserved verbatim; client-side score computation is prohibited.
class EmployeeKpiDto {
  final String id;
  final String employeeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String metricName;
  final double targetValue;
  final double actualValue;
  final double? score;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeKpiDto({
    required this.id,
    required this.employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required this.metricName,
    required this.targetValue,
    required this.actualValue,
    this.score,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  })  : periodStart = DateTime.utc(
          periodStart.year,
          periodStart.month,
          periodStart.day,
        ),
        periodEnd = DateTime.utc(
          periodEnd.year,
          periodEnd.month,
          periodEnd.day,
        );

  /// Constructs an [EmployeeKpiDto] from raw JSON map.
  ///
  /// Throws [FormatException] if any required fields are missing, invalid, or out of domain bounds.
  factory EmployeeKpiDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('Missing or empty "id" in KPI JSON payload.');
    }

    final rawEmployeeId = (json['employee_id'] ?? json['employeeId'])?.toString().trim();
    if (rawEmployeeId == null || rawEmployeeId.isEmpty) {
      throw const FormatException('Missing or empty "employee_id" in KPI JSON payload.');
    }

    final rawMetricName = (json['metric_name'] ?? json['metricName'])?.toString().trim();
    if (rawMetricName == null || rawMetricName.isEmpty) {
      throw const FormatException('Missing or empty "metric_name" in KPI JSON payload.');
    }

    final rawStart = (json['period_start'] ?? json['periodStart'])?.toString().trim();
    if (rawStart == null || rawStart.isEmpty) {
      throw const FormatException('Missing or empty "period_start" in KPI JSON payload.');
    }
    final parsedStart = DateTime.tryParse(rawStart);
    if (parsedStart == null) {
      throw FormatException('Invalid "period_start" date format: "$rawStart"');
    }

    final rawEnd = (json['period_end'] ?? json['periodEnd'])?.toString().trim();
    if (rawEnd == null || rawEnd.isEmpty) {
      throw const FormatException('Missing or empty "period_end" in KPI JSON payload.');
    }
    final parsedEnd = DateTime.tryParse(rawEnd);
    if (parsedEnd == null) {
      throw FormatException('Invalid "period_end" date format: "$rawEnd"');
    }

    final normalizedStart = DateTime.utc(parsedStart.year, parsedStart.month, parsedStart.day);
    final normalizedEnd = DateTime.utc(parsedEnd.year, parsedEnd.month, parsedEnd.day);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const FormatException('KPI "period_end" date cannot precede "period_start" date.');
    }

    final rawTarget = json['target_value'] ?? json['targetValue'];
    if (rawTarget == null || (rawTarget is! num && double.tryParse(rawTarget.toString()) == null)) {
      throw const FormatException('Missing or invalid "target_value" in KPI JSON payload.');
    }
    final targetValue = rawTarget is num ? rawTarget.toDouble() : double.parse(rawTarget.toString());

    final rawActual = json['actual_value'] ?? json['actualValue'];
    if (rawActual == null || (rawActual is! num && double.tryParse(rawActual.toString()) == null)) {
      throw const FormatException('Missing or invalid "actual_value" in KPI JSON payload.');
    }
    final actualValue = rawActual is num ? rawActual.toDouble() : double.parse(rawActual.toString());

    final rawScore = json['score'];
    final double? score;
    if (rawScore == null) {
      score = null;
    } else if (rawScore is num) {
      score = rawScore.toDouble();
    } else {
      score = double.tryParse(rawScore.toString());
    }

    final remarks = json['remarks']?.toString().trim();

    final rawCreatedAt = (json['created_at'] ?? json['createdAt'])?.toString().trim();
    final createdAt = rawCreatedAt != null && rawCreatedAt.isNotEmpty
        ? DateTime.tryParse(rawCreatedAt)?.toUtc()
        : null;

    final rawUpdatedAt = (json['updated_at'] ?? json['updatedAt'])?.toString().trim();
    final updatedAt = rawUpdatedAt != null && rawUpdatedAt.isNotEmpty
        ? DateTime.tryParse(rawUpdatedAt)?.toUtc()
        : null;

    return EmployeeKpiDto(
      id: rawId,
      employeeId: rawEmployeeId,
      periodStart: normalizedStart,
      periodEnd: normalizedEnd,
      metricName: rawMetricName,
      targetValue: targetValue,
      actualValue: actualValue,
      score: score,
      remarks: remarks != null && remarks.isNotEmpty ? remarks : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Maps this DTO to an immutable domain [EmployeeKpi].
  EmployeeKpi toDomain() {
    return EmployeeKpi(
      id: id,
      employeeId: employeeId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      metricName: metricName,
      targetValue: targetValue,
      actualValue: actualValue,
      score: score,
      remarks: remarks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a DTO from an existing domain [EmployeeKpi].
  factory EmployeeKpiDto.fromDomain(EmployeeKpi domain) {
    return EmployeeKpiDto(
      id: domain.id,
      employeeId: domain.employeeId,
      periodStart: domain.periodStart,
      periodEnd: domain.periodEnd,
      metricName: domain.metricName,
      targetValue: domain.targetValue,
      actualValue: domain.actualValue,
      score: domain.score,
      remarks: domain.remarks,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
  }

  /// Serializes this DTO to standard backend JSON representation with snake_case keys.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'employee_id': employeeId,
      'metric_name': metricName,
      'period_start': _formatDate(periodStart),
      'period_end': _formatDate(periodEnd),
      'target_value': targetValue,
      'actual_value': actualValue,
    };
    if (score != null) {
      map['score'] = score;
    }
    if (remarks != null) {
      map['remarks'] = remarks;
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
