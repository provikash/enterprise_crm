import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/mock_user_lead_link_repository.dart';
import '../../features/calling/data/repositories/mock_lead_call_activity_repository.dart';
import '../../features/calling/data/repositories/mock_lead_follow_up_repository.dart';
import '../../features/dispatch/data/repositories/mock_dispatch_repository.dart';
import '../../features/inventory/data/repositories/mock_inventory_repository.dart';
import '../../features/leads/data/repositories/mock_lead_repository.dart';
import '../../features/purchase/data/repositories/mock_purchase_repository.dart';
import '../../features/user_management/data/mock/mock_account_store.dart';
import '../../features/user_management/data/repositories/mock_user_management_repository.dart';
import 'crm_dependencies.dart';
import 'mock_hr_payroll_dependencies.dart';

/// Assembles in-memory mock repositories for local development and offline testing.
///
/// Notice: All mock repositories and seed datasets are contained exclusively
/// within this factory and its referenced mock classes. When the application
/// runs in API mode, this factory is NEVER invoked, ensuring zero mock data leaks
/// into live environments.
CrmDependencies createMockCrmDependencies() {
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
  final dispatchRepository = MockDispatchRepository();
  final purchaseRepository = MockPurchaseRepository();
  final hrPayrollDependencies = createMockHrPayrollDependencies();

  return CrmDependencies(
    leadRepository: leadRepository,
    authRepository: authRepository,
    userManagementRepository: userManagementRepository,
    userLeadLinkRepository: userLeadLinkRepository,
    leadCallActivityRepository: leadCallActivityRepository,
    leadFollowUpRepository: leadFollowUpRepository,
    inventoryRepository: inventoryRepository,
    dispatchRepository: dispatchRepository,
    purchaseRepository: purchaseRepository,
    hrPayrollDependencies: hrPayrollDependencies,
  );
}
