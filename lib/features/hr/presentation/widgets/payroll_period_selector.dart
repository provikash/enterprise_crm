import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payroll_period.dart';
import '../bloc/payroll_period_cubit.dart';
import '../bloc/payroll_period_state.dart';

/// Reusable responsive component for inspecting and selecting approved Payroll Periods.
///
/// Follows HR-6.4 architectural constraints:
/// - Connects to [PayrollPeriodCubit] provided above or via context.
/// - Renders loading, loaded, empty, and failure states.
/// - Shows approved period names and date ranges without speculative calculations.
/// - Adapts gracefully across mobile (320px–360px), tablet (768px), and desktop (1200px) viewports.
/// - Supports Light and Dark themes via Theme tokens.
class PayrollPeriodSelector extends StatelessWidget {
  final ValueChanged<PayrollPeriod?>? onPeriodChanged;
  final bool showHeader;

  const PayrollPeriodSelector({
    super.key,
    this.onPeriodChanged,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<PayrollPeriodCubit, PayrollPeriodState>(
      listenWhen: (previous, current) =>
          previous.selectedPeriodId != current.selectedPeriodId,
      listener: (context, state) {
        onPeriodChanged?.call(state.selectedPeriod);
      },
      builder: (context, state) {
        return Card(
          key: const Key('payroll_period_selector_card'),
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHeader) ...[
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
                  const SizedBox(height: 12),
                ],
                _buildContent(context, state, theme, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PayrollPeriodState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (state.status) {
      case PayrollPeriodStatus.initial:
      case PayrollPeriodStatus.loading:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                key: Key('payroll_period_loading_indicator'),
                strokeWidth: 2.5,
              ),
            ),
          ),
        );

      case PayrollPeriodStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 32,
                  key: const Key('payroll_period_error_icon'),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Failed to load payroll periods.',
                  key: const Key('payroll_period_error_message'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('payroll_period_retry_button'),
                  onPressed: () => context.read<PayrollPeriodCubit>().retry(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case PayrollPeriodStatus.loaded:
        if (state.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 32,
                    key: const Key('payroll_period_empty_icon'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No payroll periods are available.',
                    key: const Key('payroll_period_empty_message'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: const Key('payroll_period_empty_refresh_button'),
                    onPressed: () => context.read<PayrollPeriodCubit>().reload(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        final selected = state.selectedPeriod;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('payroll_period_dropdown'),
                  value: state.selectedPeriodId,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text(
                    'Select a payroll period',
                    key: Key('payroll_period_select_hint'),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return state.periods.map<Widget>((period) {
                      return Text(
                        '${period.name} (${period.formattedPeriod})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                  items: state.periods.map((period) {
                    return DropdownMenuItem<String>(
                      key: Key('payroll_period_item_${period.id}'),
                      value: period.id,
                      child: Text(
                        '${period.name} (${period.formattedPeriod})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (periodId) {
                    if (periodId != null) {
                      context.read<PayrollPeriodCubit>().selectPeriod(periodId);
                    }
                  },
                ),
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('payroll_period_selected_details'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Period: ${selected.name} (${selected.formattedPeriod})',
                        key: const Key('payroll_period_selected_label'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
    }
  }
}
