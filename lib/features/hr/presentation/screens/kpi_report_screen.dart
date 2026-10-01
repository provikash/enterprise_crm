import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_kpi_repository.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/kpi_report_row.dart';
import '../../domain/entities/kpi_report_summary.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../bloc/kpi_report_cubit.dart';
import '../bloc/kpi_report_state.dart';

/// Screen presenting the KPI Performance Report.
///
/// Follows HR-8.5 requirements:
/// - Evaluates quantitative targets, actual values, and assessor scores from [EmployeeKpiRepository].
/// - Displays only approved fields: period, employee, metric, target, actual, score, remarks.
/// - Strict score integrity: stored scores only; zero re-computation or score fabrication.
/// - Strict aggregation safety: zero cross-metric averaging or leaderboard ranking.
/// - Displays approved summary counts only: Total Records, Scored, Unscored, and metric-specific sums.
/// - Protected by [HrAccessPolicy.canViewHrRecords].
class KpiReportScreen extends StatelessWidget {
  final CurrentUser user;
  final HrReportRepository? reportRepository;
  final EmployeeKpiRepository? kpiRepository;
  final EmployeeRepository? employeeRepository;
  final KpiReportCubit? cubit;

  const KpiReportScreen({
    super.key,
    required this.user,
    this.reportRepository,
    this.kpiRepository,
    this.employeeRepository,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewHrRecords(user)) {
      return const AccessRestrictedScreen();
    }

    final effectiveReportRepo = reportRepository ??
        MockHrReportRepository(
          employeeRepository: employeeRepository ?? MockEmployeeRepository(),
          kpiRepository: kpiRepository ?? MockEmployeeKpiRepository(),
        );

    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _KpiReportView(),
      );
    }

    return BlocProvider(
      create: (_) => KpiReportCubit(
        repository: effectiveReportRepo,
      ),
      child: const _KpiReportView(),
    );
  }
}

class _KpiReportView extends StatefulWidget {
  const _KpiReportView();

  @override
  State<_KpiReportView> createState() => _KpiReportViewState();
}

class _KpiReportViewState extends State<_KpiReportView> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _metrics = [
    'All',
    'Employee Retention Rate',
    'Time to Hire (Days)',
    'Inventory Accuracy',
    'Order Dispatch Lead Time (Hours)',
    'Quarterly Sales Revenue (\$k)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<KpiReportCubit>().setSearchTerm(query);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<KpiReportCubit>();
    final currentRange = cubit.state.query.dateRange;

    final initialDateRange = currentRange != null
        ? DateTimeRange(
            start: currentRange.start,
            end: currentRange.end,
          )
        : DateTimeRange(
            start: DateTime.utc(2026, 7, 1),
            end: DateTime.utc(2026, 9, 30),
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
    );

    if (picked != null && mounted) {
      cubit.setDateRangeFilter(
        ReportDateRange(
          start: picked.start,
          end: picked.end,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      key: const Key('kpi_report_scaffold'),
      appBar: AppBar(
        title: const Text('KPI Performance Report'),
        actions: [
          IconButton(
            key: const Key('kpi_report_refresh_button'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<KpiReportCubit>().loadReport(forceRefresh: true),
          ),
        ],
      ),
      body: BlocConsumer<KpiReportCubit, KpiReportState>(
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
                child: _buildBody(context, state, theme, colorScheme, isDesktop),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterControls(
    BuildContext context,
    KpiReportState state,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<KpiReportCubit>();
    final activeMetric = state.query.metricName ?? 'All';

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
              key: const Key('kpi_report_search_input'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by employee or metric name...',
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

            // Date Range & Reset Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('kpi_report_date_range_button'),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    state.query.dateRange != null
                        ? state.query.dateRange!.formattedLabel
                        : 'Filter Period',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _pickDateRange(context),
                ),
                if (state.query.dateRange != null)
                  IconButton(
                    key: const Key('kpi_report_clear_date_range_button'),
                    tooltip: 'Clear Period Filter',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => cubit.setDateRangeFilter(null),
                  ),
                if (state.query.hasActiveFilters)
                  TextButton.icon(
                    key: const Key('kpi_report_clear_filters_button'),
                    icon: const Icon(Icons.filter_alt_off, size: 16),
                    label: const Text('Reset Filters',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _searchController.clear();
                      cubit.clearFilters();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Metric Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _metrics.map((metric) {
                  final isSelected = activeMetric == metric;
                  final keyName = metric.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      key: Key('kpi_report_metric_$keyName'),
                      label: Text(metric),
                      selected: isSelected,
                      onSelected: (_) => cubit.setMetricFilter(metric),
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
    KpiReportSummary summary,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('kpi_report_summary_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Total KPI Records: ${summary.totalRecords}',
              key: const Key('kpi_report_total_count'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Scored: ${summary.scoredRecords}',
              key: const Key('kpi_report_scored_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              'Unscored: ${summary.unscoredRecords}',
              key: const Key('kpi_report_unscored_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
            if (summary.singleMetricName != null) ...[
              Text(
                'Target: ${summary.totalTargetForMetric != null ? KpiReportRow.formatNumber(summary.totalTargetForMetric!) : '—'}',
                key: const Key('kpi_report_metric_target'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              Text(
                'Actual: ${summary.totalActualForMetric != null ? KpiReportRow.formatNumber(summary.totalActualForMetric!) : '—'}',
                key: const Key('kpi_report_metric_actual'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    KpiReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('kpi_report_loading'),
        ),
      );
    }

    if (state.isFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            key: const Key('kpi_report_error_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    'Failed to generate KPI Performance Report. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('kpi_report_retry_button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => context.read<KpiReportCubit>().retry(),
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
            key: const Key('kpi_report_empty_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.track_changes_outlined,
                  size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'No KPI records match the selected report criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (state.query.hasActiveFilters)
                OutlinedButton.icon(
                  key: const Key('kpi_report_reset_empty_button'),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    _searchController.clear();
                    context.read<KpiReportCubit>().clearFilters();
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
    List<KpiReportRow> rows,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      key: const Key('kpi_report_mobile_list'),
      padding: const EdgeInsets.all(16.0),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return Card(
          key: ValueKey('kpi_mobile_card_${row.kpiId}'),
          margin: const EdgeInsets.only(bottom: 10.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        row.metricName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (row.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Score: ${row.formattedScore}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${row.employeeName} (${row.employeeCode ?? row.employeeId})',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.formattedPeriod,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Target: ${row.formattedTarget}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Actual: ${row.formattedActual}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                if (row.remarks != null && row.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remarks: ${row.remarks}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    List<KpiReportRow> rows,
    ReportSort? activeSort,
  ) {
    final cubit = context.read<KpiReportCubit>();

    void onSortCol(String field) {
      final currentField = activeSort?.field ?? 'period';
      final isDesc = activeSort?.direction.isDescending ?? true;
      final newDir = currentField == field && isDesc
          ? ReportSortDirection.ascending
          : ReportSortDirection.descending;

      cubit.setSort(ReportSort(field: field, direction: newDir));
    }

    final sortColumnIndex = switch (activeSort?.field) {
      'period' => 0,
      'employeeName' => 1,
      'employeeCode' => 2,
      'metricName' => 3,
      'target' => 4,
      'actual' => 5,
      'score' => 6,
      _ => 0,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('kpi_report_table'),
          sortColumnIndex: sortColumnIndex,
          sortAscending: activeSort?.direction.isAscending ?? false,
          columns: [
            DataColumn(
              label: const Text('Period'),
              onSort: (columnIndex, ascending) => onSortCol('period'),
            ),
            DataColumn(
              label: const Text('Employee Name'),
              onSort: (columnIndex, ascending) => onSortCol('employeeName'),
            ),
            DataColumn(
              label: const Text('Employee Code'),
              onSort: (columnIndex, ascending) => onSortCol('employeeCode'),
            ),
            DataColumn(
              label: const Text('Metric Name'),
              onSort: (columnIndex, ascending) => onSortCol('metricName'),
            ),
            DataColumn(
              label: const Text('Target'),
              numeric: true,
              onSort: (columnIndex, ascending) => onSortCol('target'),
            ),
            DataColumn(
              label: const Text('Actual'),
              numeric: true,
              onSort: (columnIndex, ascending) => onSortCol('actual'),
            ),
            DataColumn(
              label: const Text('Score'),
              numeric: true,
              onSort: (columnIndex, ascending) => onSortCol('score'),
            ),
            const DataColumn(label: Text('Remarks')),
          ],
          rows: rows.map((row) {
            return DataRow(
              key: ValueKey('kpi_table_row_${row.kpiId}'),
              cells: [
                DataCell(Text(row.formattedPeriod)),
                DataCell(Text(row.employeeName)),
                DataCell(Text(row.employeeCode ?? '—')),
                DataCell(Text(row.metricName)),
                DataCell(Text(row.formattedTarget)),
                DataCell(Text(row.formattedActual)),
                DataCell(Text(row.formattedScore)),
                DataCell(Text(row.remarks ?? '—')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
