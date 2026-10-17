import '../../core/network/api_client.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/user_lead_link_repository.dart';
import '../../features/calling/domain/repositories/lead_call_activity_repository.dart';
import '../../features/calling/domain/repositories/lead_follow_up_repository.dart';
import '../../features/dispatch/domain/repositories/dispatch_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/purchase/domain/repositories/purchase_repository.dart';
import '../../features/user_management/domain/repositories/user_management_repository.dart';
import '../../features/vendors/domain/repositories/vendor_repository.dart';
import 'crm_dependencies.dart';
import 'hr_payroll_dependencies.dart';

/// Instruction for Instructor / Backend Integrator:
///
/// This factory is the sole entry point for assembling production API repositories.
/// When the backend REST API is available:
/// 1. Replace the mock fallbacks below with your concrete API repository implementations
///    (e.g., `ApiLeadRepository(apiClient)`, `ApiAuthRepository(apiClient)`).
/// 2. Ensure each API repository implements the corresponding abstract interface.
/// 3. In `lib/core/config/app_config.dart`, set `dataSourceMode = DataSourceMode.api`
///    and configure your `apiBaseUri`.
///
/// When running in this mode, ZERO mock data or mock account stores are instantiated.
CrmDependencies createApiCrmDependencies({
  required ApiClient apiClient,
  required LeadRepository leadRepository,
  required AuthRepository authRepository,
  required UserManagementRepository userManagementRepository,
  required UserLeadLinkRepository userLeadLinkRepository,
  required LeadCallActivityRepository leadCallActivityRepository,
  required LeadFollowUpRepository leadFollowUpRepository,
  required InventoryRepository inventoryRepository,
  required DispatchRepository dispatchRepository,
  required PurchaseRepository purchaseRepository,
  required VendorRepository vendorRepository,
  required HrPayrollDependencies hrPayrollDependencies,
}) {
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
    vendorRepository: vendorRepository,
    hrPayrollDependencies: hrPayrollDependencies,
  );
}
