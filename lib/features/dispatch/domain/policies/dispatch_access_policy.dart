import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';

/// Centralized role and permission-based authorization policy for the Dispatch module.
abstract final class DispatchAccessPolicy {
  /// Checks whether [user] can access and view the Dispatch module.
  static bool canView(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!AccessPolicy.canAccessModule(user, CrmModule.dispatch)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchView);
  }

  /// Checks whether [user] can create new dispatch orders.
  static bool canCreate(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchCreate);
  }

  /// Checks whether [user] can change dispatch status (e.g. In Transit, Delivered).
  static bool canUpdateStatus(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchUpdateStatus);
  }

  /// Checks whether [user] can export dispatches as CSV.
  static bool canExportCsv(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchExportCsv);
  }

  /// Checks whether [user] can export dispatches as Excel (.xlsx).
  static bool canExportXlsx(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchExportXlsx);
  }

  /// Checks whether [user] can export dispatch register reports as PDF.
  static bool canExportPdf(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchExportPdf);
  }

  /// Checks whether [user] can download individual dispatch bills / challans in PDF.
  static bool canDownloadBill(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchDownloadBill) ||
        AccessPolicy.hasPermission(user, CrmPermissions.dispatchExportPdf);
  }

  /// Checks whether [user] has permission for any export format.
  static bool canExportAny(CurrentUser user) {
    return canExportCsv(user) || canExportXlsx(user) || canExportPdf(user);
  }
}
