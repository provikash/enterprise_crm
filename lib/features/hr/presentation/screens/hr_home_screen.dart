import 'package:flutter/material.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../data/repositories/mock_attendance_repository.dart';
import '../../data/repositories/mock_employee_kpi_repository.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_document_repository.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../widgets/hr_feature_card.dart';
import '../widgets/hr_page_header.dart';
import '../widgets/hr_responsive_grid.dart';
import '../widgets/hr_section_card.dart';
import 'attendance_home_screen.dart';
import 'employee_directory_screen.dart';
import 'employee_kpi_list_screen.dart';

/// Central HR & Payroll Module Dashboard / Main Feature Grid screen.
///
/// Implements the enterprise interaction model:
/// HR / Payroll → Main Feature Grid → Feature-Specific Grid / Overview → Detailed View
class HrHomeScreen extends StatelessWidget {
  final CurrentUser user;
  final EmployeeRepository repository;
  final EmployeeDocumentRepository? documentRepository;
  final AttendanceRepository? attendanceRepository;
  final EmployeeKpiRepository? kpiRepository;

  const HrHomeScreen({
    super.key,
    required this.user,
    required this.repository,
    this.documentRepository,
    this.attendanceRepository,
    this.kpiRepository,
  });

  @override
  Widget build(BuildContext context) {
    // Route guard: Access restricted if not authorized for HR module or records
    if (!HrAccessPolicy.canAccessModule(user)) {
      return const AccessRestrictedScreen();
    }

    if (!user.isAdmin && !HrAccessPolicy.canViewHrRecords(user)) {
      return const AccessRestrictedScreen();
    }

    return Scaffold(
      key: const Key('hr_home_scaffold'),
      appBar: AppBar(title: const Text('Human Resources')),
      body: SingleChildScrollView(
        key: const Key('hr_home_scroll_view'),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HrPageHeader(
                  title: 'HR & Payroll Management',
                  subtitle:
                      'Manage employee directory, daily attendance, performance metrics, and payroll records.',
                  tag: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Enterprise Module',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMainGrid(context),
                const SizedBox(height: 24),
                _buildQuickOverview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid(BuildContext context) {
    final canViewPayroll = HrAccessPolicy.canViewPayroll(user);

    return HrResponsiveGrid(
      key: const Key('hr_main_feature_grid'),
      spacing: 16,
      runSpacing: 16,
      children: [
        HrFeatureCard(
          key: const Key('hr_feature_card_employees'),
          title: 'Employees',
          description: 'Employee directory, profiles, roles, and status',
          icon: Icons.people_outline,
          metric: 'Directory & Profiles',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeDirectoryScreen(
                  user: user,
                  repository: repository,
                  documentRepository: documentRepository,
                  attendanceRepository: attendanceRepository,
                  kpiRepository: kpiRepository,
                ),
              ),
            );
          },
        ),
        HrFeatureCard(
          key: const Key('hr_feature_card_attendance'),
          title: 'Attendance',
          description: 'Daily logs, check-in/out, calendar & history',
          icon: Icons.calendar_month_outlined,
          metric: 'Logs & Calendar',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttendanceHomeScreen(
                  user: user,
                  repository:
                      attendanceRepository ?? MockAttendanceRepository(),
                ),
              ),
            );
          },
        ),
        HrFeatureCard(
          key: const Key('hr_feature_card_kpi'),
          title: 'Performance (KPI)',
          description: 'Quarterly goals, target tracking, and evaluations',
          icon: Icons.assessment_outlined,
          metric: 'Goals & Appraisals',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeKpiListScreen(
                  user: user,
                  kpiRepository: kpiRepository ?? MockEmployeeKpiRepository(),
                  employeeRepository: repository,
                ),
              ),
            );
          },
        ),
        HrFeatureCard(
          key: const Key('hr_feature_card_documents'),
          title: 'Documents',
          description: 'Agreements, identity verification & compliance',
          icon: Icons.folder_shared_outlined,
          metric: 'Files & Compliance',
          onTap: () {
            // Opens Employee Directory where user can select employee to view documents
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeDirectoryScreen(
                  user: user,
                  repository: repository,
                  documentRepository: documentRepository,
                  attendanceRepository: attendanceRepository,
                  kpiRepository: kpiRepository,
                ),
              ),
            );
          },
        ),
        if (canViewPayroll)
          HrFeatureCard(
            key: const Key('hr_feature_card_payroll'),
            title: 'Payroll',
            description: 'Compensation structures, disbursement & tax details',
            icon: Icons.payments_outlined,
            metric: 'Compensation Structure',
            badge: 'Authorized',
            onTap: () => _showPayrollOverview(context),
          ),
      ],
    );
  }

  Widget _buildQuickOverview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HrSectionCard(
      title: 'Module Capabilities & Operational Scope',
      icon: Icons.info_outline,
      children: [
        Text(
          'The HR & Payroll module provides end-to-end workforce lifecycle management. Access permissions are strictly managed by your assigned CRM role.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildCapabilityChip(
              context,
              'Workforce Directory',
              Icons.badge_outlined,
            ),
            _buildCapabilityChip(
              context,
              'Punch Regularization',
              Icons.access_time_outlined,
            ),
            _buildCapabilityChip(
              context,
              'Goal Appraisals',
              Icons.trending_up_outlined,
            ),
            _buildCapabilityChip(
              context,
              'Document Storage',
              Icons.file_present_outlined,
            ),
            if (HrAccessPolicy.canViewPayroll(user))
              _buildCapabilityChip(
                context,
                'Payroll Audit',
                Icons.account_balance_wallet_outlined,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapabilityChip(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                          'Enterprise Salary Summary & Policy',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Disbursement Frequency',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Monthly (30 Days)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Salary Structure',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Base + Allowances',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Currency',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INR (₹)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Compliance & Tax Filing',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Standard Deductions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Individual salary details and payslips are linked to employee profiles and confidential self-service records.',
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
