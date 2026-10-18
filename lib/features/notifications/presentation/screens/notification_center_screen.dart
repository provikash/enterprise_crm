import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/approvals/domain/repositories/approval_repository.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/entities/notification_priority.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../navigation/deep_link_navigation_resolver.dart';

/// Full-page workspace for inspecting, filtering, and managing notifications.
class NotificationCenterScreen extends StatefulWidget {
  final CurrentUser user;
  final NotificationCubit cubit;
  final ApprovalRepository? approvalRepository;

  const NotificationCenterScreen({
    super.key,
    required this.user,
    required this.cubit,
    this.approvalRepository,
  });

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationCategory? _selectedCategory;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit.state is NotificationInitial) {
      widget.cubit.watchNotifications(widget.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<NotificationCubit, NotificationState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final List<CrmNotification> allNotifications;
        final int unreadCount;

        if (state is NotificationLoaded) {
          allNotifications = state.notifications;
          unreadCount = state.unreadCount;
        } else {
          allNotifications = const [];
          unreadCount = 0;
        }

        final filteredNotifications = allNotifications.where((n) {
          if (_selectedCategory != null && n.category != _selectedCategory) {
            return false;
          }
          if (_unreadOnly && n.isRead) {
            return false;
          }
          return true;
        }).toList();

        return Scaffold(
          key: const Key('notification_center_scaffold'),
          appBar: AppBar(
            title: const Text('Notification Center'),
            actions: [
              if (unreadCount > 0)
                Builder(
                  builder: (context) {
                    final isNarrow = MediaQuery.of(context).size.width < 450;
                    if (isNarrow) {
                      return IconButton(
                        key: const Key('notification_center_mark_all_read_button'),
                        icon: const Icon(Icons.done_all),
                        tooltip: 'Mark all read',
                        onPressed: () {
                          widget.cubit.markAllAsRead(widget.user.id);
                        },
                      );
                    }
                    return TextButton.icon(
                      key: const Key('notification_center_mark_all_read_button'),
                      onPressed: () {
                        widget.cubit.markAllAsRead(widget.user.id);
                      },
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all read'),
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter controls
                _buildFilterControls(context),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: state is NotificationLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredNotifications.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: filteredNotifications.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filteredNotifications[index];
                                return _buildNotificationCard(context, item);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('notification_chip_all'),
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...NotificationCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('notification_chip_${cat.name}'),
                      label: Text(cat.displayName),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Unread toggle
          Row(
            children: [
              FilterChip(
                key: const Key('notification_filter_unread_only'),
                label: const Text('Unread Only'),
                selected: _unreadOnly,
                onSelected: (val) {
                  setState(() => _unreadOnly = val);
                },
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  'Showing ${_selectedCategory == null ? 'All' : _selectedCategory!.displayName}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, CrmNotification item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnread = !item.isRead;

    return Card(
      key: Key('notification_card_${item.id}'),
      elevation: isUnread ? 1.5 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isUnread
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: isUnread
          ? colorScheme.primaryContainer.withValues(alpha: 0.08)
          : colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (isUnread) {
            widget.cubit.markAsRead(
              notificationId: item.id,
              userId: widget.user.id,
            );
          }
          DeepLinkNavigationResolver.resolve(
            context,
            notification: item,
            user: widget.user,
            approvalRepository: widget.approvalRepository,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Priority, Category, and Timestamp
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildPriorityBadge(item.priority),
                  _buildCategoryBadge(item.category),
                  Text(
                    _formatDateTime(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Body
              Text(
                item.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              // Action buttons bar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isUnread)
                    TextButton.icon(
                      key: Key('notification_mark_read_${item.id}'),
                      onPressed: () {
                        widget.cubit.markAsRead(
                          notificationId: item.id,
                          userId: widget.user.id,
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark read', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  IconButton(
                    key: Key('notification_clear_${item.id}'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Dismiss',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.cubit.clearNotification(
                        notificationId: item.id,
                        userId: widget.user.id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(NotificationPriority priority) {
    Color bg;
    Color fg;

    switch (priority) {
      case NotificationPriority.critical:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case NotificationPriority.warning:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case NotificationPriority.success:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case NotificationPriority.info:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(NotificationCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _unreadOnly
                  ? 'You have caught up with all unread notifications.'
                  : 'There are no notifications matching your filter criteria.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
