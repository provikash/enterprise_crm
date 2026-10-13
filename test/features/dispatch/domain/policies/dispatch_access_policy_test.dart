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
      expect(DispatchAccessPolicy.canExportCsv(adminUser), isTrue);
      expect(DispatchAccessPolicy.canExportXlsx(adminUser), isTrue);
      expect(DispatchAccessPolicy.canExportPdf(adminUser), isTrue);
      expect(DispatchAccessPolicy.canDownloadBill(adminUser), isTrue);
      expect(DispatchAccessPolicy.canExportAny(adminUser), isTrue);
    });

    test('dispatcher user with dispatch module and empty permissions has full access (backward compat)', () {
      expect(DispatchAccessPolicy.canView(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canCreate(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canUpdateStatus(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canExportCsv(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canExportXlsx(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canExportPdf(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canDownloadBill(dispatcherUser), isTrue);
      expect(DispatchAccessPolicy.canExportAny(dispatcherUser), isTrue);
    });

    test('user without dispatch module is denied all operations', () {
      expect(DispatchAccessPolicy.canView(salesUser), isFalse);
      expect(DispatchAccessPolicy.canCreate(salesUser), isFalse);
      expect(DispatchAccessPolicy.canUpdateStatus(salesUser), isFalse);
      expect(DispatchAccessPolicy.canExportCsv(salesUser), isFalse);
      expect(DispatchAccessPolicy.canExportXlsx(salesUser), isFalse);
      expect(DispatchAccessPolicy.canExportPdf(salesUser), isFalse);
      expect(DispatchAccessPolicy.canDownloadBill(salesUser), isFalse);
      expect(DispatchAccessPolicy.canExportAny(salesUser), isFalse);
    });

    test('User 1: can only view dispatch, cannot create, edit, or download pdf', () {
      final user1 = CurrentUser(
        id: 'usr_1',
        displayName: 'User 1 (View Only)',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view'},
      );

      expect(DispatchAccessPolicy.canView(user1), isTrue);
      expect(DispatchAccessPolicy.canCreate(user1), isFalse);
      expect(DispatchAccessPolicy.canUpdateStatus(user1), isFalse);
      expect(DispatchAccessPolicy.canExportCsv(user1), isFalse);
      expect(DispatchAccessPolicy.canExportXlsx(user1), isFalse);
      expect(DispatchAccessPolicy.canExportPdf(user1), isFalse);
      expect(DispatchAccessPolicy.canDownloadBill(user1), isFalse);
      expect(DispatchAccessPolicy.canExportAny(user1), isFalse);
    });

    test('User 2: can view and download pdf/bill, cannot edit, create, or export csv/xlsx', () {
      final user2 = CurrentUser(
        id: 'usr_2',
        displayName: 'User 2 (View and PDF)',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {
          'dispatch.view',
          'dispatch.export.pdf',
          'dispatch.bill.download',
        },
      );

      expect(DispatchAccessPolicy.canView(user2), isTrue);
      expect(DispatchAccessPolicy.canDownloadBill(user2), isTrue);
      expect(DispatchAccessPolicy.canExportPdf(user2), isTrue);
      expect(DispatchAccessPolicy.canExportAny(user2), isTrue);
      expect(DispatchAccessPolicy.canCreate(user2), isFalse);
      expect(DispatchAccessPolicy.canUpdateStatus(user2), isFalse);
      expect(DispatchAccessPolicy.canExportCsv(user2), isFalse);
      expect(DispatchAccessPolicy.canExportXlsx(user2), isFalse);
    });

    test('User 3: can view and edit/create/update status, cannot export or download bill', () {
      final user3 = CurrentUser(
        id: 'usr_3',
        displayName: 'User 3 (Editor)',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {
          'dispatch.view',
          'dispatch.create',
          'dispatch.update_status',
        },
      );

      expect(DispatchAccessPolicy.canView(user3), isTrue);
      expect(DispatchAccessPolicy.canCreate(user3), isTrue);
      expect(DispatchAccessPolicy.canUpdateStatus(user3), isTrue);
      expect(DispatchAccessPolicy.canExportCsv(user3), isFalse);
      expect(DispatchAccessPolicy.canExportXlsx(user3), isFalse);
      expect(DispatchAccessPolicy.canExportPdf(user3), isFalse);
      expect(DispatchAccessPolicy.canDownloadBill(user3), isFalse);
      expect(DispatchAccessPolicy.canExportAny(user3), isFalse);
    });

    test('granular csv and excel permissions work independently', () {
      final csvOnlyUser = CurrentUser(
        id: 'usr_csv',
        displayName: 'CSV User',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.export.csv'},
      );

      expect(DispatchAccessPolicy.canExportCsv(csvOnlyUser), isTrue);
      expect(DispatchAccessPolicy.canExportXlsx(csvOnlyUser), isFalse);
      expect(DispatchAccessPolicy.canExportPdf(csvOnlyUser), isFalse);

      final xlsxOnlyUser = CurrentUser(
        id: 'usr_xlsx',
        displayName: 'Excel User',
        accountType: AccountType.user,
        modules: const {CrmModule.dispatch},
        permissions: const {'dispatch.view', 'dispatch.export.xlsx'},
      );

      expect(DispatchAccessPolicy.canExportCsv(xlsxOnlyUser), isFalse);
      expect(DispatchAccessPolicy.canExportXlsx(xlsxOnlyUser), isTrue);
      expect(DispatchAccessPolicy.canExportPdf(xlsxOnlyUser), isFalse);
    });
  });
}
