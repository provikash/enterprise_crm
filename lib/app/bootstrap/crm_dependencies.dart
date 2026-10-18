import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/user_lead_link_repository.dart';
import '../../features/calling/domain/repositories/lead_call_activity_repository.dart';
import '../../features/calling/domain/repositories/lead_follow_up_repository.dart';
import '../../features/dispatch/domain/repositories/dispatch_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/purchase/domain/repositories/purchase_repository.dart';
import '../../features/user_management/domain/repositories/user_management_repository.dart';
import '../../features/approvals/domain/repositories/approval_repository.dart';
import '../../features/approvals/domain/services/approval_bridge.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/services/notification_dispatcher.dart';
import '../../features/vendors/domain/repositories/vendor_repository.dart';
import 'hr_payroll_dependencies.dart';

/// Unified repository boundary for the Enterprise CRM application.
///
/// This boundary decouples the entire presentation layer from concrete
/// storage or networking implementations. When switching between in-memory
/// mock storage and a real REST backend, only the factory assembling this
/// container needs to change.
class CrmDependencies {
  final LeadRepository leadRepository;
  final AuthRepository authRepository;
  final UserManagementRepository userManagementRepository;
  final UserLeadLinkRepository userLeadLinkRepository;
  final LeadCallActivityRepository leadCallActivityRepository;
  final LeadFollowUpRepository leadFollowUpRepository;
  final InventoryRepository inventoryRepository;
  final DispatchRepository dispatchRepository;
  final PurchaseRepository purchaseRepository;
  final VendorRepository vendorRepository;
  final HrPayrollDependencies hrPayrollDependencies;
  final ApprovalRepository? approvalRepository;
  final NotificationRepository? notificationRepository;
  final ApprovalBridge? approvalBridge;
  final NotificationDispatcher? notificationDispatcher;

  const CrmDependencies({
    required this.leadRepository,
    required this.authRepository,
    required this.userManagementRepository,
    required this.userLeadLinkRepository,
    required this.leadCallActivityRepository,
    required this.leadFollowUpRepository,
    required this.inventoryRepository,
    required this.dispatchRepository,
    required this.purchaseRepository,
    required this.vendorRepository,
    required this.hrPayrollDependencies,
    this.approvalRepository,
    this.notificationRepository,
    this.approvalBridge,
    this.notificationDispatcher,
  });
}
