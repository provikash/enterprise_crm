import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../auth/domain/entities/current_user.dart';
import '../../../../auth/domain/policies/crm_permissions.dart';
import '../../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../../shared/domain/money.dart';
import '../../../shared/domain/payroll_access_policy.dart';
import '../../../shared/presentation/widgets/money_text.dart';
import '../../../presentation/widgets/payroll_shell.dart';
import '../../domain/payroll_operations.dart';
import '../bloc/payroll_operations_cubit.dart';

enum PayrollWorkspace {
  compensation('Employee compensation', Icons.badge_outlined),
  inputs('Payroll inputs', Icons.input_outlined),
  runs('Pay runs', Icons.playlist_add_check_outlined),
  payslips('Payslips', Icons.receipt_long_outlined),
  payments('Payments', Icons.account_balance_outlined),
  reports('Reports', Icons.assessment_outlined);

  final String label;
  final IconData icon;
  const PayrollWorkspace(this.label, this.icon);
}

class PayrollOperationsScreen extends StatelessWidget {
  final CurrentUser user;
  final PayrollWorkspace workspace;
  final AppConfig config;

  const PayrollOperationsScreen({
    super.key,
    required this.user,
    required this.workspace,
    this.config = AppConfig.development,
  });

  bool _allowed() => switch (workspace) {
    PayrollWorkspace.compensation => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollSalaryView,
    ),
    PayrollWorkspace.inputs => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollRunCreate,
    ),
    PayrollWorkspace.runs => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollRunView,
    ),
    PayrollWorkspace.payslips => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollPayslipViewAll,
    ),
    PayrollWorkspace.payments => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollPaymentRelease,
    ),
    PayrollWorkspace.reports => PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollReportsView,
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!_allowed()) return const AccessRestrictedScreen();
    return PayrollShell(
      user: user,
      config: config,
      selectedRoute: _routeFor(workspace),
      title: workspace.label,
      body: KeyedSubtree(
        key: Key('payroll_${workspace.name}_screen'),
        child: BlocConsumer<PayrollOperationsCubit, PayrollOperationsState>(
          listener: (context, state) {
            if (state case PayrollOperationsReady(
              :final message?,
              :final isError,
            )) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: isError
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                );
            }
          },
          builder: (context, state) => switch (state) {
            PayrollOperationsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            PayrollOperationsFailure(:final message) => _LoadFailure(message),
            PayrollOperationsReady(:final data, :final busy) => Stack(
              children: [
                switch (workspace) {
                  PayrollWorkspace.compensation => _CompensationView(
                    user: user,
                    data: data,
                  ),
                  PayrollWorkspace.inputs => _InputsView(data: data),
                  PayrollWorkspace.runs => _RunsView(user: user, data: data),
                  PayrollWorkspace.payslips => _PayslipsView(data: data),
                  PayrollWorkspace.payments => _PaymentsView(
                    user: user,
                    data: data,
                  ),
                  PayrollWorkspace.reports => _ReportsView(data: data),
                },
                if (busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x22000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }

  String _routeFor(PayrollWorkspace value) => switch (value) {
    PayrollWorkspace.compensation => '/payroll/compensation',
    PayrollWorkspace.inputs => '/payroll/inputs',
    PayrollWorkspace.runs => '/payroll/runs',
    PayrollWorkspace.payslips => '/payroll/payslips',
    PayrollWorkspace.payments => '/payroll/payments',
    PayrollWorkspace.reports => '/payroll/reports',
  };
}

class _CompensationView extends StatelessWidget {
  final CurrentUser user;
  final PayrollOperationsSnapshot data;
  const _CompensationView({required this.user, required this.data});

  @override
  Widget build(BuildContext context) {
    final canEdit = PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollSalaryEdit,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PageIntro(
          title: 'Employee compensation',
          subtitle: 'Salary assignments, bank verification and payroll holds.',
        ),
        for (final employee in data.employees)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(employee.employeeName[0])),
              title: Text('${employee.employeeName} · ${employee.employeeId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${employee.department} · ${employee.maskedBankAccount}',
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      Text('Basic ${employee.basicSalary.format()}'),
                      Text('Allowance ${employee.fixedAllowance.format()}'),
                      Text('Deduction ${employee.fixedDeduction.format()}'),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: canEdit
                  ? Wrap(
                      spacing: 4,
                      children: [
                        FilterChip(
                          label: Text(employee.onHold ? 'On hold' : 'Active'),
                          selected: employee.onHold,
                          onSelected: (value) => context
                              .read<PayrollOperationsCubit>()
                              .setHold(employee.employeeId, value),
                        ),
                        IconButton(
                          tooltip: 'Edit compensation',
                          onPressed: () => _editCompensation(context, employee),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _editCompensation(
    BuildContext context,
    EmployeeCompensation employee,
  ) async {
    final result = await showDialog<List<Money>>(
      context: context,
      builder: (_) => _CompensationDialog(employee: employee),
    );
    if (result == null || !context.mounted) return;
    await context.read<PayrollOperationsCubit>().updateCompensation(
      employeeId: employee.employeeId,
      basicSalary: result[0],
      fixedAllowance: result[1],
      fixedDeduction: result[2],
    );
  }
}

class _CompensationDialog extends StatefulWidget {
  final EmployeeCompensation employee;
  const _CompensationDialog({required this.employee});
  @override
  State<_CompensationDialog> createState() => _CompensationDialogState();
}

class _CompensationDialogState extends State<_CompensationDialog> {
  final _key = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers =
        [
              widget.employee.basicSalary,
              widget.employee.fixedAllowance,
              widget.employee.fixedDeduction,
            ]
            .map(
              (money) =>
                  TextEditingController(text: money.format(symbol: false)),
            )
            .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Edit ${widget.employee.employeeName}'),
    content: Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in [
            'Basic salary',
            'Fixed allowance',
            'Fixed deduction',
          ].indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _controllers[entry.$1],
                decoration: InputDecoration(labelText: entry.$2),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _moneyValidator,
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!(_key.currentState?.validate() ?? false)) return;
          Navigator.pop(
            context,
            _controllers.map((c) => Money.parse(c.text)).toList(),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _InputsView extends StatelessWidget {
  final PayrollOperationsSnapshot data;
  const _InputsView({required this.data});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _PageIntro(
        title: 'Variable payroll inputs',
        subtitle: 'Bonuses, overtime, reimbursements and deductions.',
        action: FilledButton.icon(
          onPressed: () => _addInput(context),
          icon: const Icon(Icons.add),
          label: const Text('Add input'),
        ),
      ),
      if (data.inputs.isEmpty)
        const _Empty('No payroll inputs have been added.'),
      for (final input in data.inputs)
        Card(
          child: ListTile(
            leading: Icon(
              input.kind.earning
                  ? Icons.add_circle_outline
                  : Icons.remove_circle_outline,
            ),
            title: Text('${input.kind.label} · ${input.employeeId}'),
            subtitle: Text(input.note.isEmpty ? 'No note' : input.note),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MoneyText(value: input.amount),
                IconButton(
                  tooltip: 'Remove input',
                  onPressed: () => context
                      .read<PayrollOperationsCubit>()
                      .deleteInput(input.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Future<void> _addInput(BuildContext context) async {
    final result = await showDialog<_InputDraft>(
      context: context,
      builder: (_) => _InputDialog(employees: data.employees),
    );
    if (result == null || !context.mounted) return;
    await context.read<PayrollOperationsCubit>().addInput(
      employeeId: result.employeeId,
      kind: result.kind,
      amount: result.amount,
      note: result.note,
    );
  }
}

class _InputDraft {
  final String employeeId;
  final PayrollInputKind kind;
  final Money amount;
  final String note;
  const _InputDraft(this.employeeId, this.kind, this.amount, this.note);
}

class _InputDialog extends StatefulWidget {
  final List<EmployeeCompensation> employees;
  const _InputDialog({required this.employees});
  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _employeeId = widget.employees.first.employeeId;
  var _kind = PayrollInputKind.bonus;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add payroll input'),
    content: Form(
      key: _key,
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: [
                for (final e in widget.employees)
                  DropdownMenuItem(
                    value: e.employeeId,
                    child: Text('${e.employeeName} · ${e.employeeId}'),
                  ),
              ],
              onChanged: (value) => setState(() => _employeeId = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PayrollInputKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Input type'),
              items: [
                for (final kind in PayrollInputKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.label)),
              ],
              onChanged: (value) => setState(() => _kind = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: _positiveMoneyValidator,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Reason or note'),
            ),
          ],
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
          if (!(_key.currentState?.validate() ?? false)) return;
          Navigator.pop(
            context,
            _InputDraft(
              _employeeId,
              _kind,
              Money.parse(_amount.text),
              _note.text.trim(),
            ),
          );
        },
        child: const Text('Add'),
      ),
    ],
  );
}

class _RunsView extends StatelessWidget {
  final CurrentUser user;
  final PayrollOperationsSnapshot data;
  const _RunsView({required this.user, required this.data});

  @override
  Widget build(BuildContext context) {
    final canCreate = PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollRunCreate,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PageIntro(
          title: 'Pay runs',
          subtitle: 'Calculate, review, approve and lock payroll periods.',
          action: canCreate
              ? FilledButton.icon(
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New pay run'),
                )
              : null,
        ),
        for (final run in data.runs) _RunCard(user: user, run: run),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final controller = TextEditingController(text: 'October 2026');
    final period = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create pay run'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Payroll period'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (period == null || !context.mounted) return;
    await context.read<PayrollOperationsCubit>().createRun(period, user.id);
  }
}

class _RunCard extends StatelessWidget {
  final CurrentUser user;
  final PayRun run;
  const _RunCard({required this.user, required this.run});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PayrollOperationsCubit>();
    final canCreate = PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollRunCreate,
    );
    final canApprove = PayrollAccessPolicy.canApproveRun(
      user,
      isPreparer: run.preparedBy == user.id,
    );
    final canLock = PayrollAccessPolicy.has(
      user,
      CrmPermissions.payrollRunLock,
    );
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.payments_outlined),
        title: Text(run.periodLabel),
        subtitle: Text(
          '${run.status.label} · Prepared by ${run.preparedBy} · ${run.lines.length} employees',
        ),
        trailing: Chip(label: Text(run.status.label)),
        children: [
          if (run.lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _Metric('Gross', run.gross),
                  _Metric('Deductions', run.deductions),
                  _Metric('Tax', run.tax),
                  _Metric('Net', run.net),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (canCreate && run.status == PayRunStatus.draft)
                FilledButton.tonal(
                  onPressed: () => cubit.calculate(run.id, user.id),
                  child: const Text('Calculate'),
                ),
              if (canCreate && run.status == PayRunStatus.calculated)
                FilledButton.tonal(
                  onPressed: () => cubit.submit(run.id, user.id),
                  child: const Text('Submit for review'),
                ),
              if (canApprove && run.status == PayRunStatus.underReview)
                FilledButton.tonal(
                  onPressed: () => cubit.approve(run.id, user.id),
                  child: const Text('Approve'),
                ),
              if (canLock && run.status == PayRunStatus.approved)
                FilledButton(
                  onPressed: () => cubit.lock(run.id, user.id),
                  child: const Text('Lock payroll'),
                ),
            ],
          ),
          if (run.auditTrail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit trail',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final entry in run.auditTrail) Text('• $entry'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayslipsView extends StatelessWidget {
  final PayrollOperationsSnapshot data;
  const _PayslipsView({required this.data});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _PageIntro(
        title: 'Payslips',
        subtitle: 'Payslips are generated when a pay run is locked.',
      ),
      if (data.payslips.isEmpty)
        const _Empty('No payslips yet. Approve and lock a pay run first.'),
      for (final payslip in data.payslips)
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(payslip.line.employeeName),
            subtitle: Text(
              '${payslip.periodLabel} · ${payslip.line.employeeId}',
            ),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MoneyText(value: payslip.line.net),
                IconButton(
                  tooltip: 'View payslip',
                  onPressed: () => _showPayslip(context, payslip),
                  icon: const Icon(Icons.visibility_outlined),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  void _showPayslip(BuildContext context, Payslip payslip) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${payslip.line.employeeName} · ${payslip.periodLabel}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmountRow('Gross earnings', payslip.line.gross),
          _AmountRow('Deductions', payslip.line.deductions),
          _AmountRow('Tax', payslip.line.tax),
          const Divider(),
          _AmountRow('Net pay', payslip.line.net, strong: true),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _PaymentsView extends StatelessWidget {
  final CurrentUser user;
  final PayrollOperationsSnapshot data;
  const _PaymentsView({required this.user, required this.data});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _PageIntro(
        title: 'Salary payments',
        subtitle: 'Release approved bank batches and track payment references.',
      ),
      if (data.payments.isEmpty)
        const _Empty('No payment batches. Lock an approved pay run first.'),
      for (final batch in data.payments)
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(batch.periodLabel),
            subtitle: Text(
              '${batch.employeeCount} employees · ${batch.status.label}${batch.reference == null ? '' : ' · ${batch.reference}'}',
            ),
            trailing: batch.status == PaymentBatchStatus.pendingApproval
                ? FilledButton(
                    onPressed: () => context
                        .read<PayrollOperationsCubit>()
                        .releasePayment(batch.id, user.id),
                    child: const Text('Release'),
                  )
                : MoneyText(value: batch.amount),
          ),
        ),
    ],
  );
}

class _ReportsView extends StatelessWidget {
  final PayrollOperationsSnapshot data;
  const _ReportsView({required this.data});
  @override
  Widget build(BuildContext context) {
    final paidRuns = data.runs
        .where((run) => run.status == PayRunStatus.paid)
        .toList();
    final totalPaid = Money(
      paidRuns.fold<int>(0, (sum, run) => sum + run.net.paise),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _PageIntro(
          title: 'Payroll reports',
          subtitle: 'Payroll register, variance and payment summaries.',
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ReportCard(
              'Employees',
              '${data.employees.length}',
              Icons.people_outline,
            ),
            _ReportCard(
              'Pay runs',
              '${data.runs.length}',
              Icons.playlist_add_check_outlined,
            ),
            _ReportCard(
              'Paid total',
              totalPaid.format(),
              Icons.payments_outlined,
            ),
            _ReportCard(
              'Payroll holds',
              '${data.employees.where((e) => e.onHold).length}',
              Icons.pause_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Payroll register',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        for (final run in data.runs)
          Card(
            child: ListTile(
              title: Text(run.periodLabel),
              subtitle: Text(
                '${run.status.label} · ${run.lines.length} employees',
              ),
              trailing: MoneyText(value: run.net),
            ),
          ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tax values in this mock workflow are illustrative. Production statutory calculations must be returned by the authoritative payroll backend.',
            ),
          ),
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const _PageIntro({required this.title, required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              Text(subtitle),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final Money value;
  const _Metric(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      MoneyText(
        value: value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _AmountRow extends StatelessWidget {
  final String label;
  final Money value;
  final bool strong;
  const _AmountRow(this.label, this.value, {this.strong = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: strong ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ),
        MoneyText(
          value: value,
          style: strong ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReportCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  final String message;
  const _LoadFailure(this.message);
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => context.read<PayrollOperationsCubit>().load(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}

String? _moneyValidator(String? value) {
  try {
    final money = Money.parse(value ?? '');
    return money.paise < 0 ? 'Enter a non-negative amount.' : null;
  } on FormatException catch (error) {
    return error.message.toString();
  }
}

String? _positiveMoneyValidator(String? value) {
  final validation = _moneyValidator(value);
  if (validation != null) return validation;
  return Money.parse(value!).paise <= 0
      ? 'Enter an amount greater than zero.'
      : null;
}
