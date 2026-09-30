import 'package:flutter/foundation.dart';

import '../value_objects/money.dart';
import 'payroll_component.dart';

/// Immutable domain entity representing validated input data supplied to a
/// payroll calculation operation in the Enterprise CRM HR module.
///
/// Follows HR-7.2, HR-7.3, and HR-7.4 domain contracts:
/// - Stably identified by a unique [id].
/// - Stably references [Employee.id] via [employeeId].
/// - Stably references [PayrollPeriod.id] via [payrollPeriodId].
/// - Binds [baseSalary] represented as an exact [Money] value object.
/// - Captures optional [unpaidLeaveDays] for attendance-based adjustments.
/// - Supports optional itemized [components] (allowances, deductions, adjustments).
/// - Enforces currency consistency between [baseSalary] and all attached [components].
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

  /// Itemized payroll components (allowances, deductions, overrides) applicable to this run.
  final List<PayrollComponent> components;

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
    List<PayrollComponent>? components,
    this.remarks,
    DateTime? createdAt,
  })  : components = List.unmodifiable(components ?? const []),
        createdAt = createdAt?.toUtc() {
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
    for (final comp in this.components) {
      if (comp.currency != baseSalary.currency) {
        throw ArgumentError(
          'Payroll component currency (${comp.currency}) does not match base salary currency (${baseSalary.currency}) for component ID: ${comp.id}',
        );
      }
    }
  }

  /// Convenience getter for itemized earnings.
  List<PayrollComponent> get earnings =>
      components.where((c) => c.isEarning).toList();

  /// Convenience getter for itemized deductions.
  List<PayrollComponent> get deductions =>
      components.where((c) => c.isDeduction).toList();

  /// Creates a copy of this calculation input with updated fields.
  PayrollCalculationInput copyWith({
    String? id,
    String? employeeId,
    String? payrollPeriodId,
    Money? baseSalary,
    int? unpaidLeaveDays,
    List<PayrollComponent>? components,
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
      components: components ?? this.components,
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
          employeeId == other.employeeId &&
          payrollPeriodId == other.payrollPeriodId &&
          baseSalary == other.baseSalary &&
          unpaidLeaveDays == other.unpaidLeaveDays &&
          listEquals(components, other.components) &&
          remarks == other.remarks &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        payrollPeriodId,
        baseSalary,
        unpaidLeaveDays,
        Object.hashAll(components),
        remarks,
        createdAt,
      );

  @override
  String toString() =>
      'PayrollCalculationInput(id: $id, employeeId: $employeeId, periodId: $payrollPeriodId, baseSalary: $baseSalary, unpaidLeaveDays: $unpaidLeaveDays)';
}
