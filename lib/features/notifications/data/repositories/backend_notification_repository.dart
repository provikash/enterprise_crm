import 'dart:async';
import 'package:dio/dio.dart';

import '../../domain/entities/crm_notification.dart';
import '../../domain/entities/notification_category.dart';
import '../../domain/exceptions/notification_network_exception.dart';
import '../../domain/inputs/create_notification_input.dart';
import '../../domain/repositories/notification_repository.dart';
import '../dto/notification_dto.dart';

/// Production REST API implementation of [NotificationRepository] powered by Dio.
///
/// Adheres strictly to the Zero Silent Fallback rule: any network or server
/// failure throws an explicit [NotificationNetworkException].
class BackendNotificationRepository implements NotificationRepository {
  final Dio dio;
  final String basePath;

  final Map<String, StreamController<List<CrmNotification>>> _controllers = {};
  final Map<String, List<CrmNotification>> _cachedNotifications = {};

  BackendNotificationRepository({
    required this.dio,
    this.basePath = '/api/v1',
  });

  NotificationNetworkException _mapError(dynamic error) {
    if (error is NotificationNetworkException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      String? message;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] ?? data['error'])?.toString();
      }
      return NotificationNetworkException(
        message ?? error.message ?? 'Backend network failure in Notifications.',
        statusCode: status,
        originalError: error,
      );
    }
    return NotificationNetworkException(
      error.toString(),
      originalError: error,
    );
  }

  StreamController<List<CrmNotification>> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<List<CrmNotification>>.broadcast(),
    );
  }

  void _emitUpdatedCache(String userId) {
    final list = _cachedNotifications[userId] ?? const [];
    final controller = _controllers[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(List.unmodifiable(list));
    }
  }

  @override
  Stream<List<CrmNotification>> watchNotifications(String recipientUserId) {
    final controller = _getController(recipientUserId);
    // Fetch current state asynchronously to populate stream
    getNotifications(recipientUserId: recipientUserId)
        .then((items) {
          _cachedNotifications[recipientUserId] = List.from(items);
          _emitUpdatedCache(recipientUserId);
        })
        .catchError((Object err) {
          if (!controller.isClosed) {
            controller.addError(_mapError(err));
          }
        });

    return controller.stream;
  }

  @override
  Future<List<CrmNotification>> getNotifications({
    required String recipientUserId,
    bool? unreadOnly,
    NotificationCategory? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'recipient_user_id': recipientUserId,
        'unread_only': ?unreadOnly,
        if (category != null) 'category': category.name,
      };

      final response = await dio.get<dynamic>(
        '$basePath/notifications',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> rawList;
      if (data is Map<String, dynamic> && data['items'] is List<dynamic>) {
        rawList = data['items'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        rawList = data;
      } else {
        return const [];
      }

      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => NotificationDto.fromJson(json).toDomain())
          .toList();

      _cachedNotifications[recipientUserId] = List.from(items);
      _emitUpdatedCache(recipientUserId);

      return items;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<int> getUnreadCount(String recipientUserId) async {
    try {
      final response = await dio.get<dynamic>(
        '$basePath/notifications',
        queryParameters: {
          'recipient_user_id': recipientUserId,
          'unread_only': true,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['unread_count'] is num) {
        return (data['unread_count'] as num).toInt();
      } else if (data is Map<String, dynamic> &&
          data['items'] is List<dynamic>) {
        return (data['items'] as List<dynamic>).length;
      } else if (data is List<dynamic>) {
        return data.length;
      }
      return 0;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await dio.patch<dynamic>(
        '$basePath/notifications/$notificationId/read',
        data: {'user_id': userId},
      );

      final userList = _cachedNotifications[userId];
      if (userList != null) {
        final idx = userList.indexWhere((n) => n.id == notificationId);
        if (idx != -1) {
          userList[idx] = userList[idx].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _emitUpdatedCache(userId);
        }
      }
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await dio.post<dynamic>(
        '$basePath/notifications/read-all',
        data: {'user_id': userId},
      );

      final userList = _cachedNotifications[userId];
      if (userList != null) {
        final now = DateTime.now();
        for (var i = 0; i < userList.length; i++) {
          if (!userList[i].isRead) {
            userList[i] = userList[i].copyWith(isRead: true, readAt: now);
          }
        }
        _emitUpdatedCache(userId);
      }
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> clearNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await dio.delete<dynamic>(
        '$basePath/notifications/$notificationId',
        data: {'user_id': userId},
      );

      final userList = _cachedNotifications[userId];
      if (userList != null) {
        userList.removeWhere((n) => n.id == notificationId);
        _emitUpdatedCache(userId);
      }
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<CrmNotification> dispatchNotification(
    CreateNotificationInput input,
  ) async {
    try {
      final payload = {
        'recipient_user_id': input.recipientUserId,
        'title': input.title,
        'body': input.body,
        'category': input.category.name,
        'priority': input.priority.name,
        if (input.referenceModule != null)
          'reference_module': input.referenceModule!.name,
        if (input.referenceEntityType != null)
          'reference_entity_type': input.referenceEntityType,
        if (input.referenceEntityId != null)
          'reference_entity_id': input.referenceEntityId,
        if (input.payload.isNotEmpty) 'payload': input.payload,
      };

      final response = await dio.post<dynamic>(
        '$basePath/notifications',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final created = NotificationDto.fromJson(data).toDomain();
        final userList = _cachedNotifications[input.recipientUserId];
        if (userList != null) {
          userList.insert(0, created);
          _emitUpdatedCache(input.recipientUserId);
        }
        return created;
      }
      throw const NotificationNetworkException(
        'Invalid dispatch notification response format.',
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _cachedNotifications.clear();
  }
}
