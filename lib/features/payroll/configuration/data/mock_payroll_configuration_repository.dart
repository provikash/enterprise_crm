import '../domain/payroll_configuration.dart';
import '../domain/payroll_configuration_repository.dart';

class MockPayrollConfigurationRepository
    implements PayrollConfigurationRepository {
  final Duration latency;
  final List<SalaryComponent> _components = [
    SalaryComponent(
      id: 'component-basic',
      code: 'BASIC',
      name: 'Basic Salary',
      kind: SalaryComponentKind.earning,
      taxable: true,
      active: true,
      effectiveFrom: DateTime(2026, 4),
    ),
    SalaryComponent(
      id: 'component-hra',
      code: 'HRA',
      name: 'House Rent Allowance',
      kind: SalaryComponentKind.earning,
      taxable: true,
      active: true,
      effectiveFrom: DateTime(2026, 4),
    ),
    SalaryComponent(
      id: 'component-pf',
      code: 'EPF-EE',
      name: 'Employee Provident Fund',
      kind: SalaryComponentKind.deduction,
      taxable: false,
      active: true,
      effectiveFrom: DateTime(2026, 4),
    ),
    SalaryComponent(
      id: 'component-insurance',
      code: 'MED-INS',
      name: 'Medical Insurance',
      kind: SalaryComponentKind.deduction,
      taxable: false,
      active: false,
      effectiveFrom: DateTime(2026, 7),
    ),
  ];

  MockPayrollConfigurationRepository({
    this.latency = const Duration(milliseconds: 250),
  });

  @override
  Future<PayrollConfigurationSnapshot> load() async {
    await Future<void>.delayed(latency);
    return PayrollConfigurationSnapshot(
      components: List.unmodifiable(_components),
      structures: const [
        SalaryStructureSummary(
          id: 'structure-corporate',
          name: 'Corporate Staff',
          componentCount: 8,
          assignedEmployees: 84,
          active: true,
        ),
        SalaryStructureSummary(
          id: 'structure-sales',
          name: 'Sales and Incentives',
          componentCount: 10,
          assignedEmployees: 36,
          active: true,
        ),
        SalaryStructureSummary(
          id: 'structure-intern',
          name: 'Intern Stipend',
          componentCount: 3,
          assignedEmployees: 7,
          active: false,
        ),
      ],
      statutoryVersions: [
        StatutoryVersionSummary(
          id: 'stat-pf-2026',
          statute: 'Provident Fund',
          versionLabel: 'FY 2026-27',
          effectiveFrom: DateTime(2026, 4),
          current: true,
        ),
        StatutoryVersionSummary(
          id: 'stat-esi-2026',
          statute: 'Employee State Insurance',
          versionLabel: 'FY 2026-27',
          effectiveFrom: DateTime(2026, 4),
          current: true,
        ),
        StatutoryVersionSummary(
          id: 'stat-pt-2026',
          statute: 'Professional Tax',
          versionLabel: 'State schedule 2026',
          effectiveFrom: DateTime(2026, 4),
          current: true,
        ),
      ],
      payGroups: [
        PayGroupSummary(
          id: 'group-monthly',
          name: 'Monthly Payroll',
          frequency: 'Monthly',
          employeeCount: 120,
          periods: [
            PayrollPeriod(
              label: 'October 2026',
              startDate: DateTime(2026, 10),
              endDate: DateTime(2026, 10, 31),
              payDate: DateTime(2026, 10, 30),
              status: 'Open',
            ),
            PayrollPeriod(
              label: 'November 2026',
              startDate: DateTime(2026, 11),
              endDate: DateTime(2026, 11, 30),
              payDate: DateTime(2026, 11, 30),
              status: 'Upcoming',
            ),
          ],
        ),
        const PayGroupSummary(
          id: 'group-contract',
          name: 'Contract Staff',
          frequency: 'Monthly',
          employeeCount: 18,
          periods: [],
        ),
      ],
    );
  }

  @override
  Future<SalaryComponent> createComponent({
    required String code,
    required String name,
    required SalaryComponentKind kind,
    required bool taxable,
    required DateTime effectiveFrom,
  }) async {
    await Future<void>.delayed(latency);
    final normalizedCode = code.trim().toUpperCase();
    if (_components.any((item) => item.code == normalizedCode)) {
      throw StateError('A component with this code already exists.');
    }
    final component = SalaryComponent(
      id: 'component-${_components.length + 1}',
      code: normalizedCode,
      name: name.trim(),
      kind: kind,
      taxable: taxable,
      active: true,
      effectiveFrom: effectiveFrom,
    );
    _components.add(component);
    return component;
  }
}
