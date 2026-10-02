import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../bloc/pending_approvals_cubit.dart';
import '../bloc/pending_approvals_state.dart';
import '../widgets/hr_approval_status_badge.dart';
import 'hr_approval_request_details_screen.dart';
import 'hr_approval_request_screen.dart';

/// Screen displaying approval workflows within the HR module.
///
/// Features:
/// - Switchable views between "Pending Approvals" (actionable queue) and "My Requests" (submitted by user).
/// - Submission of new approval requests via [HrApprovalRequestScreen].
/// - Read-only inspection of request details via [HrApprovalRequestDetailsScreen].
/// - Strictly NO approve/reject mutations in HR-9.4 (reserved for HR-9.5).
class PendingApprovalsScreen extends StatefulWidget {
  final CurrentUser user;
  final HrApprovalRepository repository;

  const PendingApprovalsScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  late final PendingApprovalsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PendingApprovalsCubit(repository: widget.repository);
    _cubit.loadPendingApprovals(user: widget.user);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onFilterChanged(PendingApprovalsFilterMode mode) {
    _cubit.switchMode(mode, user: widget.user);
  }

  Future<void> _openNewRequestScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HrApprovalRequestScreen(
          user: widget.user,
          repository: widget.repository,
        ),
      ),
    );

    if (mounted && result != false) {
      _cubit.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Route guard
    if (!HrAccessPolicy.canAccessModule(widget.user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        key: const Key('pending_approvals_scaffold'),
        appBar: AppBar(
          title: const Text('Approvals & Requests'),
          actions: [
            IconButton(
              key: const Key('pending_approvals_refresh_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _cubit.refresh(),
            ),
            IconButton(
              key: const Key('pending_approvals_new_request_button'),
              icon: const Icon(Icons.add_task),
              tooltip: 'New Request',
              onPressed: _openNewRequestScreen,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter mode selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: BlocBuilder<PendingApprovalsCubit, PendingApprovalsState>(
                    buildWhen: (prev, curr) => prev.mode != curr.mode,
                    builder: (context, state) {
                      return SegmentedButton<PendingApprovalsFilterMode>(
                        segments: const [
                          ButtonSegment<PendingApprovalsFilterMode>(
                            value: PendingApprovalsFilterMode.pending,
                            label: Text('Pending Approvals'),
                            icon: Icon(Icons.pending_actions),
                          ),
                          ButtonSegment<PendingApprovalsFilterMode>(
                            value: PendingApprovalsFilterMode.myRequests,
                            label: Text('My Requests'),
                            icon: Icon(Icons.outbox),
                          ),
                        ],
                        selected: {state.mode},
                        onSelectionChanged: (selection) {
                          _onFilterChanged(selection.first);
                        },
                      );
                    },
                  ),
                ),

                // Main content
                Expanded(
                  child: BlocBuilder<PendingApprovalsCubit,
                      PendingApprovalsState>(
                    builder: (context, state) {
                      return switch (state) {
                        PendingApprovalsInitial() ||
                        PendingApprovalsLoading() =>
                          const Center(
                            child: CircularProgressIndicator(
                              key: Key('pending_approvals_loading_indicator'),
                            ),
                          ),
                        PendingApprovalsFailure(:final message) =>
                          _buildErrorView(context, message),
                        PendingApprovalsEmpty(:final mode) =>
                          _buildEmptyView(context, mode),
                        PendingApprovalsLoaded(:final requests) =>
                          _buildListView(context, requests),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(
      BuildContext context, PendingApprovalsFilterMode filterMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending =
        filterMode == PendingApprovalsFilterMode.pending;

    return Center(
      key: const Key('pending_approvals_empty_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.done_all : Icons.inbox,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isPending
                  ? 'No Pending Approval Requests'
                  : 'No Requests Submitted Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'All requests requiring your authorization have been processed.'
                  : 'You have not submitted any approval requests in this session.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openNewRequestScreen,
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      key: const Key('pending_approvals_error_view'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              'Failed to Load Requests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('pending_approvals_retry_button'),
              onPressed: () => _cubit.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
      BuildContext context, List<HrApprovalRequest> requests) {
    return ListView.separated(
      key: const Key('pending_approvals_list'),
      padding: const EdgeInsets.all(16.0),
      itemCount: requests.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(context, request);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, HrApprovalRequest request) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormatted =
        '${request.createdAt.year}-${request.createdAt.month.toString().padLeft(2, '0')}-${request.createdAt.day.toString().padLeft(2, '0')} ${request.createdAt.hour.toString().padLeft(2, '0')}:${request.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      key: Key('approval_request_card_${request.id}'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HrApprovalRequestDetailsScreen(
                requestId: request.id,
                initialRequest: request,
                user: widget.user,
                repository: widget.repository,
              ),
            ),
          );
        },
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
                      request.workflowType.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  HrApprovalStatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.target.targetEntityType} #${request.target.targetEntityId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Requester: ${request.requesterId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${request.id}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Text(
                    dateFormatted,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
