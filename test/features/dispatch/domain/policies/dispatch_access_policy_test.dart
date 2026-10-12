import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/dispatch/domain/policies/dispatch_access_policy.dart';

void main() {
  group('DispatchAccessPolicy Tests', () {
    final adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: const {},
    );

    final dispatcherUser = CurrentUser(
      id: 'usr_dispatcher',
      displayName: 'Dispatcher Dave',
      accountType: AccountType.user,
      modules: const {CrmModule.dispatch},
    );

    final salesUser = CurrentUser(
      id: 'usr_sales',
      displayName: 'Sales Sam',
      accountType: AccountType.user,
      modules: const {CrmModule.leadManagement, CrmModule.calling},
    );

    test('admin has full access to all dispatch operations', () {
      expect(DispatchAccessPolicy.canView(adminUser), isTrue);
      expect(DispatchAccessPolicy.canCreate(adminUser), isTrue);
      expect(DispatchAccessPolicy.canUpdateStatus(adminUser), isTrue);
    });

    test('dispatcher user with dispatch module has full access', () {
      expect(DispatchAccessPolicy.canView(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canCreate(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canUpdateStatus(dispatcherUser), isTrue);
    });

    test('user without dispatch module is denied all operations', () {
      expect(DispatchAccessPolicy.canView(salesUser), isFalse);
      expect(DispatchAccessPolicy.canCreate(salesUser), isFalse);
      expect(DispatchAccessPolicy.canUpdateStatus(salesUser), isFalse);
    });
  });
}
