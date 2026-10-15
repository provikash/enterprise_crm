import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../shared/domain/payroll_access_policy.dart';
import '../navigation/payroll_routes.dart';
import '../widgets/payroll_shell.dart';

class PayrollHomeScreen extends StatelessWidget {
  final CurrentUser user;
  final AppConfig config;

  const PayrollHomeScreen({
    super.key,
    required this.user,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isPayrollEnabled(PayrollFeature.foundations) ||
        !PayrollAccessPolicy.canEnter(user)) {
      return const AccessRestrictedScreen();
    }

    final destinations = <_PayrollDestination>[
      const _PayrollDestination('Overview', Icons.dashboard_outlined, true),
      _PayrollDestination(
        'Configuration',
        Icons.settings_outlined,
        config.isPayrollEnabled(PayrollFeature.configuration) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollConfigManage),
        route: PayrollRoutes.configuration,
      ),
      _PayrollDestination(
        'Employee compensation',
        Icons.badge_outlined,
        config.isPayrollEnabled(PayrollFeature.employeeCompensation) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollSalaryView),
        route: PayrollRoutes.compensation,
      ),
      _PayrollDestination(
        'Payroll inputs',
        Icons.input_outlined,
        config.isPayrollEnabled(PayrollFeature.inputs) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollRunCreate),
        route: PayrollRoutes.inputs,
      ),
      _PayrollDestination(
        'Pay runs',
        Icons.playlist_add_check_outlined,
        config.isPayrollEnabled(PayrollFeature.payRuns) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollRunView),
        route: PayrollRoutes.runs,
      ),
      _PayrollDestination(
        'Payslips',
        Icons.receipt_long_outlined,
        config.isPayrollEnabled(PayrollFeature.payslips) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollPayslipViewAll),
        route: PayrollRoutes.payslips,
      ),
      _PayrollDestination(
        'Payments',
        Icons.account_balance_outlined,
        config.isPayrollEnabled(PayrollFeature.payments) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollPaymentRelease),
        route: PayrollRoutes.payments,
      ),
      _PayrollDestination(
        'Reports',
        Icons.assessment_outlined,
        config.isPayrollEnabled(PayrollFeature.reports) &&
            PayrollAccessPolicy.has(user, CrmPermissions.payrollReportsView),
        route: PayrollRoutes.reports,
      ),
    ];

    return PayrollShell(
      user: user,
      config: config,
      selectedRoute: PayrollRoutes.home,
      title: 'Payroll',
      body: KeyedSubtree(
        key: const Key('payroll_home_screen'),
        child: _Overview(destinations: destinations),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final List<_PayrollDestination> destinations;
  const _Overview({required this.destinations});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Payroll workspace',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Secure payroll foundations are enabled. Additional modules appear as each release phase is activated.',
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final destination in destinations.skip(1))
            SizedBox(
              width: 260,
              child: Card(
                child: ListTile(
                  leading: Icon(destination.icon),
                  title: Text(destination.label),
                  subtitle: Text(
                    destination.enabled ? 'Available' : 'Not enabled',
                  ),
                  enabled: destination.enabled,
                  onTap: destination.enabled && destination.route != null
                      ? () => Navigator.of(
                          context,
                        ).pushReplacementNamed(destination.route!)
                      : null,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _PayrollDestination {
  final String label;
  final IconData icon;
  final bool enabled;
  final String? route;
  const _PayrollDestination(this.label, this.icon, this.enabled, {this.route});
}
