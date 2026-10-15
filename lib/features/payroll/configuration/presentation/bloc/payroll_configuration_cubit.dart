import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/payroll_configuration.dart';
import '../../domain/payroll_configuration_repository.dart';

sealed class PayrollConfigurationState {
  const PayrollConfigurationState();
}

class PayrollConfigurationLoading extends PayrollConfigurationState {
  const PayrollConfigurationLoading();
}

class PayrollConfigurationReady extends PayrollConfigurationState {
  final PayrollConfigurationSnapshot data;
  final bool submitting;
  final String? message;

  const PayrollConfigurationReady(
    this.data, {
    this.submitting = false,
    this.message,
  });
}

class PayrollConfigurationFailure extends PayrollConfigurationState {
  final String message;
  const PayrollConfigurationFailure(this.message);
}

class PayrollConfigurationCubit extends Cubit<PayrollConfigurationState> {
  final PayrollConfigurationRepository _repository;

  PayrollConfigurationCubit(this._repository)
    : super(const PayrollConfigurationLoading());

  Future<void> load() async {
    emit(const PayrollConfigurationLoading());
    try {
      emit(PayrollConfigurationReady(await _repository.load()));
    } catch (_) {
      emit(
        const PayrollConfigurationFailure(
          'Payroll configuration could not be loaded.',
        ),
      );
    }
  }

  Future<bool> createComponent({
    required String code,
    required String name,
    required SalaryComponentKind kind,
    required bool taxable,
    required DateTime effectiveFrom,
  }) async {
    final current = state;
    if (current is! PayrollConfigurationReady || current.submitting) {
      return false;
    }
    emit(PayrollConfigurationReady(current.data, submitting: true));
    try {
      await _repository.createComponent(
        code: code,
        name: name,
        kind: kind,
        taxable: taxable,
        effectiveFrom: effectiveFrom,
      );
      final refreshed = await _repository.load();
      emit(
        PayrollConfigurationReady(
          refreshed,
          message: 'Salary component created.',
        ),
      );
      return true;
    } catch (error) {
      emit(
        PayrollConfigurationReady(
          current.data,
          message: error is StateError
              ? error.message.toString()
              : 'The component could not be created.',
        ),
      );
      return false;
    }
  }
}
