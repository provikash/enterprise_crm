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

  /// Assembles an [AppConfig] derived from build-time `--dart-define` parameters
  /// or falls back to standard development defaults.
  factory AppConfig.fromEnvironment() {
    const modeStr = String.fromEnvironment('CRM_DATA_SOURCE_MODE', defaultValue: 'mock');
    const apiUrlStr = String.fromEnvironment(
      'CRM_API_BASE_URL',
      defaultValue: 'https://api.crm.vinayenterprise.com',
    );
    return AppConfig(
      dataSourceMode: modeStr.toLowerCase() == 'api'
          ? DataSourceMode.api
          : DataSourceMode.mock,
      apiBaseUri: Uri.tryParse(apiUrlStr),
      enabledPayrollFeatures: development.enabledPayrollFeatures,
    );
  }
}
