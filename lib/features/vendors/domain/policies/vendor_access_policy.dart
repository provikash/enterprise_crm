import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';

/// Centralized authorization policy governing access to Vendor Management operations.
abstract final class VendorAccessPolicy {
  /// Checks whether [user] can access and view the Vendor module.
  static bool canView(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!AccessPolicy.canAccessModule(user, CrmModule.vendorManagement)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.vendorView);
  }

  /// Checks whether [user] can create a new Vendor record.
  static bool canCreate(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.vendorCreate);
  }

  /// Checks whether [user] can edit an existing Vendor record.
  static bool canEdit(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.vendorEdit);
  }

  /// Checks whether [user] can deactivate or delete a Vendor.
  static bool canDelete(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.vendorDelete);
  }

  /// Checks whether [user] can export the vendor directory to CSV.
  static bool canExport(CurrentUser user) {
    if (user.isAdmin) return true;
    if (!canView(user)) return false;
    return user.permissions.isEmpty ||
        AccessPolicy.hasPermission(user, CrmPermissions.vendorExportCsv);
  }
}
