import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';

/// Centralized authorization policy governing access to Purchase Management operations.
abstract final class PurchaseAccessPolicy {
  /// Checks whether [user] can access and view the Purchase module.
  static bool canView(CurrentUser user) =>
      AccessPolicy.canAccessModule(user, CrmModule.purchase);

  /// Checks whether [user] can create a new Purchase Order.
  static bool canCreate(CurrentUser user) =>
      user.isAdmin || user.hasModule(CrmModule.purchase);

  /// Checks whether [user] can approve a pending Purchase Order (Admin-only).
  static bool canApprove(CurrentUser user) => user.isAdmin;

  /// Checks whether [user] can receive goods against an ordered PO.
  static bool canReceive(CurrentUser user) =>
      user.isAdmin || user.hasModule(CrmModule.purchase);
}
