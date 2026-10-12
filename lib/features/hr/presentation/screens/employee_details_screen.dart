import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_attendance_repository.dart';
import '../../data/repositories/mock_employee_document_repository.dart';
import '../../data/repositories/mock_employee_kpi_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employment_status.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_document_repository.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../bloc/employee_details_cubit.dart';
import '../bloc/employee_details_state.dart';
import '../widgets/hr_info_row.dart';
import '../widgets/hr_section_card.dart';
import 'edit_employee_screen.dart';
import 'employee_attendance_history_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_kpi_list_screen.dart';

/// Employee Details screen displaying full information for a selected employee record.
class EmployeeDetailsScreen extends StatelessWidget {
  final CurrentUser user;
  final String employeeId;
  final EmployeeRepository repository;
  final EmployeeDocumentRepository? documentRepository;
  final AttendanceRepository? attendanceRepository;
  final EmployeeKpiRepository? kpiRepository;

  const EmployeeDetailsScreen({
    super.key,
    required this.user,
    required this.employeeId,
    required this.repository,
    this.documentRepository,
    this.attendanceRepository,
    this.kpiRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (!HrAccessPolicy.canAccessModule(user)) {
      return const AccessRestrictedScreen();
    }

    if (!user.isAdmin && !HrAccessPolicy.canViewHrRecords(user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider(
      create: (_) =>
          EmployeeDetailsCubit(repository: repository)
            ..loadEmployee(employeeId),
      child: _EmployeeDetailsView(
        user: user,
        employeeId: employeeId,
        repository: repository,
        documentRepository: documentRepository,
        attendanceRepository: attendanceRepository,
        kpiRepository: kpiRepository,
      ),
    );
  }
}

class _EmployeeDetailsView extends StatefulWidget {
  final CurrentUser user;
  final String employeeId;
  final EmployeeRepository repository;
  final EmployeeDocumentRepository? documentRepository;
  final AttendanceRepository? attendanceRepository;
  final EmployeeKpiRepository? kpiRepository;

  const _EmployeeDetailsView({
    required this.user,
    required this.employeeId,
    required this.repository,
    this.documentRepository,
    this.attendanceRepository,
    this.kpiRepository,
  });

  @override
  State<_EmployeeDetailsView> createState() => _EmployeeDetailsViewState();
}

class _EmployeeDetailsViewState extends State<_EmployeeDetailsView> {
  bool _didMutate = false;

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.user.isAdmin;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop(_didMutate);
        }
      },
      child: Scaffold(
        key: const Key('employee_details_scaffold'),
        appBar: AppBar(
          title: const Text('Employee Details'),
          leading: BackButton(
            key: const Key('employee_details_back_button'),
            onPressed: () => Navigator.of(context).pop(_didMutate),
          ),
          actions: [
            BlocBuilder<EmployeeDetailsCubit, EmployeeDetailsState>(
              builder: (context, state) {
                if (state.isLoaded && canEdit && state.employee != null) {
                  return TextButton.icon(
                    key: const Key('employee_details_edit_button'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditEmployeeScreen(
                            user: widget.user,
                            employee: state.employee!,
                            repository: widget.repository,
                          ),
                        ),
                      );
                      if (updated == true && context.mounted) {
                        _didMutate = true;
                        context.read<EmployeeDetailsCubit>().reload();
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<EmployeeDetailsCubit, EmployeeDetailsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  key: Key('employee_details_loading_indicator'),
                ),
              );
            }

            if (state.isFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                        key: Key('employee_details_error_icon'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ?? 'Failed to load employee record.',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        key: const Key('employee_details_retry_button'),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () =>
                            context.read<EmployeeDetailsCubit>().reload(),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.isNotFound) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 48,
                        color: Colors.grey,
                        key: Key('employee_details_not_found_icon'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Employee Not Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record with ID "${state.searchedId ?? widget.employeeId}" does not exist.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.isLoaded && state.employee != null) {
              return _buildContent(context, state.employee!);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Employee employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      key: const Key('employee_details_content_scroll'),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          employee.fullName.isNotEmpty
                              ? employee.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.fullName,
                              key: const Key('employee_details_name_text'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              employee.employeeCode ?? 'No Code Assigned',
                              key: const Key('employee_details_code_text'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StatusBadge(status: employee.employmentStatus),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sub-Feature Navigation Overview Grid (Progressive Disclosure)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final cards = [
                    // Employee Documents Card
                    Card(
                      key: const Key('employee_details_documents_card'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      color: colorScheme.surfaceContainerLowest,
                      child: ListTile(
                        key: const Key('employee_documents_tile'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_shared_outlined,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: const Text(
                          'Employee Documents',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Agreements, KYC, identity, and certificates',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EmployeeDocumentsScreen(
                                user: widget.user,
                                employee: employee,
                                repository:
                                    widget.documentRepository ??
                                    MockEmployeeDocumentRepository(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Attendance History Card
                    Card(
                      key: const Key('employee_details_attendance_card'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      color: colorScheme.surfaceContainerLowest,
                      child: ListTile(
                        key: const Key('employee_attendance_tile'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: const Text(
                          'Attendance History',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Recorded daily logs and check-in/out records',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EmployeeAttendanceHistoryScreen(
                                user: widget.user,
                                employee: employee,
                                repository:
                                    widget.attendanceRepository ??
                                    MockAttendanceRepository(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Performance / KPI Card
                    Card(
                      key: const Key('employee_details_kpi_card'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      color: colorScheme.surfaceContainerLowest,
                      child: ListTile(
                        key: const Key('employee_kpi_tile'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.assessment_outlined,
                            size: 22,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: const Text(
                          'Performance (KPI)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Quarterly goals and evaluation metrics',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EmployeeKpiListScreen(
                                user: widget.user,
                                initialEmployeeId: employee.id,
                                kpiRepository:
                                    widget.kpiRepository ??
                                    MockEmployeeKpiRepository(),
                                employeeRepository: widget.repository,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (HrAccessPolicy.canViewPayroll(widget.user))
                      Card(
                        key: const Key('employee_details_payroll_card'),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        color: colorScheme.surfaceContainerLowest,
                        child: ListTile(
                          key: const Key('employee_payroll_tile'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              size: 22,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: const Text(
                            'Payroll & Compensation',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Salary disbursement & tax compliance',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _showPayrollOverview(context),
                        ),
                      ),
                  ];

                  if (isWide) {
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: cards.map((c) {
                        return SizedBox(
                          width: (constraints.maxWidth - 14) / 2,
                          child: c,
                        );
                      }).toList(),
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Position & Organization Info
              _buildSectionCard(
                context,
                title: 'Organization & Role',
                icon: Icons.work_outline,
                children: [
                  _buildDetailRow('Department', employee.department ?? '—'),
                  _buildDetailRow('Designation', employee.designation ?? '—'),
                  _buildDetailRow(
                    'Joining Date',
                    employee.joiningDate != null
                        ? '${employee.joiningDate!.year}-${employee.joiningDate!.month.toString().padLeft(2, '0')}-${employee.joiningDate!.day.toString().padLeft(2, '0')}'
                        : '—',
                  ),
                  _buildDetailRow('Status', employee.employmentStatus.value),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Information
              _buildSectionCard(
                context,
                title: 'Contact Information',
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildDetailRow('Email', employee.email ?? '—'),
                  _buildDetailRow('Phone', employee.phone ?? '—'),
                ],
              ),
              const SizedBox(height: 16),

              // System Linkage
              _buildSectionCard(
                context,
                title: 'CRM System Account',
                icon: Icons.account_circle_outlined,
                children: [
                  _buildDetailRow(
                    'Linked User ID',
                    employee.userId ?? 'Not linked to any CRM account',
                  ),
                ],
              ),
              if (HrAccessPolicy.canViewPayroll(widget.user)) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
                  title: 'Compensation & Payroll',
                  icon: Icons.payments_outlined,
                  trailing: TextButton.icon(
                    key: const Key('employee_details_payroll_view_button'),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Policy'),
                    onPressed: () => _showPayrollOverview(context),
                  ),
                  children: [
                    _buildDetailRow('Disbursement', 'Monthly Payroll Cycle'),
                    _buildDetailRow('Compensation Framework', 'Grade-based Banding & CTC'),
                    _buildDetailRow('Tax & Deductions', 'Standard Regulatory TDS'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return HrSectionCard(
      title: title,
      icon: icon,
      trailing: trailing,
      children: children,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return HrInfoRow(
      label: label,
      value: value,
    );
  }

  void _showPayrollOverview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payroll & Compensation',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Disbursement and tax structure',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text(
                'Compensation Overview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    HrInfoRow(
                      label: 'Disbursement Frequency',
                      value: 'Monthly (30 Days)',
                    ),
                    HrInfoRow(
                      label: 'Salary Structure',
                      value: 'Base + Allowances',
                    ),
                    HrInfoRow(
                      label: 'Currency',
                      value: 'INR (₹)',
                    ),
                    HrInfoRow(
                      label: 'Compliance & Tax Filing',
                      value: 'Standard Deductions',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Confidential employee disbursement audit is restricted to designated Payroll personnel.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EmploymentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.value.toLowerCase()) {
      'active' => Colors.green,
      'probation' => Colors.orange,
      'inactive' => Colors.grey,
      _ => Colors.blueGrey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
