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

    test('admin has full access to all purchase operations', () {
      expect(PurchaseAccessPolicy.canView(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canCreate(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canApprove(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canReceive(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canExport(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canExportCsv(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canExportPdf(adminUser), isTrue);
      expect(PurchaseAccessPolicy.canDownloadBill(adminUser), isTrue);
    });

    test('purchaser with unrestricted purchase module can view, create, receive, export but not approve without permission', () {
      expect(PurchaseAccessPolicy.canView(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canCreate(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canApprove(purchaserUser), isFalse);
      expect(PurchaseAccessPolicy.canReceive(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canExport(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canExportCsv(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canExportPdf(purchaserUser), isTrue);
      expect(PurchaseAccessPolicy.canDownloadBill(purchaserUser), isTrue);
    });

    test('standard user without purchase module is denied all operations', () {
      expect(PurchaseAccessPolicy.canView(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canCreate(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canApprove(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canReceive(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canExport(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canExportCsv(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canExportPdf(standardUser), isFalse);
      expect(PurchaseAccessPolicy.canDownloadBill(standardUser), isFalse);
    });

    test('view-only user is denied create, approve, receive, and export', () {
      const viewOnly = CurrentUser(
        id: 'usr_view',
        displayName: 'View Only User',
        accountType: AccountType.user,
        modules: {CrmModule.purchase},
        permissions: {'purchase.view'},
      );

      expect(PurchaseAccessPolicy.canView(viewOnly), isTrue);
      expect(PurchaseAccessPolicy.canCreate(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canApprove(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canReceive(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canExport(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canExportCsv(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canExportPdf(viewOnly), isFalse);
      expect(PurchaseAccessPolicy.canDownloadBill(viewOnly), isFalse);
    });

    test('user with purchase.approve permission can approve orders', () {
      const approver = CurrentUser(
        id: 'usr_approver',
        displayName: 'Approver User',
        accountType: AccountType.user,
        modules: {CrmModule.purchase},
        permissions: {'purchase.view', 'purchase.approve'},
      );

      expect(PurchaseAccessPolicy.canView(approver), isTrue);
      expect(PurchaseAccessPolicy.canApprove(approver), isTrue);
      expect(PurchaseAccessPolicy.canCreate(approver), isFalse);
    });

    test('user with purchase.receive_stock permission can receive goods', () {
      const receiver = CurrentUser(
        id: 'usr_receiver',
        displayName: 'Receiver User',
        accountType: AccountType.user,
        modules: {CrmModule.purchase},
        permissions: {'purchase.view', 'purchase.receive_stock'},
      );

      expect(PurchaseAccessPolicy.canView(receiver), isTrue);
      expect(PurchaseAccessPolicy.canReceive(receiver), isTrue);
      expect(PurchaseAccessPolicy.canCreate(receiver), isFalse);
    });

    test('user with export.pdf and bill.download permissions', () {
      const pdfUser = CurrentUser(
        id: 'usr_pdf',
        displayName: 'PDF Exporter',
        accountType: AccountType.user,
        modules: {CrmModule.purchase},
        permissions: {
          'purchase.view',
          'purchase.export.pdf',
          'purchase.bill.download',
        },
      );

      expect(PurchaseAccessPolicy.canView(pdfUser), isTrue);
      expect(PurchaseAccessPolicy.canExport(pdfUser), isTrue);
      expect(PurchaseAccessPolicy.canExportPdf(pdfUser), isTrue);
      expect(PurchaseAccessPolicy.canDownloadBill(pdfUser), isTrue);
      expect(PurchaseAccessPolicy.canExportCsv(pdfUser), isFalse);
    });

    test('user with export.csv permission only', () {
      const csvUser = CurrentUser(
        id: 'usr_csv',
        displayName: 'CSV Exporter',
        accountType: AccountType.user,
        modules: {CrmModule.purchase},
        permissions: {'purchase.view', 'purchase.export.csv'},
      );

      expect(PurchaseAccessPolicy.canView(csvUser), isTrue);
      expect(PurchaseAccessPolicy.canExport(csvUser), isTrue);
      expect(PurchaseAccessPolicy.canExportCsv(csvUser), isTrue);
      expect(PurchaseAccessPolicy.canExportPdf(csvUser), isFalse);
      expect(PurchaseAccessPolicy.canDownloadBill(csvUser), isFalse);
    });
  });
}
