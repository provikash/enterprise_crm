import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../entities/lead.dart';

/// Centralized authorization policy for Lead Management operations.
///
/// Follows the granular permission model patterned after Inventory:
/// - Administrator has unrestricted authority across all operations.
/// - Standard users require module assignment [CrmModule.leadManagement]
///   and specific granular permission grants for viewing, editing, deleting,
///   assigning, importing, and exporting leads.
abstract final class LeadAccessPolicy {
  /// Evaluates whether [user] is authorized to view all leads across the CRM.
  static bool canViewAll(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadViewAll);
  }

  /// Evaluates whether [user] is authorized to view assigned leads.
  static bool canViewAssigned(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        (AccessPolicy.hasPermission(user, CrmPermissions.leadViewAssigned) ||
            AccessPolicy.hasPermission(user, CrmPermissions.leadViewAll));
  }

  /// Evaluates whether [user] is authorized to view a specific [lead].
  static bool canViewLead({
    required CurrentUser? user,
    required Lead lead,
    String? linkedAssigneeId,
  }) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    if (canViewAll(user)) return true;
    if (!canViewAssigned(user)) return false;

    final targetAssignee = linkedAssigneeId ?? user.id;
    return lead.isAssigned && lead.assignedUserId == targetAssignee;
  }

  /// Evaluates whether [user] is authorized to create new leads.
  static bool canCreate(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadCreate);
  }

  /// Evaluates whether [user] is authorized to edit [lead].
  static bool canEdit({
    required CurrentUser? user,
    required Lead lead,
    String? linkedAssigneeId,
  }) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    if (!AccessPolicy.canAccessModule(user, CrmModule.leadManagement)) {
      return false;
    }
    if (!AccessPolicy.hasPermission(user, CrmPermissions.leadUpdate)) {
      return false;
    }
    return canViewLead(
      user: user,
      lead: lead,
      linkedAssigneeId: linkedAssigneeId,
    );
  }

  /// Evaluates whether [user] is authorized to delete leads.
  static bool canDelete({
    required CurrentUser? user,
    Lead? lead,
    String? linkedAssigneeId,
  }) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    if (!AccessPolicy.canAccessModule(user, CrmModule.leadManagement)) {
      return false;
    }
    if (!AccessPolicy.hasPermission(user, CrmPermissions.leadDelete)) {
      return false;
    }
    if (lead != null) {
      return canViewLead(
        user: user,
        lead: lead,
        linkedAssigneeId: linkedAssigneeId,
      );
    }
    return true;
  }

  /// Evaluates whether [user] is authorized to assign or reassign leads.
  static bool canAssign(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadAssign);
  }

  /// Evaluates whether [user] is authorized to import leads via CSV.
  static bool canImportCsv(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadImportCsv);
  }

  /// Evaluates whether [user] is authorized to import leads via Excel (XLSX).
  static bool canImportXlsx(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadImportXlsx);
  }

  /// Evaluates whether [user] is authorized to perform any lead import.
  static bool canImport(CurrentUser? user) {
    return canImportCsv(user) || canImportXlsx(user);
  }

  /// Evaluates whether [user] is authorized to export leads via CSV.
  static bool canExportCsv(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadExportCsv);
  }

  /// Evaluates whether [user] is authorized to export leads via Excel (XLSX).
  static bool canExportXlsx(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadExportXlsx);
  }

  /// Evaluates whether [user] is authorized to export leads via PDF.
  static bool canExportPdf(CurrentUser? user) {
    if (user == null) return false;
    if (user.isAdmin) return true;
    return AccessPolicy.canAccessModule(user, CrmModule.leadManagement) &&
        AccessPolicy.hasPermission(user, CrmPermissions.leadExportPdf);
  }

  /// Evaluates whether [user] is authorized to perform any lead export.
  static bool canExport(CurrentUser? user) {
    return canExportCsv(user) || canExportXlsx(user) || canExportPdf(user);
  }
}
