import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../bloc/attendance_dashboard_cubit.dart';
import '../bloc/attendance_dashboard_state.dart';
import '../bloc/attendance_list_state.dart';
import '../widgets/attendance_feature_card.dart';
import 'attendance_list_screen.dart';

/// Date-scoped landing dashboard for the implemented Attendance capabilities.
class AttendanceHomeScreen extends StatelessWidget {
  final CurrentUser user;
  final AttendanceRepository repository;
  final DateTime? initialDate;

  const AttendanceHomeScreen({
    super.key,
    required this.user,
    required this.repository,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewHrRecords(user)) {
      return const AccessRestrictedScreen();
    }

    final today = initialDate ?? DateTime.now();
    return BlocProvider(
      create: (_) =>
          AttendanceDashboardCubit(repository: repository, initialDate: today)
            ..loadDate(today),
      child: _AttendanceHomeView(user: user, repository: repository),
    );
  }
}

class _AttendanceHomeView extends StatelessWidget {
  final CurrentUser user;
  final AttendanceRepository repository;

  const _AttendanceHomeView({required this.user, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceDashboardCubit, AttendanceDashboardState>(
      builder: (context, state) {
        return Scaffold(
          key: const Key('attendance_home_scaffold'),
          appBar: AppBar(
            title: const Text('Attendance'),
            actions: [
              IconButton(
                key: const Key('attendance_home_refresh_button'),
                tooltip: 'Refresh selected date',
                onPressed: state.isLoading
                    ? null
                    : () => context.read<AttendanceDashboardCubit>().refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<AttendanceDashboardCubit>().refresh(),
            child: ListView(
              key: const Key('attendance_home_scroll_view'),
              padding: const EdgeInsets.all(16),
              children: [
                const _Header(),
                const SizedBox(height: 16),
                _DateSelector(
                  selectedDate: state.selectedDate,
                  disabled: state.isLoading,
                ),
                const SizedBox(height: 16),
                _Summary(state: state),
                const SizedBox(height: 24),
                Text(
                  'Quick access',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _FeatureGrid(
                  user: user,
                  repository: repository,
                  selectedDate: state.selectedDate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workforce attendance',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review authoritative records for the selected date and open attendance history or calendar views.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final bool disabled;

  const _DateSelector({required this.selectedDate, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final label =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const Key('attendance_home_date_button'),
        icon: const Icon(Icons.event_outlined),
        label: Text(label),
        onPressed: disabled
            ? null
            : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null && context.mounted) {
                  await context.read<AttendanceDashboardCubit>().loadDate(
                    picked,
                  );
                }
              },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final AttendanceDashboardState state;

  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const SizedBox(
        height: 112,
        child: Center(
          child: CircularProgressIndicator(
            key: Key('attendance_home_loading_indicator'),
          ),
        ),
      );
    }

    if (state.isFailure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unable to load attendance.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                key: const Key('attendance_home_retry_button'),
                onPressed: () =>
                    context.read<AttendanceDashboardCubit>().refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final metrics = [
      ('Recorded', state.records.length, Icons.fact_check_outlined),
      ('Present', state.presentCount, Icons.check_circle_outline),
      ('Absent', state.absentCount, Icons.cancel_outlined),
      ('On Leave', state.leaveCount, Icons.event_busy_outlined),
      ('Half-day', state.halfDayCount, Icons.timelapse_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          key: const Key('attendance_summary_grid'),
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _SummaryCard(
                  label: metric.$1,
                  value: metric.$2,
                  icon: metric.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: theme.textTheme.titleLarge),
                  Text(label, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final CurrentUser user;
  final AttendanceRepository repository;
  final DateTime selectedDate;

  const _FeatureGrid({
    required this.user,
    required this.repository,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      AttendanceFeatureCard(
        key: const Key('attendance_feature_daily_records'),
        icon: Icons.today_outlined,
        title: 'Selected date records',
        description: 'Search and review records for the selected date',
        onTap: () => _openList(context, initialDate: selectedDate),
      ),
      AttendanceFeatureCard(
        key: const Key('attendance_feature_calendar'),
        icon: Icons.calendar_month_outlined,
        title: 'Calendar',
        description: 'Browse attendance records by month and date',
        onTap: () => _openList(
          context,
          initialViewMode: AttendanceViewMode.calendar,
          initialCalendarMonth: selectedDate,
        ),
      ),
      AttendanceFeatureCard(
        key: const Key('attendance_feature_history'),
        icon: Icons.history_outlined,
        title: 'Attendance history',
        description: 'Search and filter all available attendance records',
        onTap: () => _openList(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          key: const Key('attendance_feature_grid'),
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  void _openList(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? initialCalendarMonth,
    AttendanceViewMode initialViewMode = AttendanceViewMode.list,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendanceListScreen(
          user: user,
          repository: repository,
          initialDate: initialDate,
          initialCalendarMonth: initialCalendarMonth,
          initialViewMode: initialViewMode,
        ),
      ),
    );
  }
}
