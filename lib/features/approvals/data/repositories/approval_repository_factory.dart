import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/repositories/approval_repository.dart';
import '../mock/mock_approval_store.dart';
import 'backend_approval_repository.dart';
import 'mock_approval_repository.dart';

/// Controlled cutover factory establishing dual-mode switching for Approvals.
///
/// If [AppConfig.dataSourceMode] is [DataSourceMode.api], instantiates
/// [BackendApprovalRepository]. If [DataSourceMode.mock], instantiates
/// [MockApprovalRepository].
abstract final class ApprovalRepositoryFactory {
  static ApprovalRepository create({
    required AppConfig appConfig,
    MockApprovalStore? mockStore,
    Dio? dio,
    String basePath = '/api/v1',
  }) {
    if (appConfig.dataSourceMode == DataSourceMode.api) {
      final client = dio ?? Dio();
      return BackendApprovalRepository(dio: client, basePath: basePath);
    }
    return MockApprovalRepository(mockStore);
  }
}
