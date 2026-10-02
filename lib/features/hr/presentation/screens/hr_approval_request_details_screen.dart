import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/presentation/screens/access_restricted_screen.dart';
import '../../domain/entities/hr_approval_history_entry.dart';
import '../../domain/entities/hr_approval_request.dart';
import '../../domain/policies/hr_access_policy.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../bloc/hr_approval_decision_cubit.dart';
import '../bloc/hr_approval_decision_state.dart';
import '../widgets/hr_approval_status_badge.dart';

/// Details screen for an individual HR approval request.
///
/// Features (HR-9.5):
/// - Route protected by [HrAccessPolicy.canAccessModule].
/// - Displays complete approved domain and target entity metadata.
/// - Authorized decision actions (Approve, Reject) for administrators on pending requests.
/// - Cancellation action for original requester or administrator.
/// - Chronological audit history trail rendering.
/// - Responsive card layouts across Android mobile and desktop Web.
class HrApprovalRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final CurrentUser user;
  final HrApprovalRepository repository;
  final HrApprovalRequest? initialRequest;

  const HrApprovalRequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.user,
    required this.repository,
    this.initialRequest,
  });

  @override
  State<HrApprovalRequestDetailsScreen> createState() =>
      _HrApprovalRequestDetailsScreenState();
}

class _HrApprovalRequestDetailsScreenState
    extends State<HrApprovalRequestDetailsScreen> {
  late final HrApprovalDecisionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = HrApprovalDecisionCubit(
      repository: widget.repository,
      actor: widget.user,
      requestId: widget.requestId,
      initialRequest: widget.initialRequest,
    );
    _cubit.loadDetails();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Route guard
    if (!HrAccessPolicy.canAccessModule(widget.user)) {
      return const AccessRestrictedScreen();
    }

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<HrApprovalDecisionCubit, HrApprovalDecisionState>(
        listener: (context, state) {
          if (state is HrApprovalDecisionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const Key('hr_approval_decision_success_snackBar'),
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is HrApprovalDecisionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const Key('hr_approval_decision_error_snackBar'),
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            key: const Key('hr_approval_details_scaffold'),
            appBar: AppBar(
              title: Text('Request ${widget.requestId}'),
              actions: [
                IconButton(
                  key: const Key('hr_approval_details_refresh_button'),
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _cubit.loadDetails(),
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HrApprovalDecisionState state) {
    if (state is HrApprovalDecisionLoading && _cubit.currentRequest == null) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('hr_approval_details_loading'),
        ),
      );
    }

    if (state is HrApprovalDecisionFailure && _cubit.currentRequest == null) {
      if (state.message.contains('not found')) {
        return const Center(
          key: Key('hr_approval_details_not_found'),
          child: Text(
            'Approval request not found.',
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      return Center(
        key: const Key('hr_approval_details_error'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => _cubit.loadDetails(),
              ),
            ],
          ),
        ),
      );
    }

    final req = state is HrApprovalDecisionReady
        ? state.request
        : (state is HrApprovalDecisionSuccess
            ? state.request
            : _cubit.currentRequest);

    if (req == null) {
      return const Center(
        key: Key('hr_approval_details_not_found'),
        child: Text(
          'Approval request not found.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final history = state is HrApprovalDecisionReady
        ? state.history
        : (state is HrApprovalDecisionSuccess
            ? state.history
            : const <HrApprovalHistoryEntry>[]);

    final canDecide = state is HrApprovalDecisionReady
        ? state.canDecide
        : (widget.user.isAdmin && req.status.isPending);
    final canCancel = state is HrApprovalDecisionReady
        ? state.canCancel
        : (req.status.isPending &&
            (widget.user.isAdmin || widget.user.id == req.requesterId));
    final isSubmitting = state is HrApprovalDecisionSubmitting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        final maxWidth = isDesktop ? 700.0 : double.infinity;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, req),
                  const SizedBox(height: 12),
                  _buildWorkflowCard(context, req),
                  const SizedBox(height: 12),
                  _buildTargetCard(context, req),
                  const SizedBox(height: 12),
                  _buildRequesterCard(context, req),
                  if (req.remarks != null && req.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildRemarksCard(context, req),
                  ],
                  const SizedBox(height: 12),
                  _buildDecisionActionsCard(
                    context,
                    req,
                    canDecide: canDecide,
                    canCancel: canCancel,
                    isSubmitting: isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryCard(context, history),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_header_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.id,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req.workflowType.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            HrApprovalStatusBadge(status: req.status),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Workflow Type', req.workflowType.displayName),
            const SizedBox(height: 8),
            _buildDetailRow('Identifier', req.workflowType.identifier),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_target_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Entity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Target Module', req.target.targetModule.name),
            const SizedBox(height: 8),
            _buildDetailRow('Entity Type', req.target.targetEntityType),
            const SizedBox(height: 8),
            _buildDetailRow('Entity ID', req.target.targetEntityId),
          ],
        ),
      ),
    );
  }

  Widget _buildRequesterCard(BuildContext context, HrApprovalRequest req) {
    final createdStr =
        req.createdAt.toIso8601String().replaceFirst('T', ' ').split('.').first;
    final updatedStr = req.updatedAt
        ?.toIso8601String()
        .replaceFirst('T', ' ')
        .split('.')
        .first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission & Audit Metadata',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Requester User ID', req.requesterId),
            const SizedBox(height: 8),
            _buildDetailRow('Submitted At (UTC)', createdStr),
            if (updatedStr != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Updated At (UTC)', updatedStr),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context, HrApprovalRequest req) {
    return Card(
      key: const Key('hr_approval_details_remarks_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission Remarks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              req.remarks!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionActionsCard(
    BuildContext context,
    HrApprovalRequest req, {
    required bool canDecide,
    required bool canCancel,
    required bool isSubmitting,
  }) {
    if (!canDecide && !canCancel && req.status.isTerminal) {
      return Card(
        key: const Key('hr_approval_details_terminal_card'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'This request is in terminal status "${req.status.displayName}". No further actions are available.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (!canDecide && !canCancel) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const Key('hr_approval_details_decision_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decision Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(
                    key: Key('hr_approval_decision_submitting_indicator'),
                  ),
                ),
              )
            else ...[
              if (canDecide) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('hr_approval_approve_button'),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showApproveDialog(context),
                    ),
                    OutlinedButton.icon(
                      key: const Key('hr_approval_reject_button'),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                      ),
                      onPressed: () => _showRejectDialog(context),
                    ),
                  ],
                ),
              ],
              if (canCancel) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('hr_approval_cancel_button'),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('Cancel Request'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  onPressed: () => _showCancelDialog(context),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this request?'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('hr_approval_decision_reason_field'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Remarks / Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('hr_approval_confirm_decision_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _cubit.approve(reason: reasonController.text);
            },
            child: const Text('Confirm Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this request:'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('hr_approval_decision_reason_field'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('hr_approval_confirm_decision_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _cubit.reject(reason: reasonController.text);
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Approval Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this pending request?'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('hr_approval_decision_reason_field'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            key: const Key('hr_approval_confirm_cancel_button'),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _cubit.cancel(reason: reasonController.text);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    List<HrApprovalHistoryEntry> history,
  ) {
    return Card(
      key: const Key('hr_approval_details_history_card'),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decision & Audit History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No audit history recorded.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int index = 0; index < history.length; index++) ...[
                    if (index > 0) const Divider(height: 16),
                    _buildHistoryItem(context, history[index]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, HrApprovalHistoryEntry entry) {
    final timeStr = entry.timestamp
        .toIso8601String()
        .replaceFirst('T', ' ')
        .split('.')
        .first;

    IconData icon;
    Color color;
    switch (entry.action) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'cancelled':
        icon = Icons.block;
        color = Colors.orange;
        break;
      case 'submitted':
      default:
        icon = Icons.send;
        color = Colors.blue;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.action.toUpperCase()} by ${entry.actorId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                entry.previousStatus != null
                    ? 'Status: ${entry.previousStatus!.label} -> ${entry.newStatus.label}'
                    : 'Status: ${entry.newStatus.label}',
                style: const TextStyle(fontSize: 12),
              ),
              if (entry.reason != null && entry.reason!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Reason: ${entry.reason}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
