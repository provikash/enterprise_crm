import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';

/// Centralized authorization policy governing access to Purchase Management operations.
abstract final class PurchaseAccessPolicy {
  /// Checks whether [user] can access and view the Purchase module.
  static bool canView(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!AccessPolicy.canAccessModule(user, CrmModule.purchase)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseView);
  }

  /// Checks whether [user] can create a new Purchase Order.
  static bool canCreate(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseCreate);
  }

  /// Checks whether [user] can approve a pending Purchase Order.
  static bool canApprove(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return AccessPolicy.hasPermission(user, CrmPermissions.purchaseApprove);
  }

  /// Checks whether [user] can receive goods against an ordered PO.
  static bool canReceive(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseReceiveStock);
  }

  /// Checks whether [user] can export purchase reports or PO bills.
  static bool canExport(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseExportCsv) ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseExportPdf);
  }

  /// Checks whether [user] can export purchase reports as CSV.
  static bool canExportCsv(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseExportCsv);
  }

  /// Checks whether [user] can export purchase reports as PDF.
  static bool canExportPdf(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseExportPdf);
  }

  /// Checks whether [user] can download individual PO bills in PDF.
  static bool canDownloadBill(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.purchaseDownloadBill);
  }
}
