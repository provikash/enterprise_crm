import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../shared/domain/payroll_access_policy.dart';

class PayrollShell extends StatelessWidget {
  static const double desktopNavigationBreakpoint = 700;

  final CurrentUser user;
  final AppConfig config;
  final String selectedRoute;
  final String title;
  final Widget body;
  final PreferredSizeWidget? appBarBottom;
  final Widget? floatingActionButton;

  const PayrollShell({
    super.key,
    required this.user,
    required this.config,
    required this.selectedRoute,
    required this.title,
    required this.body,
    this.appBarBottom,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(user, config);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Payroll is often displayed inside a wider CRM workspace. Keep the
        // module navigation fixed at desktop and tablet landscape widths so it
        // does not unexpectedly collapse after navigating to another page.
        final wide = constraints.maxWidth >= desktopNavigationBreakpoint;
        return Scaffold(
          key: const Key('payroll_shell'),
          appBar: AppBar(title: Text(title), bottom: appBarBottom),
          drawer: wide
              ? null
              : Drawer(
                  child: _PayrollNavigation(
                    destinations: destinations,
                    selectedRoute: selectedRoute,
                    drawerMode: true,
                  ),
                ),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              if (wide)
                Container(
                  width: constraints.maxWidth >= 1100 ? 270 : 240,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: _PayrollNavigation(
                      destinations: destinations,
                      selectedRoute: selectedRoute,
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class _PayrollNavigation extends StatelessWidget {
  final List<_PayrollShellDestination> destinations;
  final String selectedRoute;
  final bool drawerMode;

  const _PayrollNavigation({
    required this.destinations,
    required this.selectedRoute,
    this.drawerMode = false,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const ListTile(
          leading: Icon(Icons.payments_outlined),
          title: Text(
            'Payroll',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Enterprise workspace'),
        ),
        const Divider(),
        for (final destination in destinations)
          ListTile(
            key: Key('payroll_nav_${destination.key}'),
            leading: Icon(destination.icon),
            title: Text(destination.label),
            selected:
                selectedRoute == destination.route ||
                (destination.route == '/payroll/config/components' &&
                    selectedRoute.startsWith('/payroll/config/')),
            enabled: destination.enabled,
            subtitle: destination.enabled
                ? null
                : const Text('Permission required'),
            onTap: destination.enabled
                ? () {
                    final navigator = Navigator.of(context);
                    if (drawerMode) navigator.pop();
                    if (selectedRoute == destination.route ||
                        (destination.route == '/payroll/config/components' &&
                            selectedRoute.startsWith('/payroll/config/'))) {
                      return;
                    }
                    navigator.pushReplacementNamed(destination.route);
                  }
                : null,
          ),
      ],
    ),
  );
}

List<_PayrollShellDestination> _destinations(
  CurrentUser user,
  AppConfig config,
) => [
  const _PayrollShellDestination(
    key: 'overview',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    route: '/payroll',
    enabled: true,
  ),
  _PayrollShellDestination(
    key: 'configuration',
    label: 'Configuration',
    icon: Icons.settings_outlined,
    route: '/payroll/config/components',
    enabled:
        config.isPayrollEnabled(PayrollFeature.configuration) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollConfigManage),
  ),
  _PayrollShellDestination(
    key: 'compensation',
    label: 'Employee compensation',
    icon: Icons.badge_outlined,
    route: '/payroll/compensation',
    enabled:
        config.isPayrollEnabled(PayrollFeature.employeeCompensation) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollSalaryView),
  ),
  _PayrollShellDestination(
    key: 'inputs',
    label: 'Payroll inputs',
    icon: Icons.input_outlined,
    route: '/payroll/inputs',
    enabled:
        config.isPayrollEnabled(PayrollFeature.inputs) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollRunCreate),
  ),
  _PayrollShellDestination(
    key: 'runs',
    label: 'Pay runs',
    icon: Icons.playlist_add_check_outlined,
    route: '/payroll/runs',
    enabled:
        config.isPayrollEnabled(PayrollFeature.payRuns) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollRunView),
  ),
  _PayrollShellDestination(
    key: 'payslips',
    label: 'Payslips',
    icon: Icons.receipt_long_outlined,
    route: '/payroll/payslips',
    enabled:
        config.isPayrollEnabled(PayrollFeature.payslips) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollPayslipViewAll),
  ),
  _PayrollShellDestination(
    key: 'payments',
    label: 'Payments',
    icon: Icons.account_balance_outlined,
    route: '/payroll/payments',
    enabled:
        config.isPayrollEnabled(PayrollFeature.payments) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollPaymentRelease),
  ),
  _PayrollShellDestination(
    key: 'reports',
    label: 'Reports',
    icon: Icons.assessment_outlined,
    route: '/payroll/reports',
    enabled:
        config.isPayrollEnabled(PayrollFeature.reports) &&
        PayrollAccessPolicy.has(user, CrmPermissions.payrollReportsView),
  ),
];

class _PayrollShellDestination {
  final String key;
  final String label;
  final IconData icon;
  final String route;
  final bool enabled;

  const _PayrollShellDestination({
    required this.key,
    required this.label,
    required this.icon,
    required this.route,
    required this.enabled,
  });
}
