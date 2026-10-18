import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/domain/policies/crm_permissions.dart';
import '../../../dashboard/presentation/mappers/crm_module_presentation.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/policies/approvals_access_policy.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../../notifications/domain/services/notification_dispatcher.dart';
import '../../../purchase/domain/repositories/purchase_repository.dart';
import '../../../vendors/domain/repositories/vendor_repository.dart';
import '../cubit/approval_action_cubit.dart';
import '../cubit/approval_action_state.dart';
import '../cubit/approval_detail_cubit.dart';
import '../cubit/approval_detail_state.dart';
import '../widgets/approval_action_dialog.dart';
import '../widgets/approval_activity_timeline.dart';
import '../widgets/approval_step_stepper.dart';

/// Screen for in-depth inspection of an approval request, its steps, audit trail, and actions.
class ApprovalDetailScreen extends StatelessWidget {
  final String requestId;
  final CurrentUser user;
  final ApprovalRepository? repository;

  const ApprovalDetailScreen({
    super.key,
    required this.requestId,
    required this.user,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    ApprovalRepository? repo = repository;
    if (repo == null) {
      try {
        repo = context.read<ApprovalRepository>();
      } catch (_) {}
    }

    NotificationDispatcher? dispatcher;
    try {
      dispatcher = context.read<NotificationDispatcher>();
    } catch (_) {}

    PurchaseRepository? purchaseRepo;
    try {
      purchaseRepo = context.read<PurchaseRepository>();
    } catch (_) {}

    VendorRepository? vendorRepo;
    try {
      vendorRepo = context.read<VendorRepository>();
    } catch (_) {}

    final activeRepo = repo!;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ApprovalDetailCubit(activeRepo)..loadDetail(requestId),
        ),
        BlocProvider(
          create: (_) => ApprovalActionCubit(
            activeRepo,
            notificationDispatcher: dispatcher,
            purchaseRepository: purchaseRepo,
            vendorRepository: vendorRepo,
          ),
        ),
      ],
      child: _ApprovalDetailView(requestId: requestId, user: user),
    );
  }
}

class _ApprovalDetailView extends StatelessWidget {
  final String requestId;
  final CurrentUser user;

  const _ApprovalDetailView({required this.requestId, required this.user});

  void _showActionDialog(
    BuildContext context, {
    required ApprovalRequest request,
    required ApprovalActionType actionType,
  }) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ApprovalActionDialog(
          actionType: actionType,
          requestNumber: request.requestNumber,
          onConfirm: (comment) async {
            final actionCubit = context.read<ApprovalActionCubit>();
            switch (actionType) {
              case ApprovalActionType.approved:
                await actionCubit.approve(
                  requestId: request.id,
                  actor: user,
                  comment: comment,
                  request: request,
                );
              case ApprovalActionType.rejected:
                await actionCubit.reject(
                  requestId: request.id,
                  actor: user,
                  rejectionReason: comment ?? '',
                  request: request,
                );
              case ApprovalActionType.revisionRequested:
                await actionCubit.requestRevision(
                  requestId: request.id,
                  actor: user,
                  revisionNotes: comment ?? '',
                  request: request,
                );
              case ApprovalActionType.cancelled:
                await actionCubit.cancel(
                  requestId: request.id,
                  actor: user,
                  reason: comment,
                  request: request,
                );
              default:
                break;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<ApprovalActionCubit, ApprovalActionState>(
      listener: (context, actionState) {
        if (actionState is ApprovalActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(actionState.message),
              backgroundColor: Colors.green.shade800,
            ),
          );
          context.read<ApprovalDetailCubit>().refresh();
        } else if (actionState is ApprovalActionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(actionState.message),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      child: Scaffold(
        key: const Key('approval_detail_scaffold'),
        appBar: AppBar(
          title: const Text('Approval Details'),
          actions: [
            IconButton(
              key: const Key('approval_detail_refresh_btn'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh details',
              onPressed: () => context.read<ApprovalDetailCubit>().refresh(),
            ),
          ],
        ),
        body: BlocBuilder<ApprovalDetailCubit, ApprovalDetailState>(
          builder: (context, state) {
            if (state is ApprovalDetailLoading ||
                state is ApprovalDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ApprovalDetailFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
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
                        onPressed: () => context
                            .read<ApprovalDetailCubit>()
                            .loadDetail(requestId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state as ApprovalDetailLoaded;
            final request = loaded.request;

            final canDecide = ApprovalsAccessPolicy.canPerformDecision(
              user,
              request,
            );
            final canCancel = ApprovalsAccessPolicy.canCancelRequest(
              user,
              request,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeaderCard(context, request),
                      const SizedBox(height: 16),

                      // Multi-step workflow progress
                      _buildSectionCard(
                        context,
                        title: 'Workflow Approval Steps',
                        icon: Icons.alt_route,
                        child: ApprovalStepStepper(
                          steps: request.steps,
                          currentStepIndex: request.currentStepIndex,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata / entity reference details
                      if (request.metadata.isNotEmpty) ...[
                        _buildSectionCard(
                          context,
                          title: 'Originating Entity Context',
                          icon: Icons.data_object,
                          child: _buildMetadataView(context, request.metadata),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Audit activity log
                      _buildSectionCard(
                        context,
                        title: 'Audit Activity Timeline',
                        icon: Icons.history,
                        child: ApprovalActivityTimeline(
                          activities: loaded.auditTrail,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Governance Notice (when user cannot decide on an actionable request)
                      if (!canDecide && request.isActionable) ...[
                        _buildGovernanceNotice(context, request: request),
                        const SizedBox(height: 16),
                      ],

                      // Actions row (if actionable)
                      if (canDecide || canCancel) ...[
                        _buildActionToolbar(
                          context,
                          request: request,
                          canDecide: canDecide,
                          canCancel: canCancel,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ApprovalRequest request) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  request.requestNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPriorityChip(request.priority),
                    const SizedBox(width: 8),
                    _buildStatusChip(request.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.entityTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Metadata Grid
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _buildInfoItem(
                  context,
                  label: 'Module',
                  value: request.module.displayName,
                  icon: Icons.category_outlined,
                ),
                _buildInfoItem(
                  context,
                  label: 'Requester',
                  value: request.requesterName,
                  icon: Icons.person_outline,
                ),
                if (request.departmentName != null)
                  _buildInfoItem(
                    context,
                    label: 'Department',
                    value: request.departmentName!,
                    icon: Icons.business_outlined,
                  ),
                _buildInfoItem(
                  context,
                  label: 'Submitted',
                  value: _formatDateTime(request.submittedAt),
                  icon: Icons.calendar_today_outlined,
                ),
                if (request.amount != null)
                  _buildInfoItem(
                    context,
                    label: 'Amount',
                    value:
                        '${request.currencyCode ?? ''} ${request.amount!.toStringAsFixed(2)}'
                            .trim(),
                    icon: Icons.attach_money,
                  ),
                if (request.decidedAt != null)
                  _buildInfoItem(
                    context,
                    label: 'Decided At',
                    value: _formatDateTime(request.decidedAt!),
                    icon: Icons.event_available,
                  ),
                if (request.decidedByUserName != null)
                  _buildInfoItem(
                    context,
                    label: 'Decision By',
                    value: request.decidedByUserName!,
                    icon: Icons.verified_user_outlined,
                  ),
              ],
            ),

            if (request.decisionNotes != null &&
                request.decisionNotes!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decision Remarks:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.decisionNotes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataView(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        children: metadata.entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  entry.key,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionToolbar(
    BuildContext context, {
    required ApprovalRequest request,
    required bool canDecide,
    required bool canCancel,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (canDecide) ...[
                  FilledButton.icon(
                    key: const Key('approval_action_approve_btn'),
                    onPressed: () => _showActionDialog(
                      context,
                      request: request,
                      actionType: ApprovalActionType.approved,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('approval_action_reject_btn'),
                    onPressed: () => _showActionDialog(
                      context,
                      request: request,
                      actionType: ApprovalActionType.rejected,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const Key('approval_action_revision_btn'),
                    onPressed: () => _showActionDialog(
                      context,
                      request: request,
                      actionType: ApprovalActionType.revisionRequested,
                    ),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Request Revision'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 44),
                    ),
                  ),
                ],
                if (canCancel) ...[
                  OutlinedButton.icon(
                    key: const Key('approval_action_cancel_btn'),
                    onPressed: () => _showActionDialog(
                      context,
                      request: request,
                      actionType: ApprovalActionType.cancelled,
                    ),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Cancel Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      minimumSize: const Size(120, 44),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.outline),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(ApprovalPriority priority) {
    Color bg;
    Color fg;

    switch (priority) {
      case ApprovalPriority.urgent:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case ApprovalPriority.high:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
      case ApprovalPriority.normal:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
      case ApprovalPriority.low:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.displayName.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStatusChip(ApprovalStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case ApprovalStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case ApprovalStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case ApprovalStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case ApprovalStatus.revisionRequested:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade900;
      case ApprovalStatus.cancelled:
        bg = Colors.grey.shade300;
        fg = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildGovernanceNotice(BuildContext context, {required ApprovalRequest request}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final step = request.currentStep;

    String message;
    final isRequester = !user.isAdmin && request.requesterId == user.id;
    final isAssignedToOther = step != null &&
        step.assignedUserId != null &&
        step.assignedUserId != user.id;

    if (isRequester) {
      message = 'Maker-Checker Governance: You submitted this request. Originators cannot approve their own requests.';
    } else if (!user.hasPermission(CrmPermissions.approvalsAction)) {
      message = 'View-Only Access: Your user account does not have the "Approve or Reject Requests" permission.';
    } else if (isAssignedToOther) {
      final assigned = step.assignedUserName ?? step.assignedRole ?? step.assignedUserId;
      message = 'Step Routing: This workflow step is assigned to $assigned. Only the designated approver or an Administrator can take action.';
    } else {
      message = 'This request is awaiting action by an authorized approver.';
    }

    return Container(
      key: const Key('approval_detail_governance_notice'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
