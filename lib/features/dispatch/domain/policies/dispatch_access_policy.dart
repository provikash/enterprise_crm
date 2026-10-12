import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';

abstract final class DispatchAccessPolicy {
  /// Checks whether [user] can access and view the Dispatch module.
  static bool canView(CurrentUser user) =>
      AccessPolicy.canAccessModule(user, CrmModule.dispatch);

  /// Checks whether [user] can create new dispatch orders.
  static bool canCreate(CurrentUser user) =>
      user.isAdmin || user.hasModule(CrmModule.dispatch);

  /// Checks whether [user] can change dispatch status (e.g. In Transit, Delivered).
  static bool canUpdateStatus(CurrentUser user) =>
      user.isAdmin || user.hasModule(CrmModule.dispatch);
}
