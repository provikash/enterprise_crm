import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/vendors/domain/policies/vendor_access_policy.dart';

void main() {
  group('VendorAccessPolicy Authorization Tests', () {
    test('admin has unconditional full access to all operations', () {
      const admin = CurrentUser(
        id: 'admin_1',
        displayName: 'Admin User',
        accountType: AccountType.admin,
        modules: {},
        permissions: {},
      );

      expect(VendorAccessPolicy.canView(admin), isTrue);
      expect(VendorAccessPolicy.canCreate(admin), isTrue);
      expect(VendorAccessPolicy.canEdit(admin), isTrue);
      expect(VendorAccessPolicy.canDelete(admin), isTrue);
      expect(VendorAccessPolicy.canExport(admin), isTrue);
    });

    test('user without vendorManagement module cannot access', () {
      const user = CurrentUser(
        id: 'user_1',
        displayName: 'Standard User',
        accountType: AccountType.user,
        modules: {CrmModule.leadManagement},
        permissions: {CrmPermissions.vendorView},
      );

      expect(VendorAccessPolicy.canView(user), isFalse);
      expect(VendorAccessPolicy.canCreate(user), isFalse);
    });

    test('user with vendorManagement module and fine-grained permissions', () {
      const viewOnlyUser = CurrentUser(
        id: 'user_2',
        displayName: 'Viewer User',
        accountType: AccountType.user,
        modules: {CrmModule.vendorManagement},
        permissions: {CrmPermissions.vendorView},
      );

      expect(VendorAccessPolicy.canView(viewOnlyUser), isTrue);
      expect(VendorAccessPolicy.canCreate(viewOnlyUser), isFalse);
      expect(VendorAccessPolicy.canEdit(viewOnlyUser), isFalse);
      expect(VendorAccessPolicy.canDelete(viewOnlyUser), isFalse);
      expect(VendorAccessPolicy.canExport(viewOnlyUser), isFalse);

      const managerUser = CurrentUser(
        id: 'user_3',
        displayName: 'Manager User',
        accountType: AccountType.user,
        modules: {CrmModule.vendorManagement},
        permissions: {
          CrmPermissions.vendorView,
          CrmPermissions.vendorCreate,
          CrmPermissions.vendorEdit,
          CrmPermissions.vendorExportCsv,
        },
      );

      expect(VendorAccessPolicy.canView(managerUser), isTrue);
      expect(VendorAccessPolicy.canCreate(managerUser), isTrue);
      expect(VendorAccessPolicy.canEdit(managerUser), isTrue);
      expect(VendorAccessPolicy.canDelete(managerUser), isFalse);
      expect(VendorAccessPolicy.canExport(managerUser), isTrue);
    });
  });
}
