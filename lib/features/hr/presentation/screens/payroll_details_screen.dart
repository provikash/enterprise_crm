import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../bloc/payroll_details_cubit.dart';
import '../bloc/payroll_details_state.dart';

/// Screen displaying the complete read-only details of an individual Payroll Record.
///
/// Follows HR-6.6 architectural boundaries:
/// - Stably requests the record by unique [recordId].
/// - Displays authoritative stored values only without client-side salary arithmetic.
/// - Resolves associated [PayrollPeriod] and [Employee] references.
/// - Strictly protected via [HrAccessPolicy.canViewPayroll].
/// - Responsive across mobile (<600px), tablet, and desktop viewports.
/// - Safe error and not-found state handling.
class PayrollDetailsScreen extends StatefulWidget {
  final CurrentUser user;
  final String recordId;
  final PayrollRepository? payrollRepository;
  final EmployeeRepository? employeeRepository;
  final PayrollDetailsCubit? cubit;

  const PayrollDetailsScreen({
    super.key,
    required this.user,
    required this.recordId,
    this.payrollRepository,
    this.employeeRepository,
    this.cubit,
  });

  @override
  State<PayrollDetailsScreen> createState() => _PayrollDetailsScreenState();
}

class _PayrollDetailsScreenState extends State<PayrollDetailsScreen> {
  late final PayrollDetailsCubit _cubit;
  bool _internalCubit = false;

  @override
  void initState() {
    super.initState();
    if (HrAccessPolicy.canViewPayroll(widget.user)) {
      if (widget.cubit != null) {
        _cubit = widget.cubit!;
      } else {
        _internalCubit = true;
        final payrollRepo =
            widget.payrollRepository ?? MockPayrollRepository();
        final employeeRepo =
            widget.employeeRepository ?? MockEmployeeRepository();

        _cubit = PayrollDetailsCubit(
          repository: payrollRepo,
          employeeRepository: employeeRepo,
          initialRecordId: widget.recordId,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(widget.user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider<PayrollDetailsCubit>.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('payroll_details_scaffold'),
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Payroll Details'),
          ),
          actions: [
            IconButton(
              key: const Key('payroll_details_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _cubit.retry(),
            ),
          ],
        ),
        body: BlocBuilder<PayrollDetailsCubit, PayrollDetailsState>(
          builder: (context, state) {
            switch (state.status) {
              case PayrollDetailsStatus.initial:
              case PayrollDetailsStatus.loading:
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      key: Key('payroll_details_loading_indicator'),
                      strokeWidth: 2.5,
                    ),
                  ),
                );

              case PayrollDetailsStatus.failure:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          key: const Key('payroll_details_error_icon'),
                          color: colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.errorMessage ??
                              'Failed to load payroll record details.',
                          key: const Key('payroll_details_error_message'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('payroll_details_retry_button'),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                          onPressed: () => _cubit.retry(),
                        ),
                      ],
                    ),
                  ),
                );

              case PayrollDetailsStatus.notFound:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          key: const Key('payroll_details_not_found_icon'),
                          size: 44,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payroll record was not found.',
                          key: const Key('payroll_details_not_found_message'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The requested record ID (${state.recordId ?? widget.recordId}) does not exist or may have been removed.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('payroll_details_not_found_back_button'),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Back to Overview'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                );

              case PayrollDetailsStatus.loaded:
                final record = state.record!;
                return _buildDetailsContent(
                  context,
                  record,
                  state.period,
                  state.employee,
                  theme,
                  colorScheme,
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    PayrollRecord record,
    PayrollPeriod? period,
    Employee? employee,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Record Overview Card
              _buildOverviewCard(record, theme, colorScheme),
              const SizedBox(height: 14),

              // 2. Employee Information Card
              _buildEmployeeCard(record, employee, theme, colorScheme),
              const SizedBox(height: 14),

              // 3. Payroll Period Card
              _buildPeriodCard(record, period, theme, colorScheme),
              const SizedBox(height: 14),

              // 4. Stored Compensation Card
              _buildFinancialsCard(record, theme, colorScheme),
              const SizedBox(height: 14),

              // 5. Additional Metadata Card
              _buildMetadataCard(record, theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    PayrollRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_details_overview_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Record Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.paymentStatus != null)
                  Container(
                    key: const Key('payroll_details_payment_status'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: record.paymentStatus == 'Paid'
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.paymentStatus!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: record.paymentStatus == 'Paid'
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Record ID',
              record.id,
              key: const Key('payroll_details_record_id'),
              theme: theme,
              colorScheme: colorScheme,
              isMonospace: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Currency',
              record.currency ?? '—',
              key: const Key('payroll_details_currency'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Payment Date',
              record.formattedPaymentDate ?? '—',
              key: const Key('payroll_details_payment_date'),
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
    PayrollRecord record,
    Employee? employee,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_details_employee_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Employee Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Employee Name',
              employee?.fullName ?? 'Unknown',
              key: const Key('payroll_details_employee_name'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Employee ID',
              record.employeeId,
              key: const Key('payroll_details_employee_id'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            if (employee?.employeeCode != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Employee Code',
                employee!.employeeCode!,
                key: const Key('payroll_details_employee_code'),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
            if (employee?.department != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Department',
                employee!.department!,
                key: const Key('payroll_details_employee_department'),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
            if (employee?.designation != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Designation',
                employee!.designation!,
                key: const Key('payroll_details_employee_designation'),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(
    PayrollRecord record,
    PayrollPeriod? period,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_details_period_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payroll Period',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Period Name',
              period?.name ?? record.payrollPeriodId,
              key: const Key('payroll_details_period_name'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Period ID',
              record.payrollPeriodId,
              key: const Key('payroll_details_period_id'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Date Range',
              period?.formattedPeriod ?? '—',
              key: const Key('payroll_details_period_range'),
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(
    PayrollRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_details_financials_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stored Compensation Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Authoritative stored domain amounts. No client-side calculations applied.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Gross Salary',
              _formatCurrency(record.grossSalary, record.currency),
              key: const Key('payroll_details_gross_salary'),
              theme: theme,
              colorScheme: colorScheme,
              isHighlight: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Allowances',
              _formatCurrency(record.totalAllowances, record.currency),
              key: const Key('payroll_details_allowances'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Total Deductions',
              _formatCurrency(record.totalDeductions, record.currency),
              key: const Key('payroll_details_deductions'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Net Payable Salary',
              _formatCurrency(record.netSalary, record.currency),
              key: const Key('payroll_details_net_salary'),
              theme: theme,
              colorScheme: colorScheme,
              isHighlight: true,
              highlightColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(
    PayrollRecord record,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_details_metadata_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Administrative Remarks & Audit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetailRow(
              'Remarks',
              record.remarks ?? '—',
              key: const Key('payroll_details_remarks'),
              theme: theme,
              colorScheme: colorScheme,
            ),
            if (record.createdAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Created At',
                record.createdAt!.toIso8601String(),
                key: const Key('payroll_details_created_at'),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
            if (record.updatedAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Updated At',
                record.updatedAt!.toIso8601String(),
                key: const Key('payroll_details_updated_at'),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Key? key,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isMonospace = false,
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            key: key,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: highlightColor ?? colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
