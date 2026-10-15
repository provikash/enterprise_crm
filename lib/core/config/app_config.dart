enum DataSourceMode { mock, api }

enum PayrollFeature {
  foundations,
  configuration,
  employeeCompensation,
  inputs,
  payRuns,
  payslips,
  payments,
  fullAndFinal,
  tax,
  compliance,
  accounting,
  reports,
  analytics,
}

class AppConfig {
  final DataSourceMode dataSourceMode;
  final Uri? apiBaseUri;
  final String companyTimeZone;
  final Set<PayrollFeature> enabledPayrollFeatures;

  const AppConfig({
    this.dataSourceMode = DataSourceMode.mock,
    this.apiBaseUri,
    this.companyTimeZone = 'Asia/Colombo',
    this.enabledPayrollFeatures = const {PayrollFeature.foundations},
  });

  bool isPayrollEnabled(PayrollFeature feature) =>
      enabledPayrollFeatures.contains(feature);

  static const development = AppConfig(
    enabledPayrollFeatures: {
      PayrollFeature.foundations,
      PayrollFeature.configuration,
      PayrollFeature.employeeCompensation,
      PayrollFeature.inputs,
      PayrollFeature.payRuns,
      PayrollFeature.payslips,
      PayrollFeature.payments,
      PayrollFeature.tax,
      PayrollFeature.compliance,
      PayrollFeature.reports,
      PayrollFeature.analytics,
    },
  );
}
