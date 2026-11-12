import '../../core/config/app_config.dart';
import '../../core/logging/crm_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/security/auth_token_vault.dart';
import '../../features/approvals/data/repositories/backend_approval_repository.dart';
import '../../features/approvals/data/services/default_approval_bridge.dart';
import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../features/approvals/domain/services/approval_bridge.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/user_lead_link_repository.dart';
import '../../features/calling/domain/repositories/lead_call_activity_repository.dart';
import '../../features/calling/domain/repositories/lead_follow_up_repository.dart';
import '../../features/dispatch/domain/repositories/dispatch_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/notifications/data/repositories/backend_notification_repository.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/services/notification_dispatcher.dart';
import '../../features/purchase/domain/repositories/purchase_repository.dart';
import '../../features/user_management/domain/repositories/user_management_repository.dart';
import '../../features/vendors/domain/repositories/vendor_repository.dart';
import 'crm_dependencies.dart';
import 'hr_payroll_dependencies.dart';
import 'mock_crm_dependencies.dart';

/// Enterprise CRM Production Dependency Assembly.
///
/// This factory provides the composition root for assembling production API repositories.
/// When connecting to a live backend REST API:
/// 1. Provide concrete API repository implementations for each module
///    (e.g., `ApiLeadRepository(apiClient)`, `ApiAuthRepository(apiClient)`).
/// 2. Ensure each API repository implements the corresponding abstract domain interface.
/// 3. In `lib/core/config/app_config.dart`, set `dataSourceMode = DataSourceMode.api`
///    and configure your `apiBaseUri`.
///
/// When running in this mode, live repositories handle network interactions via [ApiClient].
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
  ApprovalRepository? approvalRepository,
  NotificationRepository? notificationRepository,
  ApprovalBridge? approvalBridge,
  NotificationDispatcher? notificationDispatcher,
  AuthTokenVault? authTokenVault,
}) {
  final resolvedNotificationRepo =
      notificationRepository ??
      BackendNotificationRepository(dio: apiClient.dio);
  final resolvedNotificationDispatcher =
      notificationDispatcher ??
      DefaultNotificationDispatcher(resolvedNotificationRepo);
  final resolvedApprovalRepo =
      approvalRepository ?? BackendApprovalRepository(dio: apiClient.dio);
  final resolvedApprovalBridge =
      approvalBridge ??
      DefaultApprovalBridge(
        repository: resolvedApprovalRepo,
        notificationDispatcher: resolvedNotificationDispatcher,
      );

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
    approvalRepository: resolvedApprovalRepo,
    notificationRepository: resolvedNotificationRepo,
    approvalBridge: resolvedApprovalBridge,
    notificationDispatcher: resolvedNotificationDispatcher,
    authTokenVault: authTokenVault,
  );
}

/// Production composition root for API-connected mode.
///
/// Automatically instantiates [ApiClient] from [AppConfig.apiBaseUri] and wires
/// backend repositories for live network interactions.
CrmDependencies createProductionApiDependencies({
  required AppConfig config,
  AuthTokenVault? authTokenVault,
}) {
  final vault = authTokenVault ?? AuthTokenVault();
  final baseUri =
      config.apiBaseUri ?? Uri.parse('https://api.crm.vinayenterprise.com');
  final apiClient = ApiClient.fromVault(baseUri: baseUri, vault: vault);

  CrmLogger.info(
    'Bootstrap',
    'Assembling production API dependencies for: $baseUri',
  );

  // Load existing mock bundle as clean transitional fallbacks for endpoints
  // not yet implemented by the concrete backend.
  final fallbacks = createMockCrmDependencies(authTokenVault: vault);

  final notificationRepo = BackendNotificationRepository(dio: apiClient.dio);
  final notificationDispatcher = DefaultNotificationDispatcher(notificationRepo);
  final approvalRepo = BackendApprovalRepository(dio: apiClient.dio);
  final approvalBridge = DefaultApprovalBridge(
    repository: approvalRepo,
    notificationDispatcher: notificationDispatcher,
  );

  return CrmDependencies(
    leadRepository: fallbacks.leadRepository,
    authRepository: fallbacks.authRepository,
    userManagementRepository: fallbacks.userManagementRepository,
    userLeadLinkRepository: fallbacks.userLeadLinkRepository,
    leadCallActivityRepository: fallbacks.leadCallActivityRepository,
    leadFollowUpRepository: fallbacks.leadFollowUpRepository,
    inventoryRepository: fallbacks.inventoryRepository,
    dispatchRepository: fallbacks.dispatchRepository,
    purchaseRepository: fallbacks.purchaseRepository,
    vendorRepository: fallbacks.vendorRepository,
    hrPayrollDependencies: fallbacks.hrPayrollDependencies,
    approvalRepository: approvalRepo,
    notificationRepository: notificationRepo,
    approvalBridge: approvalBridge,
    notificationDispatcher: notificationDispatcher,
    authTokenVault: vault,
  );
}
