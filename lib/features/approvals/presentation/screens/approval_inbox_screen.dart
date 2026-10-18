import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/repositories/approval_repository.dart';
import '../cubit/approval_inbox_cubit.dart';
import '../cubit/approval_inbox_state.dart';
import '../cubit/approval_inbox_tab.dart';
import '../widgets/approval_card.dart';
import '../widgets/approval_data_table.dart';
import '../widgets/approval_filter_bar.dart';
import 'approval_detail_screen.dart';

/// Responsive multi-tab Approval Inbox screen.
class ApprovalInboxScreen extends StatelessWidget {
  final CurrentUser user;
  final ApprovalRepository repository;
  final ValueChanged<ApprovalRequest>? onSelectRequest;

  const ApprovalInboxScreen({
    super.key,
    required this.user,
    required this.repository,
    this.onSelectRequest,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalInboxCubit(
        repository,
        currentUserId: user.id,
      )..loadApprovals(),
      child: _ApprovalInboxView(
        user: user,
        repository: repository,
        onSelectRequest: onSelectRequest,
      ),
    );
  }
}

class _ApprovalInboxView extends StatelessWidget {
  final CurrentUser user;
  final ApprovalRepository repository;
  final ValueChanged<ApprovalRequest>? onSelectRequest;

  const _ApprovalInboxView({
    required this.user,
    required this.repository,
    this.onSelectRequest,
  });

  void _navigateToDetail(BuildContext context, ApprovalRequest request) {
    if (onSelectRequest != null) {
      onSelectRequest!(request);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApprovalDetailScreen(
          requestId: request.id,
          user: user,
          repository: repository,
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<ApprovalInboxCubit>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalInboxCubit, ApprovalInboxState>(
      builder: (context, state) {
        final cubit = context.read<ApprovalInboxCubit>();

        return Column(
          key: const Key('approval_inbox_view'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs Bar
            _buildTabBar(context, state: state, cubit: cubit),

            // Search & Filter Bar
            if (state is ApprovalInboxLoaded)
              ApprovalFilterBar(
                searchQuery: state.searchQuery,
                onSearchChanged: cubit.setSearchQuery,
                selectedModule: state.selectedModule,
                onModuleChanged: cubit.setModuleFilter,
                selectedPriority: state.selectedPriority,
                onPriorityChanged: cubit.setPriorityFilter,
                onClearFilters: cubit.clearFilters,
              ),

            // Main Content Area
            Expanded(
              child: _buildBody(context, state: state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(
    BuildContext context, {
    required ApprovalInboxState state,
    required ApprovalInboxCubit cubit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedTab = state is ApprovalInboxLoaded
        ? state.selectedTab
        : ApprovalInboxTab.pending;

    final pendingCount = state is ApprovalInboxLoaded ? state.pendingCount : 0;
    final approvedCount = state is ApprovalInboxLoaded ? state.approvedCount : 0;
    final rejectedCount = state is ApprovalInboxLoaded ? state.rejectedCount : 0;
    final myCount = state is ApprovalInboxLoaded ? state.mySubmissionsCount : 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(
              context,
              tab: ApprovalInboxTab.pending,
              title: 'Pending Review',
              count: pendingCount,
              badgeColor: Colors.amber.shade700,
              isSelected: selectedTab == ApprovalInboxTab.pending,
              onTap: () => cubit.setTab(ApprovalInboxTab.pending),
            ),
            _buildTabButton(
              context,
              tab: ApprovalInboxTab.approved,
              title: 'Approved',
              count: approvedCount,
              badgeColor: Colors.green.shade700,
              isSelected: selectedTab == ApprovalInboxTab.approved,
              onTap: () => cubit.setTab(ApprovalInboxTab.approved),
            ),
            _buildTabButton(
              context,
              tab: ApprovalInboxTab.rejected,
              title: 'Rejected',
              count: rejectedCount,
              badgeColor: Colors.red.shade700,
              isSelected: selectedTab == ApprovalInboxTab.rejected,
              onTap: () => cubit.setTab(ApprovalInboxTab.rejected),
            ),
            _buildTabButton(
              context,
              tab: ApprovalInboxTab.mySubmissions,
              title: 'My Submissions',
              count: myCount,
              badgeColor: Colors.blue.shade700,
              isSelected: selectedTab == ApprovalInboxTab.mySubmissions,
              onTap: () => cubit.setTab(ApprovalInboxTab.mySubmissions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required ApprovalInboxTab tab,
    required String title,
    required int count,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      key: Key('approval_tab_${tab.name}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? badgeColor : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required ApprovalInboxState state}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is ApprovalInboxLoading || state is ApprovalInboxInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ApprovalInboxFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('approval_inbox_retry_btn'),
                onPressed: () => context.read<ApprovalInboxCubit>().loadApprovals(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final loaded = state as ApprovalInboxLoaded;
    final requests = loaded.filteredRequests;

    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.task_alt,
                size: 56,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 14),
              Text(
                'No approval requests in this view.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All workflow tasks for this criteria are up to date.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet = constraints.maxWidth >= 700;

        if (isDesktopOrTablet) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ApprovalDataTable(
              requests: requests,
              onSelectRequest: (r) => _navigateToDetail(context, r),
            ),
          );
        }

        return ListView.builder(
          key: const Key('approval_inbox_card_list'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return ApprovalCard(
              request: request,
              onTap: () => _navigateToDetail(context, request),
            );
          },
        );
      },
    );
  }
}
