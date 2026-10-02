import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/current_user.dart';
import '../../data/repositories/mock_hr_approval_repository.dart';
import '../../domain/entities/hr_notification.dart';
import '../../domain/entities/hr_notification_type.dart';
import '../../domain/repositories/hr_approval_repository.dart';
import '../../domain/repositories/hr_notification_repository.dart';
import '../bloc/hr_notification_cubit.dart';
import '../bloc/hr_notification_state.dart';
import '../screens/hr_approval_request_details_screen.dart';

/// Modal dialog displaying in-app notifications for [user].
///
/// Features:
/// - Scoped to [user.id]; cross-user notification leakage is prevented.
/// - Allows marking individual or all notifications as read.
/// - Tapping an approval-related notification navigates to [HrApprovalRequestDetailsScreen].
class HrNotificationInboxDialog extends StatelessWidget {
  final CurrentUser user;
  final HrNotificationRepository notificationRepository;
  final HrApprovalRepository? approvalRepository;

  const HrNotificationInboxDialog({
    super.key,
    required this.user,
    required this.notificationRepository,
    this.approvalRepository,
  });

  static Future<void> show({
    required BuildContext context,
    required CurrentUser user,
    required HrNotificationRepository notificationRepository,
    HrApprovalRepository? approvalRepository,
  }) {
    return showDialog(
      context: context,
      builder: (_) => HrNotificationInboxDialog(
        user: user,
        notificationRepository: notificationRepository,
        approvalRepository: approvalRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HrNotificationCubit(repository: notificationRepository)
        ..loadNotifications(user: user),
      child: Dialog(
        key: const Key('hr_notification_inbox_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const Divider(),
                Expanded(
                  child: BlocBuilder<HrNotificationCubit, HrNotificationState>(
                    builder: (context, state) {
                      return switch (state) {
                        HrNotificationInitial() ||
                        HrNotificationLoading() =>
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        HrNotificationError(:final message) => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 40),
                                const SizedBox(height: 8),
                                Text(message, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        HrNotificationLoaded(
                          :final notifications,
                        ) =>
                          notifications.isEmpty
                              ? _buildEmptyState(context)
                              : _buildNotificationList(
                                  context, notifications),
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

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<HrNotificationCubit, HrNotificationState>(
      builder: (context, state) {
        final unread = state is HrNotificationLoaded ? state.unreadCount : 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Notifications',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unread > 0)
                  TextButton(
                    key: const Key('hr_notifications_mark_all_read_button'),
                    onPressed: () => context
                        .read<HrNotificationCubit>()
                        .markAllAsRead(user: user),
                    child: const Text('Mark all read'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
      BuildContext context, List<HrNotification> notifications) {
    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = notifications[index];
        return ListTile(
          key: Key('hr_notification_item_${item.id}'),
          leading: CircleAvatar(
            backgroundColor: _getIconBackgroundColor(item.type),
            child: Icon(
              _getNotificationIcon(item.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                item.body,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(item.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          trailing: !item.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () async {
            final nav = Navigator.of(context);
            if (!item.isRead) {
              await context
                  .read<HrNotificationCubit>()
                  .markAsRead(notificationId: item.id, user: user);
            }
            nav.pop();
            nav.push(
              MaterialPageRoute(
                builder: (_) => HrApprovalRequestDetailsScreen(
                  requestId: item.requestId,
                  user: user,
                  repository:
                      approvalRepository ?? MockHrApprovalRepository(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getIconBackgroundColor(HrNotificationType type) {
    switch (type) {
      case HrNotificationType.approvalRequestSubmitted:
        return Colors.orange;
      case HrNotificationType.approvalDecisionRecorded:
        return Colors.green;
      case HrNotificationType.approvalRequestCancelled:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(HrNotificationType type) {
    switch (type) {
      case HrNotificationType.approvalRequestSubmitted:
        return Icons.assignment_outlined;
      case HrNotificationType.approvalDecisionRecorded:
        return Icons.verified_outlined;
      case HrNotificationType.approvalRequestCancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year}-${_twoDigits(utc.month)}-${_twoDigits(utc.day)} '
        '${_twoDigits(utc.hour)}:${_twoDigits(utc.minute)} UTC';
  }

  String _twoDigits(int n) => n >= 10 ? '$n' : '0$n';
}
