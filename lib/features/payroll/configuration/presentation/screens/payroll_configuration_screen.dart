import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../auth/domain/entities/current_user.dart';
import '../../../../auth/domain/policies/crm_permissions.dart';
import '../../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../../shared/domain/payroll_access_policy.dart';
import '../../domain/payroll_configuration.dart';
import '../bloc/payroll_configuration_cubit.dart';

class PayrollConfigurationScreen extends StatelessWidget {
  final CurrentUser user;
  final int initialTab;

  const PayrollConfigurationScreen({
    super.key,
    required this.user,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!PayrollAccessPolicy.has(user, CrmPermissions.payrollConfigManage)) {
      return const AccessRestrictedScreen();
    }
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        key: const Key('payroll_configuration_screen'),
        appBar: AppBar(
          title: const Text('Payroll configuration'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Components'),
              Tab(text: 'Structures'),
              Tab(text: 'Statutory versions'),
              Tab(text: 'Pay groups'),
            ],
          ),
        ),
        body:
            BlocConsumer<PayrollConfigurationCubit, PayrollConfigurationState>(
              listener: (context, state) {
                if (state is PayrollConfigurationReady &&
                    state.message != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(state.message!)));
                }
              },
              builder: (context, state) => switch (state) {
                PayrollConfigurationLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                PayrollConfigurationFailure(:final message) => _FailureState(
                  message: message,
                ),
                PayrollConfigurationReady(:final data, :final submitting) =>
                  TabBarView(
                    children: [
                      _ComponentsTab(data: data, submitting: submitting),
                      _StructuresTab(items: data.structures),
                      _StatutoryTab(items: data.statutoryVersions),
                      _PayGroupsTab(items: data.payGroups),
                    ],
                  ),
              },
            ),
      ),
    );
  }
}

class _ComponentsTab extends StatelessWidget {
  final PayrollConfigurationSnapshot data;
  final bool submitting;

  const _ComponentsTab({required this.data, required this.submitting});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _SectionHeader(
        title: 'Salary components',
        subtitle: '${data.components.length} configured components',
        action: FilledButton.icon(
          onPressed: submitting ? null : () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New component'),
        ),
      ),
      const SizedBox(height: 12),
      for (final component in data.components)
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(component.code.characters.first)),
            title: Text(component.name),
            subtitle: Text(
              '${component.code} • ${_kindLabel(component.kind)} • Effective ${_date(component.effectiveFrom)}',
            ),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (component.taxable) const Chip(label: Text('Taxable')),
                Chip(label: Text(component.active ? 'Active' : 'Inactive')),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _showCreateDialog(BuildContext context) async {
    final cubit = context.read<PayrollConfigurationCubit>();
    final draft = await showDialog<_ComponentDraft>(
      context: context,
      builder: (_) => const _CreateComponentDialog(),
    );
    if (draft == null) return;
    await cubit.createComponent(
      code: draft.code,
      name: draft.name,
      kind: draft.kind,
      taxable: draft.taxable,
      effectiveFrom: DateTime(2026, 11),
    );
  }
}

class _ComponentDraft {
  final String code;
  final String name;
  final SalaryComponentKind kind;
  final bool taxable;

  const _ComponentDraft({
    required this.code,
    required this.name,
    required this.kind,
    required this.taxable,
  });
}

class _CreateComponentDialog extends StatefulWidget {
  const _CreateComponentDialog();

  @override
  State<_CreateComponentDialog> createState() => _CreateComponentDialogState();
}

class _CreateComponentDialogState extends State<_CreateComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  var _kind = SalaryComponentKind.earning;
  var _taxable = true;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New salary component'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Component code'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter a component code.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Enter a component name.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SalaryComponentKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final value in SalaryComponentKind.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(_kindLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Taxable'),
                value: _taxable,
                onChanged: (value) => setState(() => _taxable = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(
            context,
            _ComponentDraft(
              code: _codeController.text,
              name: _nameController.text,
              kind: _kind,
              taxable: _taxable,
            ),
          );
        },
        child: const Text('Create'),
      ),
    ],
  );
}

class _StructuresTab extends StatelessWidget {
  final List<SalaryStructureSummary> items;
  const _StructuresTab({required this.items});

  @override
  Widget build(BuildContext context) => _CardList(
    title: 'Salary structures',
    children: [
      for (final item in items)
        ListTile(
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(item.name),
          subtitle: Text(
            '${item.componentCount} components • ${item.assignedEmployees} employees',
          ),
          trailing: Chip(label: Text(item.active ? 'Active' : 'Draft')),
        ),
    ],
  );
}

class _StatutoryTab extends StatelessWidget {
  final List<StatutoryVersionSummary> items;
  const _StatutoryTab({required this.items});

  @override
  Widget build(BuildContext context) => _CardList(
    title: 'Effective-dated statutory configuration',
    children: [
      for (final item in items)
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(item.statute),
          subtitle: Text(
            '${item.versionLabel} • From ${_date(item.effectiveFrom)}',
          ),
          trailing: Chip(label: Text(item.current ? 'Current' : 'Historical')),
        ),
    ],
  );
}

class _PayGroupsTab extends StatelessWidget {
  final List<PayGroupSummary> items;
  const _PayGroupsTab({required this.items});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _SectionHeader(
        title: 'Pay groups and calendar',
        subtitle: 'Mock employee counts and upcoming periods',
      ),
      const SizedBox(height: 12),
      for (final group in items)
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(group.name),
            subtitle: Text(
              '${group.frequency} • ${group.employeeCount} employees',
            ),
            children: group.periods.isEmpty
                ? const [
                    ListTile(title: Text('No calendar periods configured.')),
                  ]
                : [
                    for (final period in group.periods)
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: Text(period.label),
                        subtitle: Text(
                          '${_date(period.startDate)} – ${_date(period.endDate)} • Pay ${_date(period.payDate)}',
                        ),
                        trailing: Chip(label: Text(period.status)),
                      ),
                  ],
          ),
        ),
    ],
  );
}

class _CardList extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CardList({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _SectionHeader(title: title, subtitle: '${children.length} mock records'),
      const SizedBox(height: 12),
      for (final child in children) Card(child: child),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(subtitle),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class _FailureState extends StatelessWidget {
  final String message;
  const _FailureState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 40),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => context.read<PayrollConfigurationCubit>().load(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}

String _date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

String _kindLabel(SalaryComponentKind value) => switch (value) {
  SalaryComponentKind.earning => 'Earning',
  SalaryComponentKind.deduction => 'Deduction',
  SalaryComponentKind.employerContribution => 'Employer contribution',
};
