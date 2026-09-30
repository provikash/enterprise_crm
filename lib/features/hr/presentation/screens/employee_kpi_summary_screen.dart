import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../bloc/employee_kpi_summary_cubit.dart';
import '../bloc/employee_kpi_summary_state.dart';
import 'employee_kpi_list_screen.dart';

/// Screen displaying the KPI Performance Summary & Visualization dashboard.
///
/// Fully adheres to HR-5 frozen requirements:
/// - Reuses authoritative [EmployeeKpiRepository].
/// - Displays only approved counts and direct per-metric Target vs Actual values.
/// - Zero speculative formulas, achievement percentages, weighted scoring, or employee rankings.
/// - Supports period filtering and responsive layouts across mobile and desktop.
class EmployeeKpiSummaryScreen extends StatelessWidget {
  final CurrentUser user;
  final EmployeeKpiRepository? kpiRepository;
  final EmployeeRepository? employeeRepository;
  final EmployeeKpiSummaryCubit? summaryCubit;
  final DateTime? initialPeriodStart;
  final DateTime? initialPeriodEnd;
  final VoidCallback? onNavigateToKpiList;

  const EmployeeKpiSummaryScreen({
    super.key,
    required this.user,
    this.kpiRepository,
    this.employeeRepository,
    this.summaryCubit,
    this.initialPeriodStart,
    this.initialPeriodEnd,
    this.onNavigateToKpiList,
  });

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canAccessModule(user)) {
      return const AccessRestrictedScreen();
    }

    if (!user.isAdmin && !HrAccessPolicy.canViewHrRecords(user)) {
      return const AccessRestrictedScreen();
    }

    final effectiveKpiRepo =
        kpiRepository ??
        RepositoryProvider.of<EmployeeKpiRepository>(context, listen: false);

    if (summaryCubit != null) {
      return BlocProvider.value(
        value: summaryCubit!,
        child: _EmployeeKpiSummaryView(
          user: user,
          kpiRepository: effectiveKpiRepo,
          employeeRepository: employeeRepository ?? MockEmployeeRepository(),
          onNavigateToKpiList: onNavigateToKpiList,
        ),
      );
    }

    return BlocProvider(
      create: (_) => EmployeeKpiSummaryCubit(
        repository: effectiveKpiRepo,
        initialPeriodStart: initialPeriodStart,
        initialPeriodEnd: initialPeriodEnd,
      )..loadSummary(startDate: initialPeriodStart, endDate: initialPeriodEnd),
      child: _EmployeeKpiSummaryView(
        user: user,
        kpiRepository: effectiveKpiRepo,
        employeeRepository: employeeRepository ?? MockEmployeeRepository(),
        onNavigateToKpiList: onNavigateToKpiList,
      ),
    );
  }
}

class _EmployeeKpiSummaryView extends StatefulWidget {
  final CurrentUser user;
  final EmployeeKpiRepository kpiRepository;
  final EmployeeRepository employeeRepository;
  final VoidCallback? onNavigateToKpiList;

  const _EmployeeKpiSummaryView({
    required this.user,
    required this.kpiRepository,
    required this.employeeRepository,
    this.onNavigateToKpiList,
  });

  @override
  State<_EmployeeKpiSummaryView> createState() =>
      _EmployeeKpiSummaryViewState();
}

class _EmployeeKpiSummaryViewState extends State<_EmployeeKpiSummaryView> {
  final Map<String, String> _employeeNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadEmployeeNames();
  }

  Future<void> _loadEmployeeNames() async {
    try {
      final employees = await widget.employeeRepository.getEmployees();
      if (!mounted) return;
      setState(() {
        for (final emp in employees) {
          _employeeNameCache[emp.id] = emp.fullName;
        }
      });
    } catch (_) {
      // Ignored - fallback to ID
    }
  }

  void _openPeriodSelectionModal(BuildContext context) {
    final cubit = context.read<EmployeeKpiSummaryCubit>();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select KPI Measurement Period',
                      style: Theme.of(bottomSheetContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  key: const Key('kpi_summary_period_all'),
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('All Recorded Periods'),
                  onTap: () {
                    cubit.setPeriod(null, null);
                    Navigator.of(bottomSheetContext).pop();
                  },
                ),
                ListTile(
                  key: const Key('kpi_summary_period_q3_2026'),
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Q3 2026 (Jul–Sep)'),
                  subtitle: const Text('2026-07-01 to 2026-09-30'),
                  onTap: () {
                    cubit.setPeriod(
                      DateTime.utc(2026, 7, 1),
                      DateTime.utc(2026, 9, 30),
                    );
                    Navigator.of(bottomSheetContext).pop();
                  },
                ),
                ListTile(
                  key: const Key('kpi_summary_period_custom'),
                  leading: const Icon(Icons.date_range_outlined),
                  title: const Text('Custom Date Range'),
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      initialDateRange: DateTimeRange(
                        start:
                            cubit.state.periodStart ?? DateTime.utc(2026, 7, 1),
                        end: cubit.state.periodEnd ?? DateTime.utc(2026, 9, 30),
                      ),
                    );
                    if (picked != null) {
                      cubit.setPeriod(
                        DateTime.utc(
                          picked.start.year,
                          picked.start.month,
                          picked.start.day,
                        ),
                        DateTime.utc(
                          picked.end.year,
                          picked.end.month,
                          picked.end.day,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToKpiList() {
    if (widget.onNavigateToKpiList != null) {
      widget.onNavigateToKpiList!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeKpiListScreen(
          user: widget.user,
          kpiRepository: widget.kpiRepository,
          employeeRepository: widget.employeeRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: const Key('employee_kpi_summary_scaffold'),
      appBar: AppBar(
        key: const Key('employee_kpi_summary_app_bar'),
        title: const Text('KPI Performance Summary'),
        actions: [
          IconButton(
            key: const Key('kpi_summary_view_list_button'),
            tooltip: 'View All Records',
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: _navigateToKpiList,
          ),
          IconButton(
            key: const Key('kpi_summary_refresh_button'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EmployeeKpiSummaryCubit>().reload(),
          ),
        ],
      ),
      body: BlocBuilder<EmployeeKpiSummaryCubit, EmployeeKpiSummaryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(key: Key('kpi_summary_loading')),
            );
          }

          if (state.isFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 56,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load KPI summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'An unexpected error occurred.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('kpi_summary_retry_button'),
                      onPressed: () =>
                          context.read<EmployeeKpiSummaryCubit>().reload(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selection Banner
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: MediaQuery.of(context).size.width < 480
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Measurement Period',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        Text(
                                          state.activePeriodLabel,
                                          key: const Key(
                                            'kpi_summary_active_period_text',
                                          ),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  key: const Key('kpi_summary_period_button'),
                                  onPressed: () =>
                                      _openPeriodSelectionModal(context),
                                  icon: const Icon(
                                    Icons.filter_alt_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Change Period'),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Measurement Period',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      state.activePeriodLabel,
                                      key: const Key(
                                        'kpi_summary_active_period_text',
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const Key('kpi_summary_period_button'),
                                onPressed: () =>
                                    _openPeriodSelectionModal(context),
                                icon: const Icon(
                                  Icons.filter_alt_outlined,
                                  size: 16,
                                ),
                                label: const Text('Change Period'),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                if (state.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  // Summary Metrics Cards Grid
                  _buildSummaryCards(context, state),
                  const SizedBox(height: 24),

                  // Tracked Metrics Distribution
                  _buildMetricDistributionCard(context, state),
                  const SizedBox(height: 24),

                  // Per-Metric Target vs Actual Direct Comparisons
                  _buildPerMetricComparisonsSection(context, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          key: const Key('kpi_summary_empty_state'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No KPI records found for the selected period.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different measurement period or view all recorded periods.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('kpi_summary_reset_period_button'),
              onPressed: () =>
                  context.read<EmployeeKpiSummaryCubit>().setPeriod(null, null),
              icon: const Icon(Icons.all_inclusive),
              label: const Text('View All Recorded Periods'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    EmployeeKpiSummaryState state,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;
    final isMobile = width < 600;

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isSmall ? 1.05 : (isMobile ? 1.25 : 1.6),
      children: [
        _buildStatCard(
          key: const Key('kpi_summary_card_total'),
          title: 'Total KPI Records',
          value: '${state.totalKpis}',
          icon: Icons.assignment_outlined,
          color: Theme.of(context).colorScheme.primary,
          context: context,
        ),
        _buildStatCard(
          key: const Key('kpi_summary_card_employees'),
          title: 'Employees Evaluated',
          value: '${state.distinctEmployeesCount}',
          icon: Icons.people_alt_outlined,
          color: Colors.teal,
          context: context,
        ),
        _buildStatCard(
          key: const Key('kpi_summary_card_scores_recorded'),
          title: 'Scores Recorded',
          value: '${state.recordsWithScoreCount}',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          context: context,
        ),
        _buildStatCard(
          key: const Key('kpi_summary_card_scores_pending'),
          title: 'Pending Evaluation',
          value: '${state.recordsWithoutScoreCount}',
          icon: Icons.hourglass_empty_outlined,
          color: Colors.orange,
          context: context,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Key key,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: key,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricDistributionCard(
    BuildContext context,
    EmployeeKpiSummaryState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metricCounts = state.metricCounts;
    final total = state.totalKpis;

    return Card(
      key: const Key('kpi_summary_metric_distribution'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tracked Metrics Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Distribution of evaluations across distinct performance metrics',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...metricCounts.entries.map((entry) {
              final metricName = entry.key;
              final count = entry.value;
              final proportion = total > 0 ? (count / total) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            metricName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count record${count == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: proportion,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerMetricComparisonsSection(
    BuildContext context,
    EmployeeKpiSummaryState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metricGroups = state.metricRecords;

    return Column(
      key: const Key('kpi_summary_comparisons_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.compare_arrows_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Per-Metric Target vs Actual Records',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Target and actual values are presented in their native measurement units. No cross-metric averages are applied.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...metricGroups.entries.map((entry) {
          final metricName = entry.key;
          final records = entry.value;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metricName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  ...records.map((kpi) {
                    final empName =
                        _employeeNameCache[kpi.employeeId] ?? kpi.employeeId;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  empName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (kpi.score != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Score: ${kpi.score}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Score: Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${kpi.targetValue}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Actual',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${kpi.actualValue}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
