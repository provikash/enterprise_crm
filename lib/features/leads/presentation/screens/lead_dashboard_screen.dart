import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/lead_export_file_saver.dart';
import '../../domain/entities/lead_query.dart';
import '../../domain/entities/lead_source.dart';
import '../../domain/repositories/lead_repository.dart';
import '../bloc/lead_dashboard_cubit.dart';
import '../bloc/lead_dashboard_state.dart';
import '../services/lead_import_file_picker.dart';
import '../widgets/inbound_lead_simulator_dialog.dart';
import '../widgets/lead_export_dialog.dart';
import '../widgets/lead_quick_action.dart';
import '../widgets/lead_summary_card.dart';
import 'lead_import_workflow_screen.dart';
import 'lead_list_screen.dart';

class LeadDashboardScreen extends StatelessWidget {
  final LeadDashboardCubit? cubit;
  final LeadRepository? repository;
  final void Function(LeadQuery query)? onNavigateToLeads;
  final VoidCallback? onAddLead;
  final VoidCallback? onImportLeads;
  final VoidCallback? onDistributeLeads;
  final VoidCallback? onExportLeads;
  final VoidCallback? onSimulateLead;
  final LeadImportFilePicker? filePicker;
  final LeadExportFileSaver? fileSaver;
  final VoidCallback? onLogout;

  const LeadDashboardScreen({
    super.key,
    this.cubit,
    this.repository,
    this.onNavigateToLeads,
    this.onAddLead,
    this.onImportLeads,
    this.onDistributeLeads,
    this.onExportLeads,
    this.onSimulateLead,
    this.filePicker,
    this.fileSaver,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LeadDashboardView(
          onNavigateToLeads: onNavigateToLeads,
          onAddLead: onAddLead,
          onImportLeads: onImportLeads,
          onDistributeLeads: onDistributeLeads,
          onExportLeads: onExportLeads,
          onSimulateLead: onSimulateLead,
          repository: repository,
          filePicker: filePicker,
          fileSaver: fileSaver,
          onLogout: onLogout,
        ),
      );
    }

    if (repository != null) {
      return BlocProvider(
        create: (_) => LeadDashboardCubit(repository!)..loadDashboard(),
        child: _LeadDashboardView(
          onNavigateToLeads: onNavigateToLeads,
          onAddLead: onAddLead,
          onImportLeads: onImportLeads,
          onDistributeLeads: onDistributeLeads,
          onExportLeads: onExportLeads,
          onSimulateLead: onSimulateLead,
          repository: repository,
          filePicker: filePicker,
          fileSaver: fileSaver,
          onLogout: onLogout,
        ),
      );
    }

    // Attempt to use already provided Cubit from ancestor context
    return _LeadDashboardView(
      onNavigateToLeads: onNavigateToLeads,
      onAddLead: onAddLead,
      onImportLeads: onImportLeads,
      onDistributeLeads: onDistributeLeads,
      onExportLeads: onExportLeads,
      onSimulateLead: onSimulateLead,
      repository: repository,
      filePicker: filePicker,
      fileSaver: fileSaver,
      onLogout: onLogout,
    );
  }
}

class _LeadDashboardView extends StatelessWidget {
  final void Function(LeadQuery query)? onNavigateToLeads;
  final VoidCallback? onAddLead;
  final VoidCallback? onImportLeads;
  final VoidCallback? onDistributeLeads;
  final VoidCallback? onExportLeads;
  final VoidCallback? onSimulateLead;
  final LeadRepository? repository;
  final LeadImportFilePicker? filePicker;
  final LeadExportFileSaver? fileSaver;
  final VoidCallback? onLogout;

  const _LeadDashboardView({
    this.onNavigateToLeads,
    this.onAddLead,
    this.onImportLeads,
    this.onDistributeLeads,
    this.onExportLeads,
    this.onSimulateLead,
    this.repository,
    this.filePicker,
    this.fileSaver,
    this.onLogout,
  });

  void _showComingSoon(BuildContext context, String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName will be connected in upcoming phases.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openLeadList(BuildContext context, LeadQuery query) async {
    if (onNavigateToLeads != null) {
      onNavigateToLeads!(query);
      return;
    }
    LeadRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<LeadRepository>();
      } catch (_) {}
    }
    if (repo == null) {
      _showComingSoon(context, 'View Leads');
      return;
    }

    final dashboardCubit = context.read<LeadDashboardCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeadListScreen(
          repository: repo,
          initialQuery: query,
          filePicker: filePicker,
          exportFileSaver: fileSaver,
        ),
      ),
    );
    if (context.mounted) {
      dashboardCubit.loadDashboard();
    }
  }

  Future<void> _openImportWorkflow(BuildContext context) async {
    LeadRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<LeadRepository>();
      } catch (_) {}
    }
    if (repo == null) {
      _showComingSoon(context, 'Import Leads');
      return;
    }

    final dashboardCubit = context.read<LeadDashboardCubit>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LeadImportWorkflowScreen(repository: repo!, filePicker: filePicker),
      ),
    );
    if (result == true && context.mounted) {
      dashboardCubit.loadDashboard();
    }
  }

  Future<void> _openDistributeLeads(BuildContext context) async {
    LeadRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<LeadRepository>();
      } catch (_) {}
    }
    if (repo == null) {
      _showComingSoon(context, 'Distribute Leads');
      return;
    }

    final dashboardCubit = context.read<LeadDashboardCubit>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LeadListScreen(repository: repo, isDistributionMode: true),
      ),
    );
    if (result == true && context.mounted) {
      dashboardCubit.loadDashboard();
    }
  }

  Future<void> _openExportDialog(BuildContext context) async {
    LeadRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<LeadRepository>();
      } catch (_) {}
    }
    if (repo == null) {
      _showComingSoon(context, 'Export Leads');
      return;
    }

    LeadExportFileSaver? saver = fileSaver;
    if (saver == null) {
      try {
        saver = context.read<LeadExportFileSaver>();
      } catch (_) {}
    }
    saver ??= const DefaultLeadExportFileSaver();

    final result = await showLeadExportDialog(
      context: context,
      repository: repo,
      fileSaver: saver,
      query: const LeadQuery(),
      contextExplanation: 'All Leads will be exported.',
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lead export saved.')));
    }
  }

  Future<void> _openSimulator(BuildContext context) async {
    if (onSimulateLead != null) {
      onSimulateLead!();
      return;
    }
    LeadRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<LeadRepository>();
      } catch (_) {}
    }
    if (repo == null) {
      _showComingSoon(context, 'Simulate Inbound Lead');
      return;
    }

    final dashboardCubit = context.read<LeadDashboardCubit>();
    final lead = await InboundLeadSimulatorDialog.show(
      context,
      repository: repo,
    );
    if (lead != null && context.mounted) {
      dashboardCubit.loadDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lead #${lead.id} created from external ingestion!'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: () {
              context.read<LeadDashboardCubit>().loadDashboard();
            },
          ),
          if (onLogout != null)
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.0,
                child: IconButton(
                  key: const Key('shell_logout_button'),
                  icon: const Icon(Icons.logout, size: 1),
                  onPressed: onLogout,
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<LeadDashboardCubit, LeadDashboardState>(
        builder: (context, state) {
          return switch (state) {
            LeadDashboardInitial() => const Center(
              child: CircularProgressIndicator(),
            ),
            LeadDashboardLoading() => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading lead summary...'),
                ],
              ),
            ),
            LeadDashboardEmpty() => _buildEmptyState(context, theme),
            LeadDashboardFailure(:final message) => _buildFailureState(
              context,
              theme,
              message,
            ),
            LeadDashboardLoaded(:final metrics) => _buildLoadedDashboard(
              context,
              theme,
              metrics,
            ),
          };
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No leads yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a lead manually or import leads from Excel/CSV.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed:
                      onAddLead ?? () => _showComingSoon(context, 'Add Lead'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lead'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      onImportLeads ?? () => _openImportWorkflow(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Leads'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.read<LeadDashboardCubit>().loadDashboard();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedDashboard(
    BuildContext context,
    ThemeData theme,
    LeadSummaryMetrics metrics,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 800;
        final columns = isMobile
            ? 2
            : isTablet
            ? 3
            : 4;
        final childAspectRatio = constraints.maxWidth < 360
            ? 1.15
            : isMobile
            ? 1.3
            : isTablet
            ? 1.35
            : 1.5;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Overview & Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time distribution of leads and intake channels',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Summary Cards Grid
              GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: [
                  LeadSummaryCard(
                    key: const Key('dashboard_card_total_leads'),
                    title: 'Total Leads',
                    count: metrics.totalLeads,
                    icon: Icons.people_alt_outlined,
                    accentColor: theme.colorScheme.primary,
                    onTap: () => _openLeadList(context, const LeadQuery()),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_assigned_leads'),
                    title: 'Assigned Leads',
                    count: metrics.assignedLeads,
                    icon: Icons.assignment_ind_outlined,
                    accentColor: Colors.teal,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(isAssigned: true),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_unassigned_leads'),
                    title: 'Unassigned Leads',
                    count: metrics.unassignedLeads,
                    icon: Icons.person_add_disabled_outlined,
                    accentColor: Colors.deepOrange,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(isAssigned: false),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_manual_leads'),
                    title: 'Manual Leads',
                    count: metrics.manualLeads,
                    icon: Icons.edit_note_outlined,
                    accentColor: Colors.purple,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(source: LeadSource.manual),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_excel_leads'),
                    title: 'Excel Leads',
                    count: metrics.excelLeads,
                    icon: Icons.table_chart_outlined,
                    accentColor: Colors.green,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(source: LeadSource.excel),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_csv_leads'),
                    title: 'CSV Leads',
                    count: metrics.csvLeads,
                    icon: Icons.insert_drive_file_outlined,
                    accentColor: Colors.blue,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(source: LeadSource.csv),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_portal_leads'),
                    title: 'Portal Leads',
                    count: metrics.portalLeads,
                    icon: Icons.language_outlined,
                    accentColor: Colors.teal,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(source: LeadSource.portal),
                    ),
                  ),
                  LeadSummaryCard(
                    key: const Key('dashboard_card_meta_leads'),
                    title: 'Meta Leads',
                    count: metrics.metaCampaignLeads,
                    icon: Icons.campaign_outlined,
                    accentColor: Colors.indigo,
                    onTap: () => _openLeadList(
                      context,
                      const LeadQuery(source: LeadSource.metaCampaign),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  LeadQuickAction(
                    key: const Key('quick_action_add_lead'),
                    label: 'Add Lead',
                    icon: Icons.add_outlined,
                    onPressed:
                        onAddLead ?? () => _showComingSoon(context, 'Add Lead'),
                  ),
                  LeadQuickAction(
                    key: const Key('quick_action_import_leads'),
                    label: 'Import Leads',
                    icon: Icons.upload_file_outlined,
                    onPressed:
                        onImportLeads ?? () => _openImportWorkflow(context),
                  ),
                  LeadQuickAction(
                    key: const Key('quick_action_simulate_lead'),
                    label: 'Simulate Inbound',
                    icon: Icons.hub_outlined,
                    onPressed: () => _openSimulator(context),
                  ),
                  LeadQuickAction(
                    key: const Key('quick_action_distribute_leads'),
                    label: 'Distribute Leads',
                    icon: Icons.alt_route_outlined,
                    onPressed:
                        onDistributeLeads ??
                        () => _openDistributeLeads(context),
                  ),
                  LeadQuickAction(
                    key: const Key('quick_action_export_leads'),
                    label: 'Export Leads',
                    icon: Icons.download_outlined,
                    onPressed:
                        onExportLeads ?? () => _openExportDialog(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
