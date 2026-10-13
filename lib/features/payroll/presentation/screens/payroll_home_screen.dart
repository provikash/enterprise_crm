import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../shared/domain/payroll_access_policy.dart';
import '../navigation/payroll_routes.dart';

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
        config.isPayrollEnabled(PayrollFeature.employeeCompensation),
      ),
      _PayrollDestination(
        'Payroll inputs',
        Icons.input_outlined,
        config.isPayrollEnabled(PayrollFeature.inputs),
      ),
      _PayrollDestination(
        'Pay runs',
        Icons.playlist_add_check_outlined,
        config.isPayrollEnabled(PayrollFeature.payRuns),
      ),
      _PayrollDestination(
        'Reports',
        Icons.assessment_outlined,
        config.isPayrollEnabled(PayrollFeature.reports),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = _Overview(destinations: destinations);
        return Scaffold(
          key: const Key('payroll_home_screen'),
          appBar: AppBar(title: const Text('Payroll')),
          drawer: wide
              ? null
              : Drawer(child: _Navigation(destinations: destinations)),
          body: Row(
            children: [
              if (wide)
                SizedBox(
                  width: 260,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: _Navigation(destinations: destinations),
                  ),
                ),
              Expanded(child: content),
            ],
          ),
          floatingActionButton:
              kDebugMode &&
                  config.isPayrollEnabled(PayrollFeature.widgetGallery)
              ? FloatingActionButton.extended(
                  tooltip: 'Open Payroll widget gallery',
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/payroll/gallery'),
                  icon: const Icon(Icons.widgets_outlined),
                  label: const Text('Widget gallery'),
                )
              : null,
        );
      },
    );
  }
}

class _Navigation extends StatelessWidget {
  final List<_PayrollDestination> destinations;
  const _Navigation({required this.destinations});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Payroll', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final destination in destinations)
          ListTile(
            leading: Icon(destination.icon),
            title: Text(destination.label),
            enabled: destination.enabled,
            selected: destination.label == 'Overview',
            subtitle: destination.enabled
                ? null
                : const Text('Coming in a later phase'),
            onTap: destination.enabled && destination.route != null
                ? () => Navigator.of(context).pushNamed(destination.route!)
                : null,
          ),
      ],
    ),
  );
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
                      ? () =>
                            Navigator.of(context).pushNamed(destination.route!)
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
