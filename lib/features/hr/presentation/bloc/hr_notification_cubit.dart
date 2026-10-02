import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/exceptions/hr_notification_exception.dart';
import '../../domain/repositories/hr_notification_repository.dart';
import 'hr_notification_state.dart';

/// Cubit managing in-app notifications for the active authenticated CRM user.
///
/// Follows HR-9.7 & HR-9.8 rules:
/// - Recipient Isolation: loads and displays only notifications addressed to [CurrentUser.id].
/// - Stale Response Protection: tracks [_activeUserId] to ignore async results if user changes.
/// - Session Reset: [clear] method wipes state and cancels active user reference on logout.
class HrNotificationCubit extends Cubit<HrNotificationState> {
  final HrNotificationRepository _repository;
  String? _activeUserId;

  HrNotificationCubit({required HrNotificationRepository repository})
      : _repository = repository,
        super(const HrNotificationInitial());

  /// Loads notifications and unread count for [user].
  Future<void> loadNotifications({required CurrentUser user}) async {
    _activeUserId = user.id;
    emit(const HrNotificationLoading());

    try {
      final notifs = await _repository.getNotificationsForUser(user.id);
      final unread = await _repository.getUnreadCount(user.id);

      // Check for stale response if user switched while async call was in flight
      if (_activeUserId != user.id) return;

      emit(HrNotificationLoaded(notifications: notifs, unreadCount: unread));
    } on HrNotificationException catch (e) {
      if (_activeUserId != user.id) return;
      emit(HrNotificationError(message: e.message, code: e.code));
    } catch (e) {
      if (_activeUserId != user.id) return;
      emit(HrNotificationError(message: e.toString(), code: 'unexpected_error'));
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead({
    required String notificationId,
    required CurrentUser user,
  }) async {
    try {
      await _repository.markAsRead(notificationId, recipientUserId: user.id);
      await loadNotifications(user: user);
    } on HrNotificationException catch (e) {
      emit(HrNotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(HrNotificationError(message: e.toString(), code: 'unexpected_error'));
    }
  }

  /// Marks all unread notifications for [user] as read.
  Future<void> markAllAsRead({required CurrentUser user}) async {
    try {
      await _repository.markAllAsRead(recipientUserId: user.id);
      await loadNotifications(user: user);
    } on HrNotificationException catch (e) {
      emit(HrNotificationError(message: e.message, code: e.code));
    } catch (e) {
      emit(HrNotificationError(message: e.toString(), code: 'unexpected_error'));
    }
  }

  /// Clears cubit state on logout or session change.
  void clear() {
    _activeUserId = null;
    emit(const HrNotificationInitial());
  }
}
