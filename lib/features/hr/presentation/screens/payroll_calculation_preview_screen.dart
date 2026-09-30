import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_employee_repository.dart';
import '../../data/repositories/mock_payroll_repository.dart';
import '../../domain/entities/payroll_calculation_input.dart';
import '../../domain/entities/payroll_component.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../domain/services/payroll_calculation_engine.dart';
import '../../domain/value_objects/calculation_validation_issue.dart';
import '../bloc/payroll_calculation_preview_cubit.dart';
import '../bloc/payroll_calculation_preview_state.dart';

/// Screen displaying the interactive, non-final Payroll Calculation Preview.
///
/// Follows HR-7.6 specifications:
/// - Strictly protected via [HrAccessPolicy.canViewPayroll(user)].
/// - Prominently displays a "PREVIEW ONLY — NON-FINAL" banner.
/// - Renders itemized earnings, deductions, gross totals, and net take-home pay.
/// - Surfaces diagnostic validation warnings and policy notices.
/// - Supports interactive simulation of attendance Loss of Pay proration policies.
/// - Pure presentation: delegates all financial calculations to [PayrollCalculationEngine].
/// - Responsive across mobile (<600px) and desktop (>=600px) viewports without overflow.
class PayrollCalculationPreviewScreen extends StatefulWidget {
  final CurrentUser user;
  final PayrollCalculationInput input;
  final EmployeeRepository? employeeRepository;
  final PayrollRepository? payrollRepository;
  final PayrollCalculationEngine? engine;
  final PayrollCalculationPreviewCubit? cubit;
  final AttendanceProrationPolicy initialAttendancePolicy;

  const PayrollCalculationPreviewScreen({
    super.key,
    required this.user,
    required this.input,
    this.employeeRepository,
    this.payrollRepository,
    this.engine,
    this.cubit,
    this.initialAttendancePolicy = AttendanceProrationPolicy.unresolved,
  });

  @override
  State<PayrollCalculationPreviewScreen> createState() =>
      _PayrollCalculationPreviewScreenState();
}

class _PayrollCalculationPreviewScreenState
    extends State<PayrollCalculationPreviewScreen> {
  PayrollCalculationPreviewCubit? _cubit;
  bool _internalCubit = false;

  @override
  void initState() {
    super.initState();
    _initializeCubitIfNeeded();
  }

  void _initializeCubitIfNeeded() {
    if (HrAccessPolicy.canViewPayroll(widget.user)) {
      if (widget.cubit != null) {
        _cubit = widget.cubit!;
        _internalCubit = false;
      } else {
        _internalCubit = true;
        _cubit = PayrollCalculationPreviewCubit(
          engine: widget.engine ?? const PayrollCalculationEngine(),
          employeeRepository:
              widget.employeeRepository ?? MockEmployeeRepository(),
          payrollRepository:
              widget.payrollRepository ?? MockPayrollRepository(),
          initialInput: widget.input,
          initialAttendancePolicy: widget.initialAttendancePolicy,
        );
      }
    }
  }

  @override
  void didUpdateWidget(PayrollCalculationPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasAuthorized = HrAccessPolicy.canViewPayroll(oldWidget.user);
    final isAuthorized = HrAccessPolicy.canViewPayroll(widget.user);

    if (wasAuthorized && !isAuthorized) {
      if (_internalCubit) {
        _cubit?.close();
      }
      _cubit = null;
      return;
    }

    if (!wasAuthorized && isAuthorized) {
      _initializeCubitIfNeeded();
      return;
    }

    if (isAuthorized && oldWidget.input != widget.input) {
      _cubit?.calculatePreview(
        input: widget.input,
        attendancePolicy: widget.initialAttendancePolicy,
      );
    }
  }

  @override
  void dispose() {
    if (_internalCubit) {
      _cubit?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canViewPayroll(widget.user) || _cubit == null) {
      return const AccessRestrictedScreen();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider<PayrollCalculationPreviewCubit>.value(
      value: _cubit!,
      child: Scaffold(
        key: const Key('payroll_calculation_preview_scaffold'),
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Payroll Calculation Preview'),
          ),
          actions: [
            IconButton(
              key: const Key('preview_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Recalculate Preview',
              onPressed: () => _cubit?.retry(),
            ),
          ],
        ),
        body: BlocBuilder<PayrollCalculationPreviewCubit,
            PayrollCalculationPreviewState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  key: Key('preview_loading_indicator'),
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
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage ??
                            'Failed to evaluate calculation preview.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('preview_retry_button'),
                        onPressed: () => _cubit?.retry(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Calculation'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final result = state.result;
            if (result == null) {
              return const Center(
                child: Text('No calculation preview available.'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;

                return SingleChildScrollView(
                  key: const Key('preview_scroll_view'),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24.0 : 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Mandatory Non-Final Banner
                      _buildNonFinalBanner(theme, colorScheme),
                      const SizedBox(height: 16),

                      // 2. Workforce & Period Context
                      _buildContextCard(state, theme, colorScheme, isDesktop),
                      const SizedBox(height: 16),

                      // 3. Interactive Attendance Policy Simulation
                      if (widget.input.unpaidLeaveDays > 0) ...[
                        _buildAttendancePolicySelector(
                          state,
                          theme,
                          colorScheme,
                          isDesktop,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Net Payable Summary Hero Card
                      _buildNetPayableCard(result, theme, colorScheme),
                      const SizedBox(height: 16),

                      // 5. Diagnostic Issues & Warnings
                      if (result.validationIssues.isNotEmpty) ...[
                        _buildValidationIssuesCard(
                          result.validationIssues,
                          theme,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 6. Itemized Breakdown (Side-by-Side on Desktop, Stacked on Mobile)
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildEarningsCard(
                                result,
                                theme,
                                colorScheme,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDeductionsCard(
                                result,
                                theme,
                                colorScheme,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildEarningsCard(result, theme, colorScheme),
                        const SizedBox(height: 16),
                        _buildDeductionsCard(result, theme, colorScheme),
                      ],

                      const SizedBox(height: 24),
                      // 7. Non-Authoritative Metadata Footer
                      _buildFooterNotice(result, theme),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Prominent banner highlighting the non-authoritative simulation nature.
  Widget _buildNonFinalBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      key: const Key('preview_non_final_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade800,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREVIEW ONLY — NON-FINAL CALCULATION',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This is an in-memory simulation preview. Compensation values have '
                  'NOT been approved, finalized, or submitted for payment. Zero database records were modified.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header card with workforce employee and period identity.
  Widget _buildContextCard(
    PayrollCalculationPreviewState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final employee = state.employee;
    final period = state.period;

    return Card(
      key: const Key('preview_context_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.person_outline),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee?.fullName ?? 'Employee ID: ${widget.input.employeeId}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${employee?.designation ?? "Staff"} • ${employee?.department ?? "Organization"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    employee?.employmentStatus.value ?? 'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  Icons.calendar_month_outlined,
                  'Period',
                  period?.name ?? widget.input.payrollPeriodId,
                  theme,
                  colorScheme,
                ),
                if (period != null)
                  _buildInfoBadge(
                    Icons.date_range_outlined,
                    'Range',
                    period.formattedPeriod,
                    theme,
                    colorScheme,
                  ),
                _buildInfoBadge(
                  Icons.event_busy_outlined,
                  'Unpaid Leave',
                  '${widget.input.unpaidLeaveDays} day(s)',
                  theme,
                  colorScheme,
                ),
                _buildInfoBadge(
                  Icons.account_balance_wallet_outlined,
                  'Base Salary',
                  widget.input.baseSalary.formatted,
                  theme,
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Interactive Attendance Loss of Pay Proration Policy Selector.
  Widget _buildAttendancePolicySelector(
    PayrollCalculationPreviewState state,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    return Card(
      key: const Key('preview_policy_selector_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulate Attendance LOP Policy',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select an approved Loss of Pay divisor policy to simulate attendance proration impact:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('policy_chip_unresolved'),
                  label: const Text('Unresolved (Defer)'),
                  selected:
                      state.attendancePolicy == AttendanceProrationPolicy.unresolved,
                  onSelected: (selected) {
                    if (selected) {
                      _cubit?.setAttendancePolicy(
                        AttendanceProrationPolicy.unresolved,
                      );
                    }
                  },
                ),
                ChoiceChip(
                  key: const Key('policy_chip_calendar'),
                  label: const Text('Calendar Days'),
                  selected:
                      state.attendancePolicy == AttendanceProrationPolicy.calendarDays,
                  onSelected: (selected) {
                    if (selected) {
                      _cubit?.setAttendancePolicy(
                        AttendanceProrationPolicy.calendarDays,
                      );
                    }
                  },
                ),
                ChoiceChip(
                  key: const Key('policy_chip_fixed30'),
                  label: const Text('Fixed 30 Days'),
                  selected:
                      state.attendancePolicy == AttendanceProrationPolicy.fixed30Days,
                  onSelected: (selected) {
                    if (selected) {
                      _cubit?.setAttendancePolicy(
                        AttendanceProrationPolicy.fixed30Days,
                      );
                    }
                  },
                ),
                ChoiceChip(
                  key: const Key('policy_chip_working26'),
                  label: const Text('Working 26 Days'),
                  selected: state.attendancePolicy ==
                      AttendanceProrationPolicy.workingDays26,
                  onSelected: (selected) {
                    if (selected) {
                      _cubit?.setAttendancePolicy(
                        AttendanceProrationPolicy.workingDays26,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Net Take-Home Hero Summary Card.
  Widget _buildNetPayableCard(
    dynamic result,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isNegative = result.netPayable.isNegative;

    return Card(
      key: const Key('preview_net_payable_card'),
      elevation: 2,
      color: isNegative
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Text(
              'NET ESTIMATED PAYABLE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isNegative
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.netPayable.formatted,
              key: const Key('preview_net_payable_amount'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNegative
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isNegative
                  ? 'Deficit: Total deductions exceed gross earnings'
                  : 'Calculated take-home preview for ${result.employeeId}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isNegative
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card displaying diagnostic warnings and validation issues.
  Widget _buildValidationIssuesCard(
    List<CalculationValidationIssue> issues,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      key: const Key('preview_validation_issues_card'),
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diagnostic Notices (${issues.length})',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: issue.isError
                            ? colorScheme.error
                            : Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        issue.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Itemized Earnings Card.
  Widget _buildEarningsCard(
    dynamic result,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final earnings = result.earnings as List<PayrollComponent>;

    return Card(
      key: const Key('preview_earnings_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
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
                  child: Text(
                    'Earnings Breakdown',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  result.grossEarnings.formatted,
                  key: const Key('preview_gross_earnings_amount'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...earnings.map(
              (earning) => _buildLineItem(
                title: earning.name,
                amount: earning.amount.formatted,
                badge: earning.source.name,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Itemized Deductions Card.
  Widget _buildDeductionsCard(
    dynamic result,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final deductions = result.deductions as List<PayrollComponent>;

    return Card(
      key: const Key('preview_deductions_card'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
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
                  child: Text(
                    'Deductions Breakdown',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  result.totalDeductions.formatted,
                  key: const Key('preview_total_deductions_amount'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (deductions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Zero deductions applicable for this period.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...deductions.map(
                (deduction) => _buildLineItem(
                  title: deduction.name,
                  amount: deduction.amount.formatted,
                  badge: deduction.calculationRuleId ?? deduction.source.name,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem({
    required String title,
    required String amount,
    required String badge,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Footer with rule version and calculation provenance.
  Widget _buildFooterNotice(dynamic result, ThemeData theme) {
    return Center(
      child: Text(
        'Rule Version: ${result.ruleVersion} • '
        'Calculation ID: ${result.calculationId} • Non-Final',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
