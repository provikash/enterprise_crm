import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/payroll_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'admin',
    displayName: 'Admin',
    accountType: AccountType.admin,
  );
  const preparer = CurrentUser(
    id: 'preparer',
    displayName: 'Preparer',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {
      CrmPermissions.payrollRunView,
      CrmPermissions.payrollRunApprove,
    },
  );

  test('admin can enter Payroll', () {
    expect(PayrollAccessPolicy.canEnter(admin), isTrue);
  });

  test('module and payroll permission are both required', () {
    const noModule = CurrentUser(
      id: 'user',
      displayName: 'User',
      accountType: AccountType.user,
      permissions: {CrmPermissions.payrollRunView},
    );
    expect(PayrollAccessPolicy.canEnter(noModule), isFalse);
  });

  test('maker-checker prevents preparer approval', () {
    expect(
      PayrollAccessPolicy.canApproveRun(preparer, isPreparer: true),
      isFalse,
    );
    expect(
      PayrollAccessPolicy.canApproveRun(preparer, isPreparer: false),
      isTrue,
    );
  });
}
