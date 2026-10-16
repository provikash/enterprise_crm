import '../../../auth/domain/entities/crm_module.dart';
import '../../../auth/domain/entities/current_user.dart';
import '../../../auth/domain/policies/access_policy.dart';
import '../../../auth/domain/policies/crm_permissions.dart';

abstract final class PayrollAccessPolicy {
  static bool canEnter(CurrentUser user) {
    if (!AccessPolicy.canAccessModule(user, CrmModule.hrPayroll)) return false;
    if (user.isAdmin) return true;
    return CrmPermissions.permissionsFor(CrmModule.hrPayroll)
        .where((permission) => permission.startsWith('payroll.'))
        .any((permission) => AccessPolicy.hasPermission(user, permission));
  }

  static bool has(CurrentUser user, String permission) =>
      permission.startsWith('payroll.') &&
      AccessPolicy.hasPermission(user, permission);

  static bool canRevealSalary(CurrentUser user) =>
      has(user, CrmPermissions.payrollSalaryView);

  static bool canApproveRun(CurrentUser user, {required bool isPreparer}) =>
      !isPreparer && has(user, CrmPermissions.payrollRunApprove);

  static bool canReleasePayment(CurrentUser user, {required bool isPreparer}) =>
      !isPreparer && has(user, CrmPermissions.payrollPaymentRelease);
}
