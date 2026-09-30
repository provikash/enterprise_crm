import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_attendance_repository.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_hr_report_repository.dart';
import '../../domain/entities/attendance_report_row.dart';
import '../../domain/entities/attendance_report_summary.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/report_sort.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/hr_report_repository.dart';
import '../bloc/attendance_report_cubit.dart';
import '../bloc/attendance_report_state.dart';
import '../widgets/attendance_status_badge.dart';

/// Screen presenting the Attendance Summary Report.
///
/// Follows HR-8.4 requirements:
/// - Evaluates daily & period attendance records from [AttendanceRepository].
/// - Displays only approved fields: date, employeeId/code/name, status, check-in, check-out, remarks.
/// - Preserves missing attendance integrity: unrecorded days are NOT reported as absent.
/// - Displays approved summary counts only: Total Records, Present, Absent, Half-day, On Leave.
/// - Strictly 0 attendance percentages or punctuality rankings.
/// - Protected by [HrAccessPolicy.canViewHrRecords].
class AttendanceReportScreen extends StatelessWidget {
  final CurrentUser user;
  final HrReportRepository? reportRepository;
  final AttendanceRepository? attendanceRepository;
  final EmployeeRepository? employeeRepository;
  final AttendanceReportCubit? cubit;

  const AttendanceReportScreen({
    super.key,
    required this.user,
    this.reportRepository,
    this.attendanceRepository,
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
          attendanceRepository:
              attendanceRepository ?? MockAttendanceRepository(),
        );

    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _AttendanceReportView(),
      );
    }

    return BlocProvider(
      create: (_) => AttendanceReportCubit(
        repository: effectiveReportRepo,
      )..loadReport(),
      child: const _AttendanceReportView(),
    );
  }
}

class _AttendanceReportView extends StatefulWidget {
  const _AttendanceReportView();

  @override
  State<_AttendanceReportView> createState() => _AttendanceReportViewState();
}

class _AttendanceReportViewState extends State<_AttendanceReportView> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _statuses = [
    'All',
    'Present',
    'Absent',
    'Half-day',
    'On Leave',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<AttendanceReportCubit>().setSearchTerm(query);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<AttendanceReportCubit>();
    final currentRange = cubit.state.query.dateRange;

    final initialDateRange = currentRange != null
        ? DateTimeRange(
            start: currentRange.startDate,
            end: currentRange.endDate,
          )
        : DateTimeRange(
            start: DateTime.utc(2026, 9, 21),
            end: DateTime.utc(2026, 9, 25),
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
      key: const Key('attendance_report_scaffold'),
      appBar: AppBar(
        title: const Text('Attendance Summary Report'),
        actions: [
          IconButton(
            key: const Key('attendance_report_refresh_button'),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AttendanceReportCubit>().loadReport(forceRefresh: true),
          ),
        ],
      ),
      body: BlocConsumer<AttendanceReportCubit, AttendanceReportState>(
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
    AttendanceReportState state,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<AttendanceReportCubit>();
    final activeStatus = state.query.status ?? 'All';

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
              key: const Key('attendance_report_search_input'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by employee name or code...',
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

            // Date Range & Clear Filters Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('attendance_report_date_range_button'),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    state.query.dateRange != null
                        ? state.query.dateRange!.formattedLabel
                        : 'Filter Date Range',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _pickDateRange(context),
                ),
                if (state.query.dateRange != null)
                  IconButton(
                    key: const Key('attendance_report_clear_date_range_button'),
                    tooltip: 'Clear Date Range',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => cubit.setDateRangeFilter(null),
                  ),
                if (state.query.hasActiveFilters)
                  TextButton.icon(
                    key: const Key('attendance_report_clear_filters_button'),
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

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final isSelected = activeStatus == status;
                  final keyName = status.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      key: Key('attendance_report_status_$keyName'),
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (_) => cubit.setStatusFilter(status),
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
    AttendanceReportSummary summary,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('attendance_report_summary_card'),
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
              'Total Records: ${summary.totalRecords}',
              key: const Key('attendance_report_total_count'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Present: ${summary.presentCount}',
              key: const Key('attendance_report_present_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              'Absent: ${summary.absentCount}',
              key: const Key('attendance_report_absent_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
            Text(
              'Half-day: ${summary.halfDayCount}',
              key: const Key('attendance_report_half_day_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.orange.shade800,
              ),
            ),
            Text(
              'On Leave: ${summary.onLeaveCount}',
              key: const Key('attendance_report_on_leave_count'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('attendance_report_loading'),
        ),
      );
    }

    if (state.isFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            key: const Key('attendance_report_error_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    'Failed to generate Attendance Report. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('attendance_report_retry_button'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => context.read<AttendanceReportCubit>().retry(),
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
            key: const Key('attendance_report_empty_state'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'No attendance records match the selected report criteria.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (state.query.hasActiveFilters)
                OutlinedButton.icon(
                  key: const Key('attendance_report_reset_empty_button'),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AttendanceReportCubit>().clearFilters();
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
    List<AttendanceReportRow> rows,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      key: const Key('attendance_report_mobile_list'),
      padding: const EdgeInsets.all(16.0),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return Card(
          key: ValueKey('attendance_mobile_card_${row.attendanceId}'),
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
                        row.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AttendanceStatusBadge(status: row.attendanceStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.employeeCode ?? row.employeeId,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      row.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (row.checkIn != null || row.checkOut != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Time: ${row.formattedCheckIn ?? '--:--'} – ${row.formattedCheckOut ?? '--:--'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
    List<AttendanceReportRow> rows,
    ReportSort? activeSort,
  ) {
    final cubit = context.read<AttendanceReportCubit>();

    void onSortCol(String field) {
      final currentField = activeSort?.field ?? 'date';
      final isDesc = activeSort?.direction.isDescending ?? true;
      final newDir = currentField == field && isDesc
          ? ReportSortDirection.ascending
          : ReportSortDirection.descending;

      cubit.setSort(ReportSort(field: field, direction: newDir));
    }

    final sortColumnIndex = switch (activeSort?.field) {
      'date' => 0,
      'employeeName' => 1,
      'employeeCode' => 2,
      'status' => 3,
      _ => 0,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('attendance_report_table'),
          sortColumnIndex: sortColumnIndex,
          sortAscending: activeSort?.direction.isAscending ?? false,
          columns: [
            DataColumn(
              label: const Text('Date'),
              onSort: (columnIndex, ascending) => onSortCol('date'),
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
              label: const Text('Status'),
              onSort: (columnIndex, ascending) => onSortCol('status'),
            ),
            const DataColumn(label: Text('Check In')),
            const DataColumn(label: Text('Check Out')),
            const DataColumn(label: Text('Remarks')),
          ],
          rows: rows.map((row) {
            return DataRow(
              key: ValueKey('attendance_table_row_${row.attendanceId}'),
              cells: [
                DataCell(Text(row.formattedDate)),
                DataCell(Text(row.employeeName)),
                DataCell(Text(row.employeeCode ?? '—')),
                DataCell(AttendanceStatusBadge(status: row.attendanceStatus)),
                DataCell(Text(row.formattedCheckIn ?? '—')),
                DataCell(Text(row.formattedCheckOut ?? '—')),
                DataCell(Text(row.remarks ?? '—')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
