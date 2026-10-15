import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/domain/money.dart';
import '../../domain/payroll_operations.dart';
import '../../domain/payroll_operations_repository.dart';

sealed class PayrollOperationsState {
  const PayrollOperationsState();
}

class PayrollOperationsLoading extends PayrollOperationsState {
  const PayrollOperationsLoading();
}

class PayrollOperationsFailure extends PayrollOperationsState {
  final String message;
  const PayrollOperationsFailure(this.message);
}

class PayrollOperationsReady extends PayrollOperationsState {
  final PayrollOperationsSnapshot data;
  final bool busy;
  final String? message;
  final bool isError;

  const PayrollOperationsReady(
    this.data, {
    this.busy = false,
    this.message,
    this.isError = false,
  });
}

class PayrollOperationsCubit extends Cubit<PayrollOperationsState> {
  final PayrollOperationsRepository _repository;

  PayrollOperationsCubit(this._repository)
    : super(const PayrollOperationsLoading());

  Future<void> load() async {
    emit(const PayrollOperationsLoading());
    try {
      emit(PayrollOperationsReady(await _repository.load()));
    } catch (_) {
      emit(const PayrollOperationsFailure('Payroll data could not be loaded.'));
    }
  }

  Future<void> updateCompensation({
    required String employeeId,
    required Money basicSalary,
    required Money fixedAllowance,
    required Money fixedDeduction,
  }) => _mutate(
    () => _repository.updateCompensation(
      employeeId: employeeId,
      basicSalary: basicSalary,
      fixedAllowance: fixedAllowance,
      fixedDeduction: fixedDeduction,
    ),
    'Compensation updated.',
  );

  Future<void> setHold(String employeeId, bool value) => _mutate(
    () => _repository.setPayrollHold(employeeId, value),
    value ? 'Employee placed on payroll hold.' : 'Payroll hold removed.',
  );

  Future<void> addInput({
    required String employeeId,
    required PayrollInputKind kind,
    required Money amount,
    required String note,
  }) => _mutate(
    () => _repository.addInput(
      employeeId: employeeId,
      kind: kind,
      amount: amount,
      note: note,
    ),
    'Payroll input added.',
  );

  Future<void> deleteInput(String inputId) =>
      _mutate(() => _repository.deleteInput(inputId), 'Payroll input removed.');

  Future<void> createRun(String period, String actor) =>
      _mutate(() => _repository.createRun(period, actor), 'Pay run created.');

  Future<void> calculate(String runId, String actor) => _mutate(
    () => _repository.calculateRun(runId, actor),
    'Pay run calculated.',
  );

  Future<void> submit(String runId, String actor) => _mutate(
    () => _repository.submitRun(runId, actor),
    'Pay run submitted for review.',
  );

  Future<void> approve(String runId, String actor) =>
      _mutate(() => _repository.approveRun(runId, actor), 'Pay run approved.');

  Future<void> lock(String runId, String actor) => _mutate(
    () => _repository.lockRun(runId, actor),
    'Pay run locked and payment batch created.',
  );

  Future<void> releasePayment(String batchId, String actor) => _mutate(
    () => _repository.releasePayment(batchId, actor),
    'Payment released and pay run marked paid.',
  );

  Future<void> _mutate(
    Future<Object?> Function() operation,
    String success,
  ) async {
    final current = state;
    if (current is! PayrollOperationsReady || current.busy) return;
    emit(PayrollOperationsReady(current.data, busy: true));
    try {
      await operation();
      emit(PayrollOperationsReady(await _repository.load(), message: success));
    } catch (error) {
      emit(
        PayrollOperationsReady(
          current.data,
          message: error.toString(),
          isError: true,
        ),
      );
    }
  }
}
