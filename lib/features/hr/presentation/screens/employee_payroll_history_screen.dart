import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_calculation_input.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../bloc/employee_payroll_history_cubit.dart';
import '../bloc/employee_payroll_history_state.dart';
import 'payroll_calculation_preview_screen.dart';
import 'payroll_details_screen.dart';

/// Screen presenting the dedicated Payroll History for an individual [Employee].
///
/// Follows HR-6.7 requirements:
/// - Stably queries records by [employee.id] (not CRM userId).
/// - Enforces strict payroll authorization via [HrAccessPolicy.canViewPayroll].
/// - Displays authoritative stored values only without client-side salary arithmetic.
/// - Resolves associated [PayrollPeriod] names for human-readable labels.
/// - Provides navigation to [PayrollDetailsScreen] for individual record drilldown.
/// - Handles loading, empty, error, and populated states safely.
class EmployeePayrollHistoryScreen extends StatefulWidget {
  final CurrentUser user;
  final Employee employee;
  final PayrollRepository? repository;
  final EmployeeRepository? employeeRepository;
  final EmployeePayrollHistoryCubit? cubit;

  const EmployeePayrollHistoryScreen({
    super.key,
    required this.user,
    required this.employee,
    this.repository,
    this.employeeRepository,
    this.cubit,
  });

  @override
  State<EmployeePayrollHistoryScreen> createState() =>
      _EmployeePayrollHistoryScreenState();
}

class _EmployeePayrollHistoryScreenState
    extends State<EmployeePayrollHistoryScreen> {
  late final EmployeePayrollHistoryCubit _cubit;
  bool _internalCubit = false;

  @override
  void initState() {
    super.initState();
    if (HrAccessPolicy.canViewPayroll(widget.user)) {
      if (widget.cubit != null) {
        _cubit = widget.cubit!;
      } else {
        _internalCubit = true;
        final payrollRepo = widget.repository ?? MockPayrollRepository();
        _cubit = EmployeePayrollHistoryCubit(
          repository: payrollRepo,
          initialEmployeeId: widget.employee.id,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant EmployeePayrollHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id != widget.employee.id &&
        HrAccessPolicy.canViewPayroll(widget.user)) {
      _cubit.loadHistory(widget.employee.id);
    }
  }

  @override
  void dispose() {
    if (_internalCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  String _formatCurrency(double? amount, String? currency) {
    if (amount == null) return '—';
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    final formatted = '$whole.${parts[1]}';
    if (currency != null && currency.isNotEmpty) {
      return '$currency $formatted';
    }
    return formatted;
  }

  Future<void> _navigateToDetails(String recordId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PayrollDetailsScreen(
          user: widget.user,
          recordId: recordId,
          payrollRepository: widget.repository,
          employeeRepository: widget.employeeRepository ?? MockEmployeeRepository(),
        ),
      ),
    );
    if (mounted) {
      _cubit.loadHistory(widget.employee.id);
    }
  }

  Future<void> _navigateToPreview(PayrollRecord record) async {
    final input = PayrollCalculationInput.fromPayrollRecord(record);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PayrollCalculationPreviewScreen(
          user: widget.user,
          input: input,
          employeeRepository:
              widget.employeeRepository ?? MockEmployeeRepository(),
          payrollRepository: widget.repository ?? MockPayrollRepository(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(widget.user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('employee_payroll_history_scaffold'),
        appBar: AppBar(
          title: Text('${widget.employee.fullName} — Payroll History'),
          leading: BackButton(
            key: const Key('employee_payroll_history_back_button'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              key: const Key('payroll_history_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _cubit.loadHistory(widget.employee.id),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: BlocBuilder<
              EmployeePayrollHistoryCubit,
              EmployeePayrollHistoryState
            >(
              builder: (context, state) {
                return Column(
                  children: [
                    // Employee Info Summary Header
                    _buildEmployeeHeader(context),
                    // State-driven body
                    Expanded(
                      child: _buildBody(context, state),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emp = widget.employee;

    return Card(
      key: const Key('employee_payroll_history_header_card'),
      margin: const EdgeInsets.all(16.0),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${emp.designation ?? 'Employee'} • ${emp.department ?? 'General'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    key: const Key('employee_payroll_history_id_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ID: ${emp.id}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmployeePayrollHistoryState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('payroll_history_loading_indicator'),
        ),
      );
    }

    if (state.isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
                key: Key('payroll_history_error_icon'),
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Failed to load payroll history.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('payroll_history_retry_button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _cubit.retry(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            key: const Key('payroll_history_empty_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Payroll Records Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No payroll records have been recorded for ${widget.employee.fullName} yet.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: const Key('payroll_history_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: state.records.length,
      itemBuilder: (context, index) {
        final record = state.records[index];
        final period = state.periods[record.payrollPeriodId];
        final periodName = period?.name ?? record.payrollPeriodId;

        return _buildPayrollRecordCard(context, record, periodName);
      },
    );
  }

  Widget _buildPayrollRecordCard(
    BuildContext context,
    PayrollRecord record,
    String periodName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid = (record.paymentStatus ?? '').toLowerCase() == 'paid';

    return Card(
      key: Key('payroll_history_card_${record.id}'),
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(record.id),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      periodName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (record.paymentStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        record.paymentStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPaid ? Colors.green[800] : Colors.orange[900],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Salary',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(record.netSalary, record.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gross Salary',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(record.grossSalary, record.currency),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('payroll_history_preview_button_${record.id}'),
                    icon: const Icon(Icons.calculate_outlined, size: 20),
                    tooltip: 'Preview Calculation',
                    onPressed: () => _navigateToPreview(record),
                  ),
                  IconButton(
                    key: Key('payroll_history_record_action_${record.id}'),
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    tooltip: 'View Details',
                    onPressed: () => _navigateToDetails(record.id),
                  ),
                ],
              ),
              if (record.paymentDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Disbursed: ${record.paymentDate!.year}-${record.paymentDate!.month.toString().padLeft(2, '0')}-${record.paymentDate!.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
