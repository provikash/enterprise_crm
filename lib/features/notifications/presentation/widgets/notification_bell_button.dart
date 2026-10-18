import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/approvals/domain/repositories/approval_repository.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import 'notification_dropdown_popover.dart';

/// Global header button displaying a bell icon with dynamic unread badge and dropdown popover trigger.
class NotificationBellButton extends StatelessWidget {
  final CurrentUser user;
  final NotificationCubit? cubit;
  final ApprovalRepository? approvalRepository;

  const NotificationBellButton({
    super.key,
    required this.user,
    this.cubit,
    this.approvalRepository,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCubit = cubit ?? context.read<NotificationCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<NotificationCubit, NotificationState>(
      bloc: effectiveCubit,
      builder: (context, state) {
        final int unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
        final notifications = state is NotificationLoaded ? state.notifications : const [];

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              key: const Key('notification_bell_button'),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: unreadCount > 0
                  ? '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}'
                  : 'Notifications',
              onPressed: () {
                _openNotificationsPopover(
                  context,
                  effectiveCubit: effectiveCubit,
                  notifications: notifications,
                  unreadCount: unreadCount,
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onError,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openNotificationsPopover(
    BuildContext context, {
    required NotificationCubit effectiveCubit,
    required List<dynamic> notifications,
    required int unreadCount,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    if (isCompact) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: NotificationDropdownPopover(
                notifications: List.from(notifications),
                unreadCount: unreadCount,
                user: user,
                cubit: effectiveCubit,
                approvalRepository: approvalRepository,
                onClose: () => Navigator.of(bottomSheetContext).pop(),
              ),
            ),
          );
        },
      );
    } else {
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.25),
        builder: (dialogContext) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: NotificationDropdownPopover(
                notifications: List.from(notifications),
                unreadCount: unreadCount,
                user: user,
                cubit: effectiveCubit,
                approvalRepository: approvalRepository,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          );
        },
      );
    }
  }
}
