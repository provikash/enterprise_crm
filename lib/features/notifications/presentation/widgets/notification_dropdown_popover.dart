import 'package:flutter/material.dart';
import '../../../../features/approvals/domain/repositories/approval_repository.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_priority.dart';
import '../cubit/notification_cubit.dart';
import '../navigation/deep_link_navigation_resolver.dart';
import '../screens/notification_center_screen.dart';

/// Interactive dropdown popover or bottom sheet content presenting recent notifications.
class NotificationDropdownPopover extends StatelessWidget {
  final List<CrmNotification> notifications;
  final int unreadCount;
  final CurrentUser user;
  final NotificationCubit cubit;
  final ApprovalRepository? approvalRepository;
  final VoidCallback? onClose;

  const NotificationDropdownPopover({
    super.key,
    required this.notifications,
    required this.unreadCount,
    required this.user,
    required this.cubit,
    this.approvalRepository,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentItems = notifications.take(5).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Popover Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Notifications',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(
                      key: const Key('notification_popover_mark_all_read'),
                      onPressed: () {
                        cubit.markAllAsRead(user.id);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Mark all read', style: TextStyle(fontSize: 11)),
                    ),
                  if (onClose != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Close',
                      onPressed: onClose,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Notification List or Empty State
            if (recentItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 40,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: recentItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = recentItems[index];
                    return _buildNotificationTile(context, item);
                  },
                ),
              ),

            const Divider(height: 1),
            // Footer: View All
            InkWell(
              key: const Key('notification_popover_view_all_button'),
              onTap: () {
                onClose?.call();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificationCenterScreen(
                      user: user,
                      cubit: cubit,
                      approvalRepository: approvalRepository,
                    ),
                  ),
                );
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'View all in Notification Center',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, CrmNotification item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !item.isRead;

    return InkWell(
      key: Key('notification_tile_${item.id}'),
      onTap: () {
        if (isUnread) {
          cubit.markAsRead(notificationId: item.id, userId: user.id);
        }
        onClose?.call();
        DeepLinkNavigationResolver.resolve(
          context,
          notification: item,
          user: user,
          approvalRepository: approvalRepository,
        );
      },
      child: Container(
        color: isUnread
            ? colorScheme.primaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority icon badge
            _buildPriorityIcon(item.priority),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRelativeTime(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(NotificationPriority priority) {
    Color color;
    IconData icon;

    switch (priority) {
      case NotificationPriority.critical:
        color = Colors.red.shade700;
        icon = Icons.error_outline;
      case NotificationPriority.warning:
        color = Colors.amber.shade800;
        icon = Icons.warning_amber_rounded;
      case NotificationPriority.success:
        color = Colors.green.shade700;
        icon = Icons.check_circle_outline;
      case NotificationPriority.info:
        color = Colors.blue.shade700;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }
}
