import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../../../features/auth/domain/policies/crm_permissions.dart';
import '../entities/approval_request.dart';

/// Pure domain policy enforcing access control for Approvals and Notifications.
abstract final class ApprovalsAccessPolicy {
  /// Whether the user can access the Approvals & Notifications module.
  static bool canAccessModule(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        (user.hasPermission(CrmPermissions.approvalsView) ||
            user.hasPermission(CrmPermissions.notificationsView));
  }

  /// Whether the user can view approval requests.
  static bool canViewApprovals(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        user.hasPermission(CrmPermissions.approvalsView);
  }

  /// Whether the user can execute approval decisions (Approve, Reject, Request Revision).
  ///
  /// Enforces the Maker-Checker principle: a non-admin requester cannot approve their own submission.
  static bool canPerformDecision(CurrentUser user, ApprovalRequest request) {
    if (!request.isActionable) return false;

    // Maker-Checker: Users cannot approve their own requests.
    if (!user.isAdmin && request.requesterId == user.id) {
      return false;
    }

    if (user.isAdmin) return true;

    if (!user.hasModule(CrmModule.approvalsNotifications) ||
        !user.hasPermission(CrmPermissions.approvalsAction)) {
      return false;
    }

    // If active step is assigned to a specific user, only that user can act.
    final step = request.currentStep;
    if (step != null && step.assignedUserId != null) {
      return step.assignedUserId == user.id;
    }

    return true;
  }

  /// Whether the user can submit new approval requests.
  static bool canSubmitRequest(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        user.hasPermission(CrmPermissions.approvalsSubmit);
  }

  /// Whether the user can cancel/recall an approval request.
  static bool canCancelRequest(CurrentUser user, ApprovalRequest request) {
    if (!request.isActionable) return false;
    // Admin can cancel, or the original requester can cancel.
    return user.isAdmin || request.requesterId == user.id;
  }

  /// Whether the user can export approval reports.
  static bool canExport(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        user.hasPermission(CrmPermissions.approvalsExport);
  }

  /// Whether the user can view notifications.
  static bool canViewNotifications(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        user.hasPermission(CrmPermissions.notificationsView);
  }

  /// Whether the user can manage (mark read, clear) notifications.
  static bool canManageNotifications(CurrentUser user) {
    if (user.isAdmin) return true;
    return user.hasModule(CrmModule.approvalsNotifications) &&
        user.hasPermission(CrmPermissions.notificationsManage);
  }
}
