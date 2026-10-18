import 'package:flutter/material.dart';
import '../../domain/entities/approval_action_type.dart';
import '../../domain/entities/approval_activity.dart';

/// Chronological audit trail showing all mutations, decisions, and comments on an [ApprovalRequest].
class ApprovalActivityTimeline extends StatelessWidget {
  final List<ApprovalActivity> activities;

  const ApprovalActivityTimeline({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No activity recorded yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      );
    }

    return Column(
      key: const Key('approval_activity_timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < activities.length; i++) ...[
          _buildActivityItem(
            context,
            activity: activities[i],
            isLast: i == activities.length - 1,
          ),
        ],
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required ApprovalActivity activity,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: _actionColor(activity.action).withValues(alpha: 0.15),
            child: Icon(
              _actionIcon(activity.action),
              size: 14,
              color: _actionColor(activity.action),
            ),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      activity.actorUserName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildActionBadge(activity.action),
                    Text(
                      _formatDateTime(activity.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (activity.comment != null &&
                    activity.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.comment!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(ApprovalActionType action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _actionColor(action).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        action.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _actionColor(action),
        ),
      ),
    );
  }

  IconData _actionIcon(ApprovalActionType action) {
    switch (action) {
      case ApprovalActionType.submitted:
        return Icons.send;
      case ApprovalActionType.approved:
        return Icons.check_circle;
      case ApprovalActionType.rejected:
        return Icons.cancel;
      case ApprovalActionType.revisionRequested:
        return Icons.replay;
      case ApprovalActionType.reassigned:
        return Icons.forward;
      case ApprovalActionType.cancelled:
        return Icons.block;
      case ApprovalActionType.commentAdded:
        return Icons.chat_bubble_outline;
    }
  }

  Color _actionColor(ApprovalActionType action) {
    switch (action) {
      case ApprovalActionType.submitted:
        return Colors.blue;
      case ApprovalActionType.approved:
        return Colors.green;
      case ApprovalActionType.rejected:
        return Colors.red;
      case ApprovalActionType.revisionRequested:
        return Colors.purple;
      case ApprovalActionType.reassigned:
        return Colors.orange;
      case ApprovalActionType.cancelled:
        return Colors.grey.shade700;
      case ApprovalActionType.commentAdded:
        return Colors.teal;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
