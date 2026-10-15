import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../domain/policies/hr_access_policy.dart';

/// Frontend workspace for enterprise attendance-adjacent contracts. It exposes
/// the intended UI without duplicating backend-owned calculations.
class WorkforceOperationsScreen extends StatelessWidget {
  final CurrentUser user;

  const WorkforceOperationsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final features = <_Operation>[
      _Operation(
        'Punch & geo-fence',
        Icons.location_on_outlined,
        'Employee check-in/out, server-time result, GPS permission state, biometric sync visibility.',
        const [
          '/attendance/check-in/',
          '/attendance/check-out/',
          '/attendance/today/',
        ],
        true,
      ),
      _Operation(
        'Shifts & roster',
        Icons.calendar_view_week_outlined,
        'Shift master, bulk assignment, night shifts, roster overrides, rest-gap and payroll-lock warnings.',
        const ['/shifts/', '/shift-assignments/bulk/', '/roster/'],
        HrAccessPolicy.canManageShifts(user),
      ),
      _Operation(
        'Policies & overtime',
        Icons.rule_outlined,
        'Effective-dated late, early-exit, half-day and overtime configuration with example previews.',
        const [
          '/attendance-policies/',
          '/overtime-requests/',
          '/attendance/recalculate/',
        ],
        HrAccessPolicy.canManageAttendancePolicies(user),
      ),
      _Operation(
        'Timesheets',
        Icons.grid_on_outlined,
        'Weekly project/task grid, draft totals, submit/reject lifecycle and utilization reporting.',
        const ['/timesheets/', '/projects/my/', '/reports/utilization/'],
        true,
      ),
      _Operation(
        'Regularization',
        Icons.edit_calendar_outlined,
        'Missed/wrong punch requests, reason and attachment, quota, approval timeline and locked-date checks.',
        const ['/regularizations/', '/regularizations/{id}/approve/'],
        true,
      ),
      _Operation(
        'Leave & holidays',
        Icons.beach_access_outlined,
        'Leave types, ledger balances, preview/apply workflow, encashment, team calendar and holiday calendars.',
        const [
          '/leave/preview/',
          '/leave/requests/',
          '/leave/balances/',
          '/holiday-calendars/',
        ],
        HrAccessPolicy.canManageLeave(user),
      ),
    ];

    return Scaffold(
      key: const Key('workforce_operations_scaffold'),
      appBar: AppBar(title: const Text('Workforce Operations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frontend contract workspace',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'These workflows are prepared for API integration. Server time, geo-fence decisions, daily calculations, policy outcomes, balance locking and payroll impact must come from the backend.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final feature in features)
                    SizedBox(
                      width: width,
                      child: _OperationCard(operation: feature),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Operation {
  final String title;
  final IconData icon;
  final String description;
  final List<String> endpoints;
  final bool canAct;
  const _Operation(
    this.title,
    this.icon,
    this.description,
    this.endpoints,
    this.canAct,
  );
}

class _OperationCard extends StatelessWidget {
  final _Operation operation;
  const _OperationCard({required this.operation});

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _OperationDetail(operation: operation),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(operation.icon),
                const Spacer(),
                Chip(
                  label: Text(operation.canAct ? 'Authorized' : 'Read only'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              operation.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(operation.description),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OperationDetail extends StatelessWidget {
  final _Operation operation;
  const _OperationDetail({required this.operation});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(operation.title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          operation.description,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        const _StatusRow(
          'Frontend screens',
          'Ready for API wiring',
          Icons.web_outlined,
        ),
        const _StatusRow(
          'Business calculation',
          'Backend authoritative',
          Icons.dns_outlined,
        ),
        const _StatusRow(
          'Audit and locking',
          'Backend authoritative',
          Icons.lock_outline,
        ),
        const SizedBox(height: 20),
        Text('API contracts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final endpoint in operation.endpoints)
                ListTile(
                  leading: const Icon(Icons.api_outlined),
                  title: Text(endpoint),
                  subtitle: const Text('Not connected in frontend-only mode'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: operation.canAct
              ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Backend API integration is required before this action can save.',
                    ),
                  ),
                )
              : null,
          icon: const Icon(Icons.add),
          label: Text('Create ${operation.title.toLowerCase()} item'),
        ),
      ],
    ),
  );
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatusRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
  );
}
