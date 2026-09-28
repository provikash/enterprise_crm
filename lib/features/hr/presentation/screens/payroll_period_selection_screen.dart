import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../bloc/payroll_period_cubit.dart';
import '../bloc/payroll_period_state.dart';
import '../widgets/payroll_period_selector.dart';

/// Minimal entry screen for HR Payroll Period Selection.
///
/// Follows HR-6.4 architectural boundaries:
/// - Access strictly restricted via [HrAccessPolicy.canViewPayroll].
/// - Constructor-based injection of [PayrollRepository].
/// - Connects [PayrollPeriodCubit] to [PayrollPeriodSelector].
/// - Displays selected period metadata without speculative calculations.
/// - Ready for consumption by HR-6.5 Payroll Overview.
class PayrollPeriodSelectionScreen extends StatefulWidget {
  final CurrentUser user;
  final PayrollRepository? payrollRepository;
  final String? initialPeriodId;

  const PayrollPeriodSelectionScreen({
    super.key,
    required this.user,
    this.payrollRepository,
    this.initialPeriodId,
  });

  @override
  State<PayrollPeriodSelectionScreen> createState() =>
      _PayrollPeriodSelectionScreenState();
}

class _PayrollPeriodSelectionScreenState
    extends State<PayrollPeriodSelectionScreen> {
  PayrollPeriodCubit? _cubit;

  @override
  void initState() {
    super.initState();
    if (HrAccessPolicy.canViewPayroll(widget.user)) {
      final repo = widget.payrollRepository ?? MockPayrollRepository();
      _cubit = PayrollPeriodCubit(
        repository: repo,
        initialPeriodId: widget.initialPeriodId,
      )..loadPeriods();
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(widget.user)) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubit = _cubit!;

    return BlocProvider<PayrollPeriodCubit>.value(
      value: cubit,
      child: Scaffold(
        key: const Key('payroll_period_selection_scaffold'),
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Payroll Period Selection'),
          ),
          actions: [
            IconButton(
              key: const Key('payroll_period_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Periods',
              onPressed: () => cubit.reload(),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PayrollPeriodSelector(
                      key: Key('payroll_period_screen_selector'),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<PayrollPeriodCubit, PayrollPeriodState>(
                      builder: (context, state) {
                        final period = state.selectedPeriod;
                        if (period == null) {
                          return Card(
                            key: const Key('payroll_no_period_selected_card'),
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 32,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please select a payroll period above to view details.',
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

                        return Card(
                          key: const Key('payroll_period_info_card'),
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Period Summary',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Period ID',
                                  period.id,
                                  key: 'info_row_id',
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  'Period Name',
                                  period.name,
                                  key: 'info_row_name',
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  'Date Range',
                                  period.formattedPeriod,
                                  key: 'info_row_range',
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  'Payment Date',
                                  period.formattedPaymentDate ?? 'Pending / Unscheduled',
                                  key: 'info_row_payment_date',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required String key}) {
    return Row(
      key: Key(key),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
