import 'package:flutter/material.dart';

import 'app/crm_app.dart';
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

void main() {
  final leadRepository = MockLeadRepository();
  final accountStore = MockAccountStore.seeded();
  final authRepository = MockAuthRepository(accountStore: accountStore);
  final userManagementRepository = MockUserManagementRepository(
    accountStore: accountStore,
  );
  final userLeadLinkRepository = MockUserLeadLinkRepository();
  final leadCallActivityRepository = MockLeadCallActivityRepository();
  final leadFollowUpRepository = MockLeadFollowUpRepository();
  final inventoryRepository = MockInventoryRepository();
  final hrPayrollDependencies = createMockHrPayrollDependencies();

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
    ),
  );
}
