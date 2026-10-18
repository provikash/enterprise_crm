import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:enterprise_crm/core/config/app_config.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/backend_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:enterprise_crm/features/notifications/data/repositories/notification_repository_factory.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_category.dart';
import 'package:enterprise_crm/features/notifications/domain/entities/notification_priority.dart';
import 'package:enterprise_crm/features/notifications/domain/exceptions/notification_network_exception.dart';
import 'package:enterprise_crm/features/notifications/domain/inputs/create_notification_input.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late _MockAdapter adapter;
  late BackendNotificationRepository repository;

  setUp(() {
    adapter = _MockAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://crm.enterprise.internal'));
    dio.httpClientAdapter = adapter;
    repository = BackendNotificationRepository(dio: dio, basePath: '/api/v1');
  });

  tearDown(() {
    repository.dispose();
  });

  ResponseBody jsonResponse(dynamic data, int statusCode) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  group('BackendNotificationRepository Tests', () {
    test('getNotifications sends GET and returns mapped list', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/notifications');
        expect(options.queryParameters['recipient_user_id'], 'usr-1');
        return jsonResponse({
          'items': [
            {
              'id': 'notif-1',
              'recipient_user_id': 'usr-1',
              'title': 'Approval Done',
              'body': 'Your PO was approved.',
              'category': 'approvalDecision',
              'priority': 'normal',
              'is_read': false,
              'created_at': '2026-10-16T15:00:00.000Z',
            },
          ],
        }, 200);
      };

      final items = await repository.getNotifications(recipientUserId: 'usr-1');
      expect(items.length, 1);
      expect(items.first.id, 'notif-1');
      expect(items.first.category, NotificationCategory.approvalDecision);
    });

    test('getUnreadCount returns correct count from API', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/notifications');
        expect(options.queryParameters['unread_only'], true);
        return jsonResponse({
          'unread_count': 5,
          'items': [],
        }, 200);
      };

      final count = await repository.getUnreadCount('usr-1');
      expect(count, 5);
    });

    test('markAsRead and markAllAsRead invoke backend endpoints', () async {
      adapter.handler = (options) {
        if (options.path == '/api/v1/notifications/notif-1/read') {
          expect(options.method, 'PATCH');
          return jsonResponse({'success': true}, 200);
        }
        if (options.path == '/api/v1/notifications/read-all') {
          expect(options.method, 'POST');
          return jsonResponse({'success': true}, 200);
        }
        return jsonResponse({}, 404);
      };

      await repository.markAsRead(notificationId: 'notif-1', userId: 'usr-1');
      await repository.markAllAsRead('usr-1');
    });

    test('clearNotification sends DELETE to endpoint', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/notifications/notif-1');
        expect(options.method, 'DELETE');
        return jsonResponse({'success': true}, 200);
      };

      await repository.clearNotification(
        notificationId: 'notif-1',
        userId: 'usr-1',
      );
    });

    test('dispatchNotification sends POST and returns created entity', () async {
      adapter.handler = (options) {
        expect(options.path, '/api/v1/notifications');
        expect(options.method, 'POST');
        final data = options.data as Map<String, dynamic>;
        expect(data['recipient_user_id'], 'usr-2');
        expect(data['title'], 'System Update');

        return jsonResponse({
          'id': 'notif-new',
          'recipient_user_id': 'usr-2',
          'title': 'System Update',
          'body': 'Server restart scheduled.',
          'category': 'systemAlert',
          'priority': 'critical',
          'created_at': '2026-10-16T18:00:00.000Z',
        }, 201);
      };

      final notif = await repository.dispatchNotification(
        const CreateNotificationInput(
          recipientUserId: 'usr-2',
          title: 'System Update',
          body: 'Server restart scheduled.',
          category: NotificationCategory.systemAlert,
          priority: NotificationPriority.critical,
          referenceModule: CrmModule.approvalsNotifications,
        ),
      );

      expect(notif.id, 'notif-new');
      expect(notif.priority, NotificationPriority.critical);
    });

    test('Zero Silent Fallback Invariant: 500 error throws NotificationNetworkException without falling back to mock', () async {
      adapter.handler = (options) {
        return jsonResponse({'error': 'Notification service unavailable'}, 500);
      };

      expect(
        () => repository.getNotifications(recipientUserId: 'usr-1'),
        throwsA(isA<NotificationNetworkException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });
  });

  group('NotificationRepositoryFactory Tests', () {
    test('instantiates MockNotificationRepository when dataSourceMode is mock', () {
      const config = AppConfig(dataSourceMode: DataSourceMode.mock);
      final repo = NotificationRepositoryFactory.create(appConfig: config);
      expect(repo, isA<MockNotificationRepository>());
    });

    test('instantiates BackendNotificationRepository when dataSourceMode is api', () {
      const config = AppConfig(dataSourceMode: DataSourceMode.api);
      final repo = NotificationRepositoryFactory.create(
        appConfig: config,
        dio: dio,
      );
      expect(repo, isA<BackendNotificationRepository>());
    });
  });
}
