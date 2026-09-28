/// Immutable domain entity representing a Payroll Record in the Enterprise CRM HR module.
///
/// Follows HR-6.1 frozen business requirements:
/// - Stably identified by a unique [id].
/// - Stably associated with an [employeeId] referencing [Employee.id].
/// - Stably associated with a [payrollPeriodId] referencing [PayrollPeriod.id].
/// - Preserves stored compensation amounts ([grossSalary], [netSalary], [totalAllowances], [totalDeductions])
///   exactly as provided by the authoritative data source without client-side calculation or rounding.
/// - [currency] represents the ISO currency code (e.g. 'INR', 'USD').
/// - [paymentStatus] is a flexible string status (e.g. 'Paid', 'Pending', 'Processing').
/// - [paymentDate] is an optional normalized UTC date.
/// - Strictly decoupled from UI and networking dependencies.
class PayrollRecord {
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

  PayrollRecord({
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
           : null {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Payroll record ID cannot be empty');
    }
    if (employeeId.trim().isEmpty) {
      throw ArgumentError.value(
        employeeId,
        'employeeId',
        'Employee ID cannot be empty',
      );
    }
    if (payrollPeriodId.trim().isEmpty) {
      throw ArgumentError.value(
        payrollPeriodId,
        'payrollPeriodId',
        'Payroll period ID cannot be empty',
      );
    }
  }

  /// Formatted payment date in 'YYYY-MM-DD' format, or `null` if not set.
  String? get formattedPaymentDate {
    if (paymentDate == null) return null;
    final y = paymentDate!.year.toString().padLeft(4, '0');
    final m = paymentDate!.month.toString().padLeft(2, '0');
    final d = paymentDate!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Creates a copy of this payroll record with updated fields.
  PayrollRecord copyWith({
    String? id,
    String? employeeId,
    String? payrollPeriodId,
    double? grossSalary,
    bool clearGrossSalary = false,
    double? netSalary,
    bool clearNetSalary = false,
    double? totalAllowances,
    bool clearTotalAllowances = false,
    double? totalDeductions,
    bool clearTotalDeductions = false,
    String? currency,
    bool clearCurrency = false,
    String? paymentStatus,
    bool clearPaymentStatus = false,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    String? remarks,
    bool clearRemarks = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      grossSalary: clearGrossSalary ? null : (grossSalary ?? this.grossSalary),
      netSalary: clearNetSalary ? null : (netSalary ?? this.netSalary),
      totalAllowances: clearTotalAllowances
          ? null
          : (totalAllowances ?? this.totalAllowances),
      totalDeductions: clearTotalDeductions
          ? null
          : (totalDeductions ?? this.totalDeductions),
      currency: clearCurrency ? null : (currency ?? this.currency),
      paymentStatus: clearPaymentStatus
          ? null
          : (paymentStatus ?? this.paymentStatus),
      paymentDate: clearPaymentDate ? null : (paymentDate ?? this.paymentDate),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollRecord &&
        runtimeType == other.runtimeType &&
        other.id == id &&
        other.employeeId == employeeId &&
        other.payrollPeriodId == payrollPeriodId &&
        other.grossSalary == grossSalary &&
        other.netSalary == netSalary &&
        other.totalAllowances == totalAllowances &&
        other.totalDeductions == totalDeductions &&
        other.currency == currency &&
        other.paymentStatus == paymentStatus &&
        other.paymentDate == paymentDate &&
        other.remarks == remarks;
  }

  @override
  int get hashCode => Object.hash(
    id,
    employeeId,
    payrollPeriodId,
    grossSalary,
    netSalary,
    totalAllowances,
    totalDeductions,
    currency,
    paymentStatus,
    paymentDate,
    remarks,
  );

  @override
  String toString() =>
      'PayrollRecord(id: $id, employeeId: $employeeId, periodId: $payrollPeriodId, gross: $grossSalary, net: $netSalary, status: $paymentStatus)';
}
