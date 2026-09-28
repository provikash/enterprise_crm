import 'package:flutter/foundation.dart';

import '../../domain/entities/payroll_period.dart';

/// Lifecycle statuses for payroll period selection state.
enum PayrollPeriodStatus { initial, loading, loaded, failure }

/// Immutable state representation for Payroll Period loading and selection.
///
/// Follows HR-6.1 frozen business requirements and HR-6.4 specifications:
/// - Stably identifies the selected period via [selectedPeriodId].
/// - Strictly decoupled from salary calculations and payment processing.
/// - Encapsulates loading, loaded, empty, and failure states.
@immutable
class PayrollPeriodState {
  final PayrollPeriodStatus status;
  final List<PayrollPeriod> periods;
  final String? selectedPeriodId;
  final String? errorMessage;

  const PayrollPeriodState({
    this.status = PayrollPeriodStatus.initial,
    this.periods = const [],
    this.selectedPeriodId,
    this.errorMessage,
  });

  /// True when repository returned zero payroll periods.
  bool get isEmpty => status == PayrollPeriodStatus.loaded && periods.isEmpty;

  /// Returns the currently selected [PayrollPeriod], or `null` if none selected or not found.
  PayrollPeriod? get selectedPeriod {
    if (selectedPeriodId == null) return null;
    for (final p in periods) {
      if (p.id == selectedPeriodId) return p;
    }
    return null;
  }

  /// Whether a valid period is currently selected.
  bool get hasSelection => selectedPeriod != null;

  /// Creates a copy of this state with updated fields.
  PayrollPeriodState copyWith({
    PayrollPeriodStatus? status,
    List<PayrollPeriod>? periods,
    String? selectedPeriodId,
    bool clearSelection = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    final effectivePeriods = periods != null
        ? List<PayrollPeriod>.unmodifiable(periods)
        : this.periods;

    return PayrollPeriodState(
      status: status ?? this.status,
      periods: effectivePeriods,
      selectedPeriodId: clearSelection
          ? null
          : (selectedPeriodId ?? this.selectedPeriodId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollPeriodState &&
        other.status == status &&
        listEquals(other.periods, periods) &&
        other.selectedPeriodId == selectedPeriodId &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        Object.hashAll(periods),
        selectedPeriodId,
        errorMessage,
      );

  @override
  String toString() =>
      'PayrollPeriodState(status: $status, count: ${periods.length}, selected: $selectedPeriodId, error: $errorMessage)';
}
