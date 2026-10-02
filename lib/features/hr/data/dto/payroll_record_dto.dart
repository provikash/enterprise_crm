import '../../domain/entities/payroll_record.dart';

/// Data Transfer Object representing a Payroll Record from the backend API.
///
/// Established in HR-10.8 to handle serialization, deserialization, and strict validation
/// between the instructor backend JSON schemas and the immutable [PayrollRecord] domain model.
///
/// Invariants:
/// - Rejects malformed JSON lacking required identifiers (`id`, `employee_id`, `payroll_period_id`).
/// - Monetary amounts are preserved exactly; missing compensation values are NEVER fabricated as 0.0.
/// - Client-side recomputation of net salary or gross salary is strictly prohibited.
/// - Dates are normalized to UTC midnight.
class PayrollRecordDto {
  final String id;
  final String employeeId;
  final String payrollPeriodId;
  final double? grossSalary;
  final double? netSalary;
  final double? totalAllowances;
  final double? totalDeductions;
  final String? currency;
  final String? paymentStatus;
  final DateTime? paymentDate;
  final String? remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PayrollRecordDto({
    required this.id,
    required this.employeeId,
    required this.payrollPeriodId,
    this.grossSalary,
    this.netSalary,
    this.totalAllowances,
    this.totalDeductions,
    this.currency,
    this.paymentStatus,
    DateTime? paymentDate,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  }) : paymentDate = paymentDate != null
            ? DateTime.utc(paymentDate.year, paymentDate.month, paymentDate.day)
            : null;

  /// Constructs a [PayrollRecordDto] from raw JSON map.
  ///
  /// Throws [FormatException] if any required identifier fields are missing or empty.
  factory PayrollRecordDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('Missing or empty "id" in PayrollRecord JSON.');
    }

    final rawEmployeeId = (json['employee_id'] ?? json['employeeId'])?.toString().trim();
    if (rawEmployeeId == null || rawEmployeeId.isEmpty) {
      throw const FormatException('Missing or empty "employee_id" in PayrollRecord JSON.');
    }

    final rawPeriodId = (json['payroll_period_id'] ?? json['payrollPeriodId'] ?? json['period_id'])?.toString().trim();
    if (rawPeriodId == null || rawPeriodId.isEmpty) {
      throw const FormatException('Missing or empty "payroll_period_id" in PayrollRecord JSON.');
    }

    double? parseMoney(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final grossSalary = parseMoney(json['gross_salary'] ?? json['grossSalary']);
    final netSalary = parseMoney(json['net_salary'] ?? json['netSalary']);
    final totalAllowances = parseMoney(json['total_allowances'] ?? json['totalAllowances']);
    final totalDeductions = parseMoney(json['total_deductions'] ?? json['totalDeductions']);

    final currency = json['currency']?.toString().trim();
    final paymentStatus = (json['payment_status'] ?? json['paymentStatus'])?.toString().trim();

    final rawPaymentDate = (json['payment_date'] ?? json['paymentDate'])?.toString().trim();
    final parsedPayment = rawPaymentDate != null && rawPaymentDate.isNotEmpty
        ? DateTime.tryParse(rawPaymentDate)
        : null;
    final paymentDate = parsedPayment != null
        ? DateTime.utc(parsedPayment.year, parsedPayment.month, parsedPayment.day)
        : null;

    final remarks = json['remarks']?.toString().trim();

    final rawCreatedAt = (json['created_at'] ?? json['createdAt'])?.toString().trim();
    final createdAt = rawCreatedAt != null && rawCreatedAt.isNotEmpty
        ? DateTime.tryParse(rawCreatedAt)?.toUtc()
        : null;

    final rawUpdatedAt = (json['updated_at'] ?? json['updatedAt'])?.toString().trim();
    final updatedAt = rawUpdatedAt != null && rawUpdatedAt.isNotEmpty
        ? DateTime.tryParse(rawUpdatedAt)?.toUtc()
        : null;

    return PayrollRecordDto(
      id: rawId,
      employeeId: rawEmployeeId,
      payrollPeriodId: rawPeriodId,
      grossSalary: grossSalary,
      netSalary: netSalary,
      totalAllowances: totalAllowances,
      totalDeductions: totalDeductions,
      currency: currency != null && currency.isNotEmpty ? currency : null,
      paymentStatus: paymentStatus != null && paymentStatus.isNotEmpty ? paymentStatus : null,
      paymentDate: paymentDate,
      remarks: remarks != null && remarks.isNotEmpty ? remarks : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Maps this DTO to an immutable domain [PayrollRecord].
  PayrollRecord toDomain() {
    return PayrollRecord(
      id: id,
      employeeId: employeeId,
      payrollPeriodId: payrollPeriodId,
      grossSalary: grossSalary,
      netSalary: netSalary,
      totalAllowances: totalAllowances,
      totalDeductions: totalDeductions,
      currency: currency,
      paymentStatus: paymentStatus,
      paymentDate: paymentDate,
      remarks: remarks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a DTO from an existing domain [PayrollRecord].
  factory PayrollRecordDto.fromDomain(PayrollRecord domain) {
    return PayrollRecordDto(
      id: domain.id,
      employeeId: domain.employeeId,
      payrollPeriodId: domain.payrollPeriodId,
      grossSalary: domain.grossSalary,
      netSalary: domain.netSalary,
      totalAllowances: domain.totalAllowances,
      totalDeductions: domain.totalDeductions,
      currency: domain.currency,
      paymentStatus: domain.paymentStatus,
      paymentDate: domain.paymentDate,
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
      'payroll_period_id': payrollPeriodId,
    };
    if (grossSalary != null) {
      map['gross_salary'] = grossSalary;
    }
    if (netSalary != null) {
      map['net_salary'] = netSalary;
    }
    if (totalAllowances != null) {
      map['total_allowances'] = totalAllowances;
    }
    if (totalDeductions != null) {
      map['total_deductions'] = totalDeductions;
    }
    if (currency != null) {
      map['currency'] = currency;
    }
    if (paymentStatus != null) {
      map['payment_status'] = paymentStatus;
    }
    if (paymentDate != null) {
      map['payment_date'] = _formatDate(paymentDate!);
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
