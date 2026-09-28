import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../bloc/payroll_overview_cubit.dart';
import '../bloc/payroll_overview_state.dart';
import '../bloc/payroll_period_cubit.dart';
import '../bloc/payroll_period_state.dart';
import '../widgets/payroll_period_selector.dart';
import 'payroll_details_screen.dart';

/// Primary read-only screen for HR Payroll Overview.
///
/// Follows HR-6.5 architectural boundaries:
/// - Strictly read-only: displays stored domain fields without salary calculations.
/// - Protected by [HrAccessPolicy.canViewPayroll].
/// - Integrates HR-6.4 [PayrollPeriodSelector] for period switching.
/// - Resolves employee names through [EmployeeRepository].
/// - Responsive: renders card list on mobile (<600px) and structured DataTable on desktop (>=600px).
/// - Safe error handling without raw exception exposure.
class PayrollOverviewScreen extends StatefulWidget {
  final CurrentUser user;
  final PayrollRepository? payrollRepository;
  final EmployeeRepository? employeeRepository;
  final String? initialPeriodId;
  final PayrollOverviewCubit? overviewCubit;
  final PayrollPeriodCubit? periodCubit;
  final ValueChanged<String>? onRecordTap;

  const PayrollOverviewScreen({
    super.key,
    required this.user,
    this.payrollRepository,
    this.employeeRepository,
    this.initialPeriodId,
    this.overviewCubit,
    this.periodCubit,
    this.onRecordTap,
  });

  @override
  State<PayrollOverviewScreen> createState() => _PayrollOverviewScreenState();
}

class _PayrollOverviewScreenState extends State<PayrollOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final PayrollPeriodCubit _periodCubit;
  late final PayrollOverviewCubit _overviewCubit;
  late final EmployeeRepository _employeeRepository;
  bool _internalPeriodCubit = false;
  bool _internalOverviewCubit = false;

  @override
  void initState() {
    super.initState();
    if (HrAccessPolicy.canViewPayroll(widget.user)) {
      final payrollRepo =
          widget.payrollRepository ?? MockPayrollRepository();
      _employeeRepository =
          widget.employeeRepository ?? MockEmployeeRepository();

      if (widget.periodCubit != null) {
        _periodCubit = widget.periodCubit!;
      } else {
        _internalPeriodCubit = true;
        _periodCubit = PayrollPeriodCubit(
          repository: payrollRepo,
          initialPeriodId: widget.initialPeriodId,
        )..loadPeriods();
      }

      if (widget.overviewCubit != null) {
        _overviewCubit = widget.overviewCubit!;
      } else {
        _internalOverviewCubit = true;
        _overviewCubit = PayrollOverviewCubit(
          repository: payrollRepo,
          employeeRepository: _employeeRepository,
          initialPeriodId: widget.initialPeriodId,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_internalPeriodCubit) {
      _periodCubit.close();
    }
    if (_internalOverviewCubit) {
      _overviewCubit.close();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _overviewCubit.setSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _overviewCubit.clearSearch();
  }

  void _handleRefresh() {
    _periodCubit.reload();
    _overviewCubit.retry();
  }

  Future<void> _handleRecordTap(String recordId) async {
    widget.onRecordTap?.call(recordId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PayrollDetailsScreen(
          user: widget.user,
          recordId: recordId,
          payrollRepository: widget.payrollRepository,
          employeeRepository: _employeeRepository,
        ),
      ),
    );
    if (mounted) {
      _overviewCubit.retry();
    }
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

  String _resolveEmployeeName(
    String employeeId,
    Map<String, String> employeeNames,
  ) {
    return employeeNames[employeeId] ?? employeeId;
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(widget.user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider<PayrollPeriodCubit>.value(value: _periodCubit),
        BlocProvider<PayrollOverviewCubit>.value(value: _overviewCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PayrollPeriodCubit, PayrollPeriodState>(
            listenWhen: (prev, curr) =>
                prev.selectedPeriodId != curr.selectedPeriodId,
            listener: (context, state) {
              if (state.selectedPeriodId != null) {
                _overviewCubit.loadRecordsForPeriod(state.selectedPeriodId!);
              }
            },
          ),
        ],
        child: Scaffold(
          key: const Key('payroll_overview_scaffold'),
          appBar: AppBar(
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Payroll Overview'),
            ),
            actions: [
              IconButton(
                key: const Key('payroll_overview_refresh_button'),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _handleRefresh,
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;

              return Column(
                children: [
                  // Period Selector Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: PayrollPeriodSelector(
                      showHeader: true,
                      onPeriodChanged: (period) {
                        if (period != null) {
                          _overviewCubit.loadRecordsForPeriod(period.id);
                        }
                      },
                    ),
                  ),

                  // Search & Count Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    child: _buildSearchBar(theme, colorScheme),
                  ),

                  // Records Content Area
                  Expanded(
                    child: BlocBuilder<PayrollOverviewCubit, PayrollOverviewState>(
                      builder: (context, state) {
                        return _buildRecordsContent(
                          context,
                          state,
                          isDesktop,
                          theme,
                          colorScheme,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return BlocBuilder<PayrollOverviewCubit, PayrollOverviewState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('payroll_overview_search_field'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by employee name or ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        key: const Key('payroll_overview_search_clear_button'),
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    state.status == PayrollOverviewStatus.loaded
                        ? (state.searchQuery.isNotEmpty
                            ? 'Showing ${state.filteredCount} of ${state.recordCount} records'
                            : '${state.recordCount} records found')
                        : '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordsContent(
    BuildContext context,
    PayrollOverviewState state,
    bool isDesktop,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (state.status) {
      case PayrollOverviewStatus.initial:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 40,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Select a payroll period to view records.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );

      case PayrollOverviewStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(
              key: Key('payroll_overview_loading_indicator'),
              strokeWidth: 2.5,
            ),
          ),
        );

      case PayrollOverviewStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  key: const Key('payroll_overview_error_icon'),
                  color: colorScheme.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ??
                      'Failed to load payroll records for this period.',
                  key: const Key('payroll_overview_error_message'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('payroll_overview_retry_button'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  onPressed: () => _overviewCubit.retry(),
                ),
              ],
            ),
          ),
        );

      case PayrollOverviewStatus.loaded:
        if (state.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    key: const Key('payroll_overview_empty_icon'),
                    size: 44,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payroll records are available for this period.',
                    key: const Key('payroll_overview_empty_message'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (state.isSearchEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    key: const Key('payroll_overview_no_results_icon'),
                    size: 44,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No records match your search.',
                    key: const Key('payroll_overview_no_results_message'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key(
                      'payroll_overview_clear_search_empty_button',
                    ),
                    onPressed: _clearSearch,
                    child: const Text('Clear Search'),
                  ),
                ],
              ),
            ),
          );
        }

        final records = state.filteredRecords;

        if (isDesktop) {
          return _buildDesktopTable(context, records, state.employeeNames, theme, colorScheme);
        } else {
          return _buildMobileCardList(context, records, state.employeeNames, theme, colorScheme);
        }
    }
  }

  Widget _buildMobileCardList(
    BuildContext context,
    List<PayrollRecord> records,
    Map<String, String> employeeNames,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final employeeName = _resolveEmployeeName(record.employeeId, employeeNames);

        return Card(
          key: Key('payroll_record_card_${record.id}'),
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _handleRecordTap(record.id),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Record ID and Payment Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.id,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (record.paymentStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: record.paymentStatus == 'Paid'
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.paymentStatus!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: record.paymentStatus == 'Paid'
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Employee Row
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${record.employeeId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  const SizedBox(height: 10),

                  // Financials Row: Gross & Net Salary
                  Row(
                    children: [
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: Payment Date & Details chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Payment: ${record.formattedPaymentDate ?? '—'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<PayrollRecord> records,
    Map<String, String> employeeNames,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          columns: const [
            DataColumn(label: Text('Record ID')),
            DataColumn(label: Text('Employee')),
            DataColumn(label: Text('Gross Salary'), numeric: true),
            DataColumn(label: Text('Net Salary'), numeric: true),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Payment Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: records.map((record) {
            final employeeName =
                _resolveEmployeeName(record.employeeId, employeeNames);

            return DataRow(
              key: ValueKey('payroll_record_row_${record.id}'),
              cells: [
                DataCell(
                  Text(
                    record.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'ID: ${record.employeeId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    _formatCurrency(record.grossSalary, record.currency),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    _formatCurrency(record.netSalary, record.currency),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                DataCell(
                  record.paymentStatus != null
                      ? Chip(
                          label: Text(record.paymentStatus!),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: record.paymentStatus == 'Paid'
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          backgroundColor: record.paymentStatus == 'Paid'
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        )
                      : const Text('—'),
                ),
                DataCell(
                  Text(record.formattedPaymentDate ?? '—'),
                ),
                DataCell(
                  IconButton(
                    key: Key('payroll_record_action_${record.id}'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    tooltip: 'View Details',
                    onPressed: () => _handleRecordTap(record.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
