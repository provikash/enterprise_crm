import 'payroll_configuration.dart';

abstract interface class PayrollConfigurationRepository {
  Future<PayrollConfigurationSnapshot> load();

  Future<SalaryComponent> createComponent({
    required String code,
    required String name,
    required SalaryComponentKind kind,
    required bool taxable,
    required DateTime effectiveFrom,
  });
}
