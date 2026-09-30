import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_calculation_input.dart';
import '../../domain/entities/payroll_calculation_result.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/services/payroll_calculation_engine.dart';

/// Status of the payroll calculation preview workflow.
enum PayrollCalculationPreviewStatus {
  /// Initial uncalculated state.
  initial,

  /// Calculation preview is being evaluated.
  loading,

  /// Calculation preview successfully produced.
  loaded,

  /// Calculation preview evaluation failed.
  error,
}

/// Immutable state for the Payroll Calculation Preview workflow.
///
/// Follows HR-7.6 presentation requirements:
/// - Encapsulates [status] of the preview.
/// - Holds the active [input] and calculated [result].
/// - Resolves associated [employee] and [period] models for presentation context.
/// - Stores active [attendancePolicy] to support interactive policy simulation.
/// - Sanitizes [errorMessage] on failure.
class PayrollCalculationPreviewState {
  final PayrollCalculationPreviewStatus status;
  final PayrollCalculationInput? input;
  final PayrollCalculationResult? result;
  final Employee? employee;
  final PayrollPeriod? period;
  final AttendanceProrationPolicy attendancePolicy;
  final String? errorMessage;

  const PayrollCalculationPreviewState({
    this.status = PayrollCalculationPreviewStatus.initial,
    this.input,
    this.result,
    this.employee,
    this.period,
    this.attendancePolicy = AttendanceProrationPolicy.unresolved,
    this.errorMessage,
  });

  /// Whether calculation is currently evaluating.
  bool get isLoading => status == PayrollCalculationPreviewStatus.loading;

  /// Whether calculation preview is loaded and available.
  bool get isLoaded => status == PayrollCalculationPreviewStatus.loaded;

  /// Whether an error occurred.
  bool get isError => status == PayrollCalculationPreviewStatus.error;

  /// Whether a calculation result exists.
  bool get hasResult => result != null;

  /// Creates a copy of this state with updated fields.
  PayrollCalculationPreviewState copyWith({
    PayrollCalculationPreviewStatus? status,
    PayrollCalculationInput? input,
    bool clearInput = false,
    PayrollCalculationResult? result,
    bool clearResult = false,
    Employee? employee,
    bool clearEmployee = false,
    PayrollPeriod? period,
    bool clearPeriod = false,
    AttendanceProrationPolicy? attendancePolicy,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PayrollCalculationPreviewState(
      status: status ?? this.status,
      input: clearInput ? null : (input ?? this.input),
      result: clearResult ? null : (result ?? this.result),
      employee: clearEmployee ? null : (employee ?? this.employee),
      period: clearPeriod ? null : (period ?? this.period),
      attendancePolicy: attendancePolicy ?? this.attendancePolicy,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollCalculationPreviewState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          input == other.input &&
          result == other.result &&
          employee == other.employee &&
          period == other.period &&
          attendancePolicy == other.attendancePolicy &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        input,
        result,
        employee,
        period,
        attendancePolicy,
        errorMessage,
      );

  @override
  String toString() =>
      'PayrollCalculationPreviewState(status: $status, hasResult: $hasResult, policy: $attendancePolicy)';
}
