import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/repositories/notification_repository.dart';
import '../mock/mock_notification_store.dart';
import 'backend_notification_repository.dart';
import 'mock_notification_repository.dart';

/// Controlled cutover factory establishing dual-mode switching for Notifications.
///
/// If [AppConfig.dataSourceMode] is [DataSourceMode.api], instantiates
/// [BackendNotificationRepository]. If [DataSourceMode.mock], instantiates
/// [MockNotificationRepository].
abstract final class NotificationRepositoryFactory {
  static NotificationRepository create({
    required AppConfig appConfig,
    MockNotificationStore? mockStore,
    Dio? dio,
    String basePath = '/api/v1',
  }) {
    if (appConfig.dataSourceMode == DataSourceMode.api) {
      final client = dio ?? Dio();
      return BackendNotificationRepository(dio: client, basePath: basePath);
    }
    return MockNotificationRepository(mockStore);
  }
}
