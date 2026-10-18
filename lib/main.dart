import 'package:flutter/material.dart';

import 'app/bootstrap/crm_dependencies.dart';
import 'app/bootstrap/mock_crm_dependencies.dart';
import 'app/crm_app.dart';
<<<<<<< HEAD
import 'app/bootstrap/mock_hr_payroll_dependencies.dart';
import 'features/approvals/data/repositories/mock_approval_repository.dart';
import 'features/notifications/data/repositories/mock_notification_repository.dart';
import 'features/notifications/domain/services/notification_dispatcher.dart';
import 'features/auth/data/repositories/mock_auth_repository.dart';
import 'features/auth/data/repositories/mock_user_lead_link_repository.dart';
import 'features/calling/data/repositories/mock_lead_call_activity_repository.dart';
import 'features/calling/data/repositories/mock_lead_follow_up_repository.dart';
import 'features/inventory/data/repositories/mock_inventory_repository.dart';
import 'features/leads/data/repositories/mock_lead_repository.dart';
import 'features/user_management/data/mock/mock_account_store.dart';
import 'features/user_management/data/repositories/mock_user_management_repository.dart';
=======
import 'core/config/app_config.dart';
>>>>>>> 2a7fa8767b573363291c48c15547378cecf22e00

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

  final notificationRepository = MockNotificationRepository();
  final notificationDispatcher = DefaultNotificationDispatcher(
    notificationRepository,
  );
  final approvalRepository = MockApprovalRepository(
    null,
    notificationDispatcher,
  );

  runApp(
    CrmApp(
<<<<<<< HEAD
      leadRepository: leadRepository,
      authRepository: authRepository,
      userManagementRepository: userManagementRepository,
      userLeadLinkRepository: userLeadLinkRepository,
      leadCallActivityRepository: leadCallActivityRepository,
      leadFollowUpRepository: leadFollowUpRepository,
      inventoryRepository: inventoryRepository,
      hrPayrollDependencies: hrPayrollDependencies,
      approvalRepository: approvalRepository,
      notificationRepository: notificationRepository,
=======
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
>>>>>>> 2a7fa8767b573363291c48c15547378cecf22e00
    ),
  );
}
