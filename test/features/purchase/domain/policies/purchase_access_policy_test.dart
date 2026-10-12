import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/purchase/domain/policies/purchase_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseAccessPolicy Tests', () {
    const adminUser = CurrentUser(
      id: 'usr_admin',
      displayName: 'Admin User',
      accountType: AccountType.admin,
      modules: {CrmModule.purchase},
      permissions: {},
    );

    const purchaserUser = CurrentUser(
      id: 'usr_purchaser',
      displayName: 'Purchaser User',
      accountType: AccountType.user,
      modules: {CrmModule.purchase},
      permissions: {},
    );

    const standardUser = CurrentUser(
      id: 'usr_standard',
      displayName: 'Standard User',
      accountType: AccountType.user,
      modules: {CrmModule.leadManagement},
      permissions: {},
    );

    test('admin has full access to all purchase operations including approve', () {
      expect(PurchaseAccessPolicy.canView(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canCreate(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canApprove(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canReceive(adminUser), isTrue);
    });

    test('purchaser with purchase module can view, create and receive but NOT approve', () {
      expect(PurchaseAccessPolicy.canView(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canCreate(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canApprove(purchaserUser), isFalse); // Admin only!
      expect(PurchaseAccessPolicy.canReceive(purchaserUser), isTrue);
    });

    test('standard user without purchase module is denied all operations', () {
      expect(PurchaseAccessPolicy.canView(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canCreate(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canApprove(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canReceive(standardUser), isFalse);
    });
  });
}
