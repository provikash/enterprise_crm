import 'package:flutter/material.dart';

import 'app/bootstrap/api_crm_dependencies.dart';
import 'app/bootstrap/crm_dependencies.dart';
import 'app/bootstrap/mock_crm_dependencies.dart';
import 'app/crm_app.dart';
import 'core/config/app_config.dart';

void main() {
  final config = AppConfig.fromEnvironment();

  // Select dependency bundle based on configured DataSourceMode.
  final CrmDependencies dependencies = switch (config.dataSourceMode) {
    DataSourceMode.mock => createMockCrmDependencies(),
    DataSourceMode.api => createProductionApiDependencies(config: config),
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
      vendorRepository: dependencies.vendorRepository,
      hrPayrollDependencies: dependencies.hrPayrollDependencies,
      approvalRepository: dependencies.approvalRepository,
      notificationRepository: dependencies.notificationRepository,
      approvalBridge: dependencies.approvalBridge,
      notificationDispatcher: dependencies.notificationDispatcher,
      authTokenVault: dependencies.authTokenVault,
    ),
  );
}
