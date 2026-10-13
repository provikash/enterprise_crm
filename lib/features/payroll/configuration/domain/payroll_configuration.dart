enum SalaryComponentKind { earning, deduction, employerContribution }

class SalaryComponent {
  final String id;
  final String code;
  final String name;
  final SalaryComponentKind kind;
  final bool taxable;
  final bool active;
  final DateTime effectiveFrom;

  const SalaryComponent({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    required this.taxable,
    required this.active,
    required this.effectiveFrom,
  });
}

class SalaryStructureSummary {
  final String id;
  final String name;
  final int componentCount;
  final int assignedEmployees;
  final bool active;

  const SalaryStructureSummary({
    required this.id,
    required this.name,
    required this.componentCount,
    required this.assignedEmployees,
    required this.active,
  });
}

class StatutoryVersionSummary {
  final String id;
  final String statute;
  final String versionLabel;
  final DateTime effectiveFrom;
  final bool current;

  const StatutoryVersionSummary({
    required this.id,
    required this.statute,
    required this.versionLabel,
    required this.effectiveFrom,
    required this.current,
  });
}

class PayrollPeriod {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime payDate;
  final String status;

  const PayrollPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.payDate,
    required this.status,
  });
}

class PayGroupSummary {
  final String id;
  final String name;
  final String frequency;
  final int employeeCount;
  final List<PayrollPeriod> periods;

  const PayGroupSummary({
    required this.id,
    required this.name,
    required this.frequency,
    required this.employeeCount,
    required this.periods,
  });
}

class PayrollConfigurationSnapshot {
  final List<SalaryComponent> components;
  final List<SalaryStructureSummary> structures;
  final List<StatutoryVersionSummary> statutoryVersions;
  final List<PayGroupSummary> payGroups;

  const PayrollConfigurationSnapshot({
    required this.components,
    required this.structures,
    required this.statutoryVersions,
    required this.payGroups,
  });
}
