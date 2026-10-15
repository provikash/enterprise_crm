import 'package:enterprise_crm/features/payroll/configuration/data/mock_payroll_configuration_repository.dart';
import 'package:enterprise_crm/features/payroll/configuration/domain/payroll_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockPayrollConfigurationRepository repository;

  setUp(() {
    repository = MockPayrollConfigurationRepository(latency: Duration.zero);
  });

  test(
    'loads realistic configuration data for every configuration tab',
    () async {
      final result = await repository.load();

      expect(result.components, isNotEmpty);
      expect(result.structures, isNotEmpty);
      expect(result.statutoryVersions, isNotEmpty);
      expect(result.payGroups, isNotEmpty);
      expect(result.payGroups.first.periods, isNotEmpty);
    },
  );

  test('creates and retains a mock salary component', () async {
    await repository.createComponent(
      code: 'bonus',
      name: 'Performance Bonus',
      kind: SalaryComponentKind.earning,
      taxable: true,
      effectiveFrom: DateTime(2026, 11),
    );

    final result = await repository.load();
    expect(result.components.last.code, 'BONUS');
    expect(result.components.last.name, 'Performance Bonus');
  });

  test('rejects a duplicate component code', () async {
    await expectLater(
      repository.createComponent(
        code: 'BASIC',
        name: 'Duplicate Basic',
        kind: SalaryComponentKind.earning,
        taxable: true,
        effectiveFrom: DateTime(2026, 11),
      ),
      throwsStateError,
    );
  });
}
