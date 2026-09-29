import '../value_objects/money.dart';

/// Immutable domain entity representing validated input data supplied to a
/// payroll calculation operation in the Enterprise CRM HR module.
///
/// Follows HR-7.2 and HR-7.3 domain contracts:
/// - Stably identified by a unique [id].
/// - Stably references [Employee.id] via [employeeId].
/// - Stably references [PayrollPeriod.id] via [payrollPeriodId].
/// - Binds [baseSalary] represented as an exact [Money] value object.
/// - Captures optional [unpaidLeaveDays] for attendance-based adjustments.
/// - Performs zero client-side calculation inside the entity.
class PayrollCalculationInput {
  /// Unique identifier of this calculation input instance.
  final String id;

  /// Foreign key referencing the physical workforce entity [Employee.id].
  final String employeeId;

  /// Foreign key referencing the active [PayrollPeriod.id].
  final String payrollPeriodId;

  /// Contracted monthly base compensation for this calculation.
  final Money baseSalary;

  /// Number of unpaid absence / Loss of Pay days for the period (defaults to 0).
  final int unpaidLeaveDays;

  /// Optional administrative notes or adjustment justifications.
  final String? remarks;

  /// Timestamp when this calculation input was configured (normalized to UTC).
  final DateTime? createdAt;

  PayrollCalculationInput({
    required this.id,
    required this.employeeId,
    required this.payrollPeriodId,
    required this.baseSalary,
    this.unpaidLeaveDays = 0,
    this.remarks,
    DateTime? createdAt,
  }) : createdAt = createdAt?.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Calculation input ID cannot be empty');
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
    if (unpaidLeaveDays < 0) {
      throw ArgumentError.value(
        unpaidLeaveDays,
        'unpaidLeaveDays',
        'Unpaid leave days cannot be negative',
      );
    }
  }

  /// Creates a copy of this calculation input with updated fields.
  PayrollCalculationInput copyWith({
    String? id,
    String? employeeId,
    String? payrollPeriodId,
    Money? baseSalary,
    int? unpaidLeaveDays,
    String? remarks,
    bool clearRemarks = false,
    DateTime? createdAt,
  }) {
    return PayrollCalculationInput(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      baseSalary: baseSalary ?? this.baseSalary,
      unpaidLeaveDays: unpaidLeaveDays ?? this.unpaidLeaveDays,
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollCalculationInput &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          employeeId == employeeId &&
          payrollPeriodId == payrollPeriodId &&
          baseSalary == other.baseSalary &&
          unpaidLeaveDays == other.unpaidLeaveDays &&
          remarks == other.remarks &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        payrollPeriodId,
        baseSalary,
        unpaidLeaveDays,
        remarks,
        createdAt,
      );

  @override
  String toString() =>
      'PayrollCalculationInput(id: $id, employeeId: $employeeId, periodId: $payrollPeriodId, baseSalary: $baseSalary, unpaidLeaveDays: $unpaidLeaveDays)';
}
