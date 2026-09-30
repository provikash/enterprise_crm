import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/employment_status.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../bloc/employee_report_cubit.dart';
import '../bloc/employee_report_state.dart';

/// Screen displaying the Employee Directory Report in the HR module.
///
/// Follows HR-8.1/8.3 specifications:
/// - Strictly protected via [HrAccessPolicy.canViewHrRecords(user)].
/// - Displays only approved, non-sensitive employee fields.
/// - Supports department, employment status, and search filters.
/// - Supports column sorting and total headcount summary.
/// - Responsive: adaptive mobile cards (<600px) and desktop table (>=600px).
class EmployeeReportScreen extends StatefulWidget {
  final CurrentUser user;
  final HrReportRepository? reportRepository;
  final EmployeeRepository? employeeRepository;
  final EmployeeReportCubit? cubit;

  const EmployeeReportScreen({
    super.key,
    required this.user,
    this.reportRepository,
    this.employeeRepository,
    this.cubit,
  });

  @override
  State<EmployeeReportScreen> createState() => _EmployeeReportScreenState();
}

class _EmployeeReportScreenState extends State<EmployeeReportScreen> {
  EmployeeReportCubit? _cubit;
  bool _internalCubit = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeCubitIfNeeded();
  }

  void _initializeCubitIfNeeded() {
    if (HrAccessPolicy.canViewHrRecords(widget.user)) {
      if (widget.cubit != null) {
        _cubit = widget.cubit!;
        _internalCubit = false;
      } else {
        _internalCubit = true;
        _cubit = EmployeeReportCubit(
          repository: widget.reportRepository ??
              MockHrReportRepository(
                employeeRepository:
                    widget.employeeRepository ?? MockEmployeeRepository(),
              ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(EmployeeReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasAuthorized = HrAccessPolicy.canViewHrRecords(oldWidget.user);
    final isAuthorized = HrAccessPolicy.canViewHrRecords(widget.user);

    if (wasAuthorized && !isAuthorized) {
      if (_internalCubit) {
        _cubit?.close();
      }
      _cubit = null;
      return;
    }

    if (!wasAuthorized && isAuthorized) {
      _initializeCubitIfNeeded();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_internalCubit) {
      _cubit?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewHrRecords(widget.user) || _cubit == null) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider<EmployeeReportCubit>.value(
      value: _cubit!,
      child: Scaffold(
        key: const Key('employee_report_scaffold'),
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Employee Directory Report'),
          ),
          actions: [
            IconButton(
              key: const Key('employee_report_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Report',
              onPressed: () => _cubit?.retry(),
            ),
          ],
        ),
        body: BlocBuilder<EmployeeReportCubit, EmployeeReportState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildSummaryAndFilterBar(context, state, colorScheme, theme),
                const Divider(height: 1),
                Expanded(
                  child: _buildReportBody(context, state, theme, colorScheme),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryAndFilterBar(
    BuildContext context,
    EmployeeReportState state,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headcount Summary Row
          Row(
            children: [
              Icon(Icons.people_alt_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total Matching Employees: ${state.totalCount}',
                  key: const Key('employee_report_total_count'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (state.query.hasFilters)
                TextButton.icon(
                  key: const Key('employee_report_clear_filters_button'),
                  onPressed: () {
                    _searchController.clear();
                    _cubit?.clearFilters();
                  },
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Field
          TextField(
            key: const Key('employee_report_search_input'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by employee name or code...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _cubit?.setSearchTerm(null);
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (val) => _cubit?.setSearchTerm(val),
          ),
          const SizedBox(height: 12),
          // Quick Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                ChoiceChip(
                  key: const Key('employee_report_status_all'),
                  label: const Text('All'),
                  selected: state.query.employmentStatus == null,
                  onSelected: (selected) {
                    if (selected) _cubit?.setEmploymentStatus(null);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  key: const Key('employee_report_status_active'),
                  label: const Text('Active'),
                  selected: state.query.employmentStatus == EmploymentStatus.active,
                  onSelected: (selected) {
                    _cubit?.setEmploymentStatus(selected ? EmploymentStatus.active : null);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  key: const Key('employee_report_status_probation'),
                  label: const Text('Probation'),
                  selected: state.query.employmentStatus == EmploymentStatus.probation,
                  onSelected: (selected) {
                    _cubit?.setEmploymentStatus(selected ? EmploymentStatus.probation : null);
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  key: const Key('employee_report_status_inactive'),
                  label: const Text('Inactive'),
                  selected: state.query.employmentStatus == EmploymentStatus.inactive,
                  onSelected: (selected) {
                    _cubit?.setEmploymentStatus(selected ? EmploymentStatus.inactive : null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportBody(
    BuildContext context,
    EmployeeReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('employee_report_loading_indicator'),
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
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ??
                    'Failed to generate Employee Directory Report.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('employee_report_retry_button'),
                onPressed: () => _cubit?.retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Report'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No employees match the selected report criteria.',
                key: const Key('employee_report_empty_state'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('employee_report_reset_empty_button'),
                onPressed: () {
                  _searchController.clear();
                  _cubit?.clearFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Criteria'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _buildDesktopTable(state, theme, colorScheme);
        }
        return _buildMobileCards(state, theme, colorScheme);
      },
    );
  }

  Widget _buildDesktopTable(
    EmployeeReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final sort = state.query.sort ?? const ReportSort(field: 'fullName');

    return SingleChildScrollView(
      key: const Key('employee_report_desktop_scroll'),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('employee_report_table'),
          sortColumnIndex: _getSortColumnIndex(sort.field),
          sortAscending: sort.direction.isAscending,
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          columns: [
            DataColumn(
              label: const Text('Code'),
              onSort: (colIndex, ascending) {
                _cubit?.setSort(
                  ReportSort(
                    field: 'employeeCode',
                    direction: ascending
                        ? ReportSortDirection.ascending
                        : ReportSortDirection.descending,
                  ),
                );
              },
            ),
            DataColumn(
              label: const Text('Full Name'),
              onSort: (colIndex, ascending) {
                _cubit?.setSort(
                  ReportSort(
                    field: 'fullName',
                    direction: ascending
                        ? ReportSortDirection.ascending
                        : ReportSortDirection.descending,
                  ),
                );
              },
            ),
            DataColumn(
              label: const Text('Department'),
              onSort: (colIndex, ascending) {
                _cubit?.setSort(
                  ReportSort(
                    field: 'department',
                    direction: ascending
                        ? ReportSortDirection.ascending
                        : ReportSortDirection.descending,
                  ),
                );
              },
            ),
            const DataColumn(label: Text('Designation')),
            const DataColumn(label: Text('Status')),
            DataColumn(
              label: const Text('Joining Date'),
              onSort: (colIndex, ascending) {
                _cubit?.setSort(
                  ReportSort(
                    field: 'joiningDate',
                    direction: ascending
                        ? ReportSortDirection.ascending
                        : ReportSortDirection.descending,
                  ),
                );
              },
            ),
          ],
          rows: state.rows.map((row) {
            return DataRow(
              key: ValueKey('employee_report_row_${row.id}'),
              cells: [
                DataCell(
                  Text(
                    row.employeeCode ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(row.fullName)),
                DataCell(Text(row.department ?? '—')),
                DataCell(Text(row.designation ?? '—')),
                DataCell(_buildStatusBadge(row.employmentStatus, colorScheme)),
                DataCell(
                  Text(
                    row.joiningDate != null
                        ? '${row.joiningDate!.year}-${row.joiningDate!.month.toString().padLeft(2, '0')}-${row.joiningDate!.day.toString().padLeft(2, '0')}'
                        : '—',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCards(
    EmployeeReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      key: const Key('employee_report_mobile_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.rows.length,
      itemBuilder: (context, index) {
        final row = state.rows[index];
        final joiningDateFormatted = row.joiningDate != null
            ? '${row.joiningDate!.year}-${row.joiningDate!.month.toString().padLeft(2, '0')}-${row.joiningDate!.day.toString().padLeft(2, '0')}'
            : '—';

        return Card(
          key: Key('employee_report_card_${row.id}'),
          margin: const EdgeInsets.symmetric(vertical: 6),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        row.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(row.employmentStatus, colorScheme),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        row.employeeCode ?? '—',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${row.department ?? 'No Dept'} • ${row.designation ?? 'No Desig'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Joined: $joiningDateFormatted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(EmploymentStatus status, ColorScheme colorScheme) {
    Color badgeColor;
    Color textColor;

    if (status == EmploymentStatus.active) {
      badgeColor = Colors.green.withValues(alpha: 0.15);
      textColor = Colors.green.shade800;
    } else if (status == EmploymentStatus.probation) {
      badgeColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange.shade800;
    } else {
      badgeColor = Colors.grey.withValues(alpha: 0.15);
      textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  int? _getSortColumnIndex(String field) {
    switch (field) {
      case 'employeeCode':
        return 0;
      case 'fullName':
        return 1;
      case 'department':
        return 2;
      case 'joiningDate':
        return 5;
      default:
        return 1;
    }
  }
}
