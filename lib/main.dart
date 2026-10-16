import 'package:flutter/material.dart';

import 'app/bootstrap/crm_dependencies.dart';
import 'app/bootstrap/mock_crm_dependencies.dart';
import 'app/crm_app.dart';
import 'core/config/app_config.dart';

void main() {
  const config = AppConfig.development;

  // Select dependency bundle based on configured DataSourceMode.
  // In DataSourceMode.api, mock repositories are never instantiated.
  final CrmDependencies dependencies = switch (config.dataSourceMode) {
    DataSourceMode.mock => createMockCrmDependencies(),
    DataSourceMode.api => throw UnimplementedError(
        'Instructor Backend Notice: Configure createApiCrmDependencies with your API endpoints in lib/app/bootstrap/api_crm_dependencies.dart',
      ),
  };

  runApp(
    CrmApp(
      appConfig: config,
      leadRepository: dependencies.leadRepository,
      authRepository: dependencies.authRepository,
      userManagementRepository: dependencies.userManagementRepository,
      userLeadLinkRepository: dependencies.userLeadLinkRepository,
      leadCallActivityRepository: dependencies.leadCallActivityRepository,
      leadFollowUpRepository: dependencies.leadFollowUpRepository,
      inventoryRepository: dependencies.inventoryRepository,
      dispatchRepository: dependencies.dispatchRepository,
      purchaseRepository: dependencies.purchaseRepository,
      hrPayrollDependencies: dependencies.hrPayrollDependencies,
    ),
  );
}
