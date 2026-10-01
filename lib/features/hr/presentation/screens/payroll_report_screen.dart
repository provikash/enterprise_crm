import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_hr_report_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/payroll_report_row.dart';
import '../../domain/entities/payroll_report_summary.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../bloc/payroll_report_cubit.dart';
import '../bloc/payroll_report_state.dart';

/// Screen presenting the Payroll Summary Report.
///
/// Follows HR-8.6 requirements:
/// - Evaluates stored [PayrollRecord]s from [PayrollRepository].
/// - Displays only approved fields: record ID, period, employee, gross salary,
///   allowances, deductions, net salary, currency, payment status, payment date, source.
/// - Monetary integrity: preserves exact numerical values and null semantics.
/// - Multi-currency safety: aggregates strictly grouped by currency; zero cross-currency summation.
/// - Protected by [HrAccessPolicy.canViewPayroll].
class PayrollReportScreen extends StatelessWidget {
  final CurrentUser user;
  final HrReportRepository? reportRepository;
  final PayrollRepository? payrollRepository;
  final EmployeeRepository? employeeRepository;
  final PayrollReportCubit? cubit;

  const PayrollReportScreen({
    super.key,
    required this.user,
    this.reportRepository,
    this.payrollRepository,
    this.employeeRepository,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(user)) {
      return const AccessRestrictedScreen();
    }

    final effectivePayrollRepo = payrollRepository ?? MockPayrollRepository();
    final effectiveEmployeeRepo = employeeRepository ?? MockEmployeeRepository();
    final effectiveReportRepo = reportRepository ??
        MockHrReportRepository(
          employeeRepository: effectiveEmployeeRepo,
          payrollRepository: effectivePayrollRepo,
        );

    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _PayrollReportView(),
      );
    }

    return BlocProvider(
      create: (_) => PayrollReportCubit(
        reportRepository: effectiveReportRepo,
        payrollRepository: effectivePayrollRepo,
      ),
      child: const _PayrollReportView(),
    );
  }
}

class _PayrollReportView extends StatefulWidget {
  const _PayrollReportView();

  @override
  State<_PayrollReportView> createState() => _PayrollReportViewState();
}

class _PayrollReportViewState extends State<_PayrollReportView> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _statuses = [
    'All',
    'Paid',
    'Pending',
    'Processing',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<PayrollReportCubit>().setSearchTerm(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: const Key('payroll_report_scaffold'),
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Payroll Summary Report'),
        ),
        actions: [
          IconButton(
            key: const Key('payroll_report_refresh_button'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<PayrollReportCubit>().loadReport(),
          ),
        ],
      ),
      body: BlocConsumer<PayrollReportCubit, PayrollReportState>(
        listener: (context, state) {
          if (state.query.searchTerm != _searchController.text) {
            _searchController.text = state.query.searchTerm ?? '';
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterControls(context, state, colorScheme),
              if (state.summary != null)
                _buildSummaryCard(context, state.summary!, colorScheme),
              Expanded(
                child:
                    _buildBody(context, state, theme, colorScheme, isDesktop),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    PayrollReportState state,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<PayrollReportCubit>();
    final activeStatus = state.query.paymentStatus ?? 'All';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              key: const Key('payroll_report_search_input'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by employee or record ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          cubit.setSearchTerm('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),

            // Period Selector & Reset Filters Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  key: const Key('payroll_report_period_selector'),
                  value: state.query.payrollPeriodId ?? 'All',
                  isDense: true,
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Periods', style: TextStyle(fontSize: 13)),
                    ),
                    ...state.periods.map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    cubit.setPeriodFilter(val);
                  },
                ),
                if (state.query.hasActiveFilters)
                  TextButton.icon(
                    key: const Key('payroll_report_clear_filters_button'),
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Reset Filters',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchController.clear();
                      cubit.resetFilters();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Payment Status Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = activeStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      key: Key('payroll_report_status_chip_$status'),
                      label: Text(status, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) => cubit.setPaymentStatusFilter(status),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    PayrollReportSummary summary,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('payroll_report_summary_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payroll Records: ${summary.totalRecords}',
                  key: const Key('payroll_report_total_records'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (!summary.isMultiCurrency && summary.singleSummary != null) ...[
                  Text(
                    'Gross Total: ${summary.singleCurrency} ${summary.singleSummary!.totalGross.toStringAsFixed(2)}',
                    key: const Key('payroll_report_gross_total'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(
                    'Net Total: ${summary.singleCurrency} ${summary.singleSummary!.totalNet.toStringAsFixed(2)}',
                    key: const Key('payroll_report_net_total'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'Deductions: ${summary.singleCurrency} ${summary.singleSummary!.totalDeductions.toStringAsFixed(2)}',
                    key: const Key('payroll_report_deductions_total'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
            if (summary.isMultiCurrency) ...[
              const SizedBox(height: 6),
              const Text(
                'Multi-Currency Grouped Totals:',
                key: Key('payroll_report_multi_currency_heading'),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: summary.currencySummaries.values.map((cs) {
                  return Chip(
                    key: Key('payroll_report_currency_chip_${cs.currency}'),
                    label: Text(
                      '${cs.currency} (${cs.recordCount}): Gross ${cs.totalGross.toStringAsFixed(2)} | Net ${cs.totalNet.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PayrollReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('payroll_report_loading'),
        ),
      );
    }

    if (state.isFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            key: const Key('payroll_report_error_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    'Failed to generate Payroll Summary Report. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('payroll_report_retry_button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => context.read<PayrollReportCubit>().retry(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.result == null || state.result!.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            key: const Key('payroll_report_empty_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'No payroll records match the selected report criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (state.query.hasActiveFilters)
                OutlinedButton.icon(
                  key: const Key('payroll_report_reset_empty_button'),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    _searchController.clear();
                    context.read<PayrollReportCubit>().resetFilters();
                  },
                ),
            ],
          ),
        ),
      );
    }

    final rows = state.result!.rows;

    if (isDesktop) {
      return _buildDesktopTable(context, rows, state.query.sort);
    } else {
      return _buildMobileList(context, rows, colorScheme);
    }
  }

  Widget _buildMobileList(
    BuildContext context,
    List<PayrollReportRow> rows,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      key: const Key('payroll_report_mobile_list'),
      padding: const EdgeInsets.all(16.0),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return Card(
          key: ValueKey('payroll_mobile_card_${row.id}'),
          margin: const EdgeInsets.only(bottom: 10.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      row.employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    _buildStatusBadge(row.paymentStatus),
                  ],
                ),
                if (row.employeeCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Code: ${row.employeeCode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Period: ${row.periodName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row.source,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text('Gross: ${row.formattedGrossSalary}',
                        style: const TextStyle(fontSize: 12)),
                    Text('Net: ${row.formattedNetSalary}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text('Allowances: ${row.formattedAllowances}',
                        style: const TextStyle(fontSize: 11)),
                    Text('Deductions: ${row.formattedDeductions}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
                if (row.paymentDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Paid on: ${row.formattedPaymentDate}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<PayrollReportRow> rows,
    ReportSort? currentSort,
  ) {
    final cubit = context.read<PayrollReportCubit>();
    final sort = currentSort ?? const ReportSort(field: 'period');

    return SingleChildScrollView(
      key: const Key('payroll_report_desktop_table'),
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _getColumnIndex(sort.field),
          sortAscending: sort.direction.isAscending,
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 52,
          columns: [
            DataColumn(
              label: const Text('Period'),
              onSort: (_, ascending) {
                cubit.setSort(ReportSort(
                  field: 'period',
                  direction: ascending
                      ? ReportSortDirection.ascending
                      : ReportSortDirection.descending,
                ));
              },
            ),
            DataColumn(
              label: const Text('Employee'),
              onSort: (_, ascending) {
                cubit.setSort(ReportSort(
                  field: 'employee',
                  direction: ascending
                      ? ReportSortDirection.ascending
                      : ReportSortDirection.descending,
                ));
              },
            ),
            DataColumn(
              label: const Text('Gross Salary'),
              numeric: true,
              onSort: (_, ascending) {
                cubit.setSort(ReportSort(
                  field: 'grossSalary',
                  direction: ascending
                      ? ReportSortDirection.ascending
                      : ReportSortDirection.descending,
                ));
              },
            ),
            const DataColumn(
              label: Text('Allowances'),
              numeric: true,
            ),
            const DataColumn(
              label: Text('Deductions'),
              numeric: true,
            ),
            DataColumn(
              label: const Text('Net Salary'),
              numeric: true,
              onSort: (_, ascending) {
                cubit.setSort(ReportSort(
                  field: 'netSalary',
                  direction: ascending
                      ? ReportSortDirection.ascending
                      : ReportSortDirection.descending,
                ));
              },
            ),
            const DataColumn(
              label: Text('Status'),
            ),
            DataColumn(
              label: const Text('Payment Date'),
              onSort: (_, ascending) {
                cubit.setSort(ReportSort(
                  field: 'paymentDate',
                  direction: ascending
                      ? ReportSortDirection.ascending
                      : ReportSortDirection.descending,
                ));
              },
            ),
            const DataColumn(
              label: Text('Source'),
            ),
          ],
          rows: rows.map((row) {
            return DataRow(
              key: ValueKey('payroll_row_${row.id}'),
              cells: [
                DataCell(Text(row.periodName)),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (row.employeeCode != null)
                        Text(
                          row.employeeCode!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                DataCell(Text(row.formattedGrossSalary)),
                DataCell(Text(row.formattedAllowances)),
                DataCell(Text(row.formattedDeductions)),
                DataCell(
                  Text(
                    row.formattedNetSalary,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(_buildStatusBadge(row.paymentStatus)),
                DataCell(Text(row.formattedPaymentDate)),
                DataCell(
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(row.source, style: const TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  int? _getColumnIndex(String field) {
    switch (field) {
      case 'period':
        return 0;
      case 'employee':
        return 1;
      case 'grossSalary':
        return 2;
      case 'netSalary':
        return 5;
      case 'paymentDate':
        return 7;
      default:
        return null;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.trim().toLowerCase()) {
      case 'paid':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case 'pending':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        break;
      case 'processing':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
