import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';
import '../../../leads/domain/entities/lead.dart';

/// Centralized authorization policy for standard CRM User calling workflows.
///
/// Admin workflows remain separate and do not traverse this standard-user policy.
abstract final class UserCallingPolicy {
  /// Returns whether [user] is authorized to access the Calling module.
  ///
  /// Administrators hold unrestricted access across all modules.
  /// Standard users require [CrmModule.calling] assigned and [CrmPermissions.callingUse] granted.
  static bool canUseCalling(CurrentUser user) {
    if (user.isAdmin) return true;

    return AccessPolicy.canAccessModule(user, CrmModule.calling) &&
        AccessPolicy.hasPermission(user, CrmPermissions.callingUse);
  }

  /// Returns whether [user] is authorized to record a call outcome on [lead].
  ///
  /// Administrators hold unrestricted authority to record call outcomes on any lead.
  /// Standard users require:
  /// 1. Calling module + `calling.use` permission.
  /// 2. Lead Management module + `lead.view_assigned` permission.
  /// 3. Valid identity link mapping to a non-empty [linkedAssigneeId].
  /// 4. Strict ownership: [lead] is assigned to [linkedAssigneeId].
  ///
  /// NOTE: `lead.update` is NOT required to record a call outcome.
  static bool canRecordActivityForLead({
    required CurrentUser user,
    required Lead lead,
    required String? linkedAssigneeId,
  }) {
    if (!canUseCalling(user)) return false;

    if (user.isAdmin) return true;

    if (!AccessPolicy.canAccessModule(user, CrmModule.leadManagement)) {
      return false;
    }

    if (!AccessPolicy.hasPermission(user, CrmPermissions.leadViewAssigned)) {
      return false;
    }

    final sanitizedLink = linkedAssigneeId?.trim();
    if (sanitizedLink == null || sanitizedLink.isEmpty) {
      return false;
    }

    if (!lead.isAssigned || lead.assignedUserId != sanitizedLink) {
      return false;
    }

    return true;
  }

  /// Returns whether [user] is authorized to view call history for [lead].
  ///
  /// Administrators have full authority. For standard users, exposes history
  /// only when the user is authorized for Calling and strictly owns the lead.
  static bool canViewLeadHistory({
    required CurrentUser user,
    required Lead lead,
    required String? linkedAssigneeId,
  }) {
    if (user.isAdmin) return true;

    return canRecordActivityForLead(
      user: user,
      lead: lead,
      linkedAssigneeId: linkedAssigneeId,
    );
  }
}
