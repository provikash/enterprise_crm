import '../value_objects/money.dart';

/// Represents the classification of a payroll component (earning vs deduction).
enum PayrollComponentKind {
  /// Increases gross earnings (e.g. Base Salary, House Rent Allowance).
  earning,

  /// Decreases gross earnings to arrive at net payable (e.g. Loss of Pay, PF, Tax).
  deduction,
}

/// Represents the origin and calculation authority of a payroll component.
enum PayrollComponentSource {
  /// Provided directly as a stored input or contracted salary figure.
  stored,

  /// Derived dynamically by an approved, deterministic calculation rule.
  calculated,

  /// Authoritatively supplied by an external backend or statutory authority.
  backendAuthoritative,

  /// Approved one-time manual override or administrative adjustment.
  userAdjustment,
}

/// Immutable domain entity representing an individual payroll component
/// (earning or deduction) in the Enterprise CRM HR module.
///
/// Follows HR-7.1 through HR-7.4 domain specifications:
/// - Stably identified by a unique [id].
/// - Categorized strictly as [PayrollComponentKind.earning] or [PayrollComponentKind.deduction].
/// - Tracks origin via [PayrollComponentSource] (stored, calculated, backend, or user adjustment).
/// - Preserves exact monetary precision using the immutable [Money] value object.
/// - Requires non-negative monetary amounts (explicit ₹0.00 is allowed; negative amounts throw).
/// - Captures optional [effectiveDate] normalized to UTC midnight.
/// - Requires [calculationRuleId] whenever [source] is [PayrollComponentSource.calculated].
/// - Preserves immutability and financial integrity.
class PayrollComponent {
  /// Unique identifier of this component instance.
  final String id;

  /// Business label or display name (e.g. 'Basic Salary', 'Loss of Pay').
  final String name;

  /// Fundamental classification (earning or deduction).
  final PayrollComponentKind kind;

  /// Exact monetary value of this component.
  final Money amount;

  /// Authority or origin of this component value.
  final PayrollComponentSource source;

  /// Normalized UTC date when this component became effective or was applied.
  final DateTime? effectiveDate;

  /// Approved rule identifier (e.g. 'FORM-04-LOP') if dynamically calculated.
  final String? calculationRuleId;

  /// Optional administrative remarks, justifications, or metadata.
  final String? remarks;

  PayrollComponent({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    this.source = PayrollComponentSource.stored,
    DateTime? effectiveDate,
    this.calculationRuleId,
    this.remarks,
  }) : effectiveDate = effectiveDate != null
            ? DateTime.utc(
                effectiveDate.year,
                effectiveDate.month,
                effectiveDate.day,
              )
            : null {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Payroll component ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Payroll component name cannot be empty',
      );
    }
    if (amount.isNegative) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Payroll component amount cannot be negative. Individual earnings and '
            'deductions must be non-negative; net deficits are represented at aggregate level.',
      );
    }
    if (source == PayrollComponentSource.calculated) {
      if (calculationRuleId == null || calculationRuleId!.trim().isEmpty) {
        throw ArgumentError.value(
          calculationRuleId,
          'calculationRuleId',
          'Calculated payroll components must identify an approved calculation rule ID.',
        );
      }
    }
  }

  /// Convenience factory for creating an earning component.
  factory PayrollComponent.earning({
    required String id,
    required String name,
    required Money amount,
    PayrollComponentSource source = PayrollComponentSource.stored,
    DateTime? effectiveDate,
    String? calculationRuleId,
    String? remarks,
  }) {
    return PayrollComponent(
      id: id,
      name: name,
      kind: PayrollComponentKind.earning,
      amount: amount,
      source: source,
      effectiveDate: effectiveDate,
      calculationRuleId: calculationRuleId,
      remarks: remarks,
    );
  }

  /// Convenience factory for creating a deduction component.
  factory PayrollComponent.deduction({
    required String id,
    required String name,
    required Money amount,
    PayrollComponentSource source = PayrollComponentSource.stored,
    DateTime? effectiveDate,
    String? calculationRuleId,
    String? remarks,
  }) {
    return PayrollComponent(
      id: id,
      name: name,
      kind: PayrollComponentKind.deduction,
      amount: amount,
      source: source,
      effectiveDate: effectiveDate,
      calculationRuleId: calculationRuleId,
      remarks: remarks,
    );
  }

  /// Whether this is an earning component.
  bool get isEarning => kind == PayrollComponentKind.earning;

  /// Whether this is a deduction component.
  bool get isDeduction => kind == PayrollComponentKind.deduction;

  /// Whether this component is stored directly from inputs.
  bool get isStored => source == PayrollComponentSource.stored;

  /// Whether this component was dynamically calculated.
  bool get isCalculated => source == PayrollComponentSource.calculated;

  /// Whether this component was authoritatively provided by the backend.
  bool get isBackendAuthoritative =>
      source == PayrollComponentSource.backendAuthoritative;

  /// Whether this component represents a manual administrative adjustment.
  bool get isUserAdjustment => source == PayrollComponentSource.userAdjustment;

  /// ISO-4217 currency code of this component amount.
  String get currency => amount.currency;

  /// Whether this component is effective for the specified [periodEnd] date.
  ///
  /// If [effectiveDate] is not set, the component is treated as universally applicable.
  /// If [effectiveDate] is set, it must not be strictly after [periodEnd].
  bool isApplicableForPeriod(DateTime periodStart, DateTime periodEnd) {
    if (effectiveDate == null) return true;
    final normalizedEnd = DateTime.utc(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
    );
    return !effectiveDate!.isAfter(normalizedEnd);
  }

  /// Creates a copy of this component with updated fields.
  PayrollComponent copyWith({
    String? id,
    String? name,
    PayrollComponentKind? kind,
    Money? amount,
    PayrollComponentSource? source,
    DateTime? effectiveDate,
    bool clearEffectiveDate = false,
    String? calculationRuleId,
    bool clearCalculationRuleId = false,
    String? remarks,
    bool clearRemarks = false,
  }) {
    return PayrollComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      effectiveDate:
          clearEffectiveDate ? null : (effectiveDate ?? this.effectiveDate),
      calculationRuleId: clearCalculationRuleId
          ? null
          : (calculationRuleId ?? this.calculationRuleId),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollComponent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          kind == other.kind &&
          amount == other.amount &&
          source == other.source &&
          effectiveDate == other.effectiveDate &&
          calculationRuleId == other.calculationRuleId &&
          remarks == other.remarks;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        kind,
        amount,
        source,
        effectiveDate,
        calculationRuleId,
        remarks,
      );

  @override
  String toString() =>
      'PayrollComponent(id: $id, name: $name, kind: $kind, amount: $amount, source: $source)';
}
