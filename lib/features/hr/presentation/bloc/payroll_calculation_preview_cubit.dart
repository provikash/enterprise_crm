import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_calculation_input.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../domain/services/payroll_calculation_engine.dart';
import 'payroll_calculation_preview_state.dart';

/// Cubit managing state for the Payroll Calculation Preview workflow.
///
/// Follows HR-7.6 architectural boundaries:
/// - Pure orchestration: delegates all financial calculations to [PayrollCalculationEngine].
/// - Resolves relational context from [EmployeeRepository] and [PayrollRepository].
/// - Supports interactive simulation via [AttendanceProrationPolicy] switching.
/// - Concurrency-safe: tracks request IDs to prevent race condition regressions.
/// - Side-effect free: strictly preview; zero persistence or state mutation outside memory.
class PayrollCalculationPreviewCubit
    extends Cubit<PayrollCalculationPreviewState> {
  final PayrollCalculationEngine _engine;
  final EmployeeRepository? _employeeRepository;
  final PayrollRepository? _payrollRepository;

  int _activeRequestId = 0;

  PayrollCalculationPreviewCubit({
    PayrollCalculationEngine engine = const PayrollCalculationEngine(),
    EmployeeRepository? employeeRepository,
    PayrollRepository? payrollRepository,
    PayrollCalculationInput? initialInput,
    AttendanceProrationPolicy initialAttendancePolicy =
        AttendanceProrationPolicy.unresolved,
  })  : _engine = engine,
        _employeeRepository = employeeRepository,
        _payrollRepository = payrollRepository,
        super(
          PayrollCalculationPreviewState(
            input: initialInput,
            attendancePolicy: initialAttendancePolicy,
          ),
        ) {
    if (initialInput != null) {
      calculatePreview(
        input: initialInput,
        attendancePolicy: initialAttendancePolicy,
      );
    }
  }

  /// Evaluates a calculation preview for the specified [input].
  Future<void> calculatePreview({
    required PayrollCalculationInput input,
    AttendanceProrationPolicy? attendancePolicy,
    DateTime? calculationTimestamp,
  }) async {
    final requestId = ++_activeRequestId;
    final effectivePolicy = attendancePolicy ?? state.attendancePolicy;

    emit(
      state.copyWith(
        status: PayrollCalculationPreviewStatus.loading,
        input: input,
        attendancePolicy: effectivePolicy,
        clearErrorMessage: true,
      ),
    );

    try {
      // 1. Resolve employee metadata if repository is available
      Employee? employee = state.employee;
      if (employee == null || employee.id != input.employeeId) {
        if (_employeeRepository != null) {
          try {
            employee =
                await _employeeRepository.getEmployeeById(input.employeeId);
          } catch (_) {
            // Non-fatal repository lookup failure
          }
        }
      }

      // 2. Resolve period metadata if repository is available
      PayrollPeriod? period = state.period;
      if (period == null || period.id != input.payrollPeriodId) {
        if (_payrollRepository != null) {
          try {
            period = await _payrollRepository
                .getPayrollPeriodById(input.payrollPeriodId);
          } catch (_) {
            // Non-fatal repository lookup failure
          }
        }
      }

      if (requestId != _activeRequestId || isClosed) return;

      // 3. Delegate calculation to pure domain engine
      final result = _engine.calculate(
        input: input,
        periodStartDate: period?.startDate,
        periodEndDate: period?.endDate,
        employeeJoiningDate: employee?.joiningDate,
        employmentStatus: employee?.employmentStatus,
        attendancePolicy: effectivePolicy,
        calculationTimestamp: calculationTimestamp,
      );

      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollCalculationPreviewStatus.loaded,
          input: input,
          result: result,
          employee: employee,
          period: period,
          attendancePolicy: effectivePolicy,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (requestId != _activeRequestId || isClosed) return;

      emit(
        state.copyWith(
          status: PayrollCalculationPreviewStatus.error,
          errorMessage:
              'Failed to generate payroll calculation preview. Please review inputs and try again.',
        ),
      );
    }
  }

  /// Updates the attendance proration policy and recalculates the preview.
  Future<void> setAttendancePolicy(AttendanceProrationPolicy newPolicy) async {
    if (state.input == null) return;
    await calculatePreview(
      input: state.input!,
      attendancePolicy: newPolicy,
    );
  }

  /// Retries calculation using the current input and policy.
  Future<void> retry() async {
    if (state.input == null) return;
    await calculatePreview(
      input: state.input!,
      attendancePolicy: state.attendancePolicy,
    );
  }
}
