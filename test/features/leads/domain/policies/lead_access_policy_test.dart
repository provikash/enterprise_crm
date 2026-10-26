import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_status.dart';
import 'package:enterprise_crm/features/leads/domain/policies/lead_access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adminUser = CurrentUser(
    id: 'admin-1',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const baseLeadUser = CurrentUser(
    id: 'user-1',
    displayName: 'Lead Agent',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {},
  );

  const userWithoutModule = CurrentUser(
    id: 'user-2',
    displayName: 'No Module User',
    accountType: AccountType.user,
    modules: {CrmModule.inventory},
    permissions: {
      CrmPermissions.leadViewAll,
      CrmPermissions.leadCreate,
      CrmPermissions.leadUpdate,
      CrmPermissions.leadDelete,
      CrmPermissions.leadAssign,
      CrmPermissions.leadImportCsv,
      CrmPermissions.leadImportXlsx,
      CrmPermissions.leadExportCsv,
      CrmPermissions.leadExportXlsx,
      CrmPermissions.leadExportPdf,
    },
  );

  CurrentUser createUserWithPermissions(Set<String> permissions, {String id = 'user-1'}) {
    return CurrentUser(
      id: id,
      displayName: 'Agent $id',
      accountType: AccountType.user,
      modules: const {CrmModule.leadManagement},
      permissions: permissions,
    );
  }

  final assignedLead = Lead(
    id: 'lead-1',
    name: 'Alice Johnson',
    phone: '+1 555-0100',
    email: 'alice@example.com',
    status: const LeadStatus('Contacted'),
    source: LeadSource.manual,
    assignedUserId: 'user-1',
    assignedUserName: 'Lead Agent',
    createdAt: DateTime(2026, 1, 1),
  );

  final otherAssignedLead = Lead(
    id: 'lead-2',
    name: 'Bob Smith',
    status: const LeadStatus('New'),
    source: LeadSource.excel,
    assignedUserId: 'user-99',
    createdAt: DateTime(2026, 1, 1),
  );

  final unassignedLead = Lead(
    id: 'lead-3',
    name: 'Charlie Brown',
    status: const LeadStatus('New'),
    source: LeadSource.csv,
    createdAt: DateTime(2026, 1, 1),
  );

  group('LeadAccessPolicy - Admin & Null Access', () {
    test('admin holds unrestricted authority across all operations', () {
      expect(LeadAccessPolicy.canViewAll(adminUser), isTrue);
      expect(LeadAccessPolicy.canViewAssigned(adminUser), isTrue);
      expect(LeadAccessPolicy.canViewLead(user: adminUser, lead: unassignedLead), isTrue);
      expect(LeadAccessPolicy.canViewLead(user: adminUser, lead: otherAssignedLead), isTrue);
      expect(LeadAccessPolicy.canCreate(adminUser), isTrue);
      expect(LeadAccessPolicy.canEdit(user: adminUser, lead: unassignedLead), isTrue);
      expect(LeadAccessPolicy.canDelete(user: adminUser, lead: unassignedLead), isTrue);
      expect(LeadAccessPolicy.canAssign(adminUser), isTrue);
      expect(LeadAccessPolicy.canImportCsv(adminUser), isTrue);
      expect(LeadAccessPolicy.canImportXlsx(adminUser), isTrue);
      expect(LeadAccessPolicy.canImport(adminUser), isTrue);
      expect(LeadAccessPolicy.canExportCsv(adminUser), isTrue);
      expect(LeadAccessPolicy.canExportXlsx(adminUser), isTrue);
      expect(LeadAccessPolicy.canExportPdf(adminUser), isTrue);
      expect(LeadAccessPolicy.canExport(adminUser), isTrue);
    });

    test('null user is denied across all operations', () {
      expect(LeadAccessPolicy.canViewAll(null), isFalse);
      expect(LeadAccessPolicy.canViewAssigned(null), isFalse);
      expect(LeadAccessPolicy.canViewLead(user: null, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canCreate(null), isFalse);
      expect(LeadAccessPolicy.canEdit(user: null, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canDelete(user: null, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canAssign(null), isFalse);
      expect(LeadAccessPolicy.canImportCsv(null), isFalse);
      expect(LeadAccessPolicy.canImportXlsx(null), isFalse);
      expect(LeadAccessPolicy.canImport(null), isFalse);
      expect(LeadAccessPolicy.canExportCsv(null), isFalse);
      expect(LeadAccessPolicy.canExportXlsx(null), isFalse);
      expect(LeadAccessPolicy.canExportPdf(null), isFalse);
      expect(LeadAccessPolicy.canExport(null), isFalse);
    });

    test('user without leadManagement module is denied even with permission tokens', () {
      expect(LeadAccessPolicy.canViewAll(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canViewAssigned(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canViewLead(user: userWithoutModule, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canCreate(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canEdit(user: userWithoutModule, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canDelete(user: userWithoutModule, lead: assignedLead), isFalse);
      expect(LeadAccessPolicy.canAssign(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canImportCsv(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canImportXlsx(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canExportCsv(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canExportXlsx(userWithoutModule), isFalse);
      expect(LeadAccessPolicy.canExportPdf(userWithoutModule), isFalse);
    });
  });

  group('LeadAccessPolicy - View Operations', () {
    test('canViewAll requires leadViewAll permission', () {
      final userWithViewAll = createUserWithPermissions({CrmPermissions.leadViewAll});
      final userWithAssignedOnly = createUserWithPermissions({CrmPermissions.leadViewAssigned});

      expect(LeadAccessPolicy.canViewAll(userWithViewAll), isTrue);
      expect(LeadAccessPolicy.canViewAll(userWithAssignedOnly), isFalse);
      expect(LeadAccessPolicy.canViewAll(baseLeadUser), isFalse);
    });

    test('canViewAssigned succeeds with either leadViewAssigned or leadViewAll', () {
      final userWithViewAll = createUserWithPermissions({CrmPermissions.leadViewAll});
      final userWithAssigned = createUserWithPermissions({CrmPermissions.leadViewAssigned});

      expect(LeadAccessPolicy.canViewAssigned(userWithViewAll), isTrue);
      expect(LeadAccessPolicy.canViewAssigned(userWithAssigned), isTrue);
      expect(LeadAccessPolicy.canViewAssigned(baseLeadUser), isFalse);
    });

    test('canViewLead honors global vs assignee scoped visibility', () {
      final globalViewer = createUserWithPermissions({CrmPermissions.leadViewAll});
      final assignedViewer = createUserWithPermissions(
        {CrmPermissions.leadViewAssigned},
        id: 'user-1',
      );

      // Global viewer sees any lead
      expect(LeadAccessPolicy.canViewLead(user: globalViewer, lead: assignedLead), isTrue);
      expect(LeadAccessPolicy.canViewLead(user: globalViewer, lead: otherAssignedLead), isTrue);
      expect(LeadAccessPolicy.canViewLead(user: globalViewer, lead: unassignedLead), isTrue);

      // Assigned viewer sees only their own assigned lead
      expect(LeadAccessPolicy.canViewLead(user: assignedViewer, lead: assignedLead), isTrue);
      expect(LeadAccessPolicy.canViewLead(user: assignedViewer, lead: otherAssignedLead), isFalse);
      expect(LeadAccessPolicy.canViewLead(user: assignedViewer, lead: unassignedLead), isFalse);

      // Custom linkedAssigneeId override works
      expect(
        LeadAccessPolicy.canViewLead(
          user: assignedViewer,
          lead: otherAssignedLead,
          linkedAssigneeId: 'user-99',
        ),
        isTrue,
      );
    });
  });

  group('LeadAccessPolicy - Create, Edit, Delete, Assign', () {
    test('canCreate requires leadCreate permission', () {
      final creator = createUserWithPermissions({CrmPermissions.leadCreate});
      expect(LeadAccessPolicy.canCreate(creator), isTrue);
      expect(LeadAccessPolicy.canCreate(baseLeadUser), isFalse);
    });

    test('canEdit requires leadUpdate and view access on the target lead', () {
      final editorWithViewAll = createUserWithPermissions({
        CrmPermissions.leadViewAll,
        CrmPermissions.leadUpdate,
      });
      final editorWithAssigned = createUserWithPermissions({
        CrmPermissions.leadViewAssigned,
        CrmPermissions.leadUpdate,
      }, id: 'user-1');
      final updateWithoutView = createUserWithPermissions({CrmPermissions.leadUpdate});

      expect(LeadAccessPolicy.canEdit(user: editorWithViewAll, lead: unassignedLead), isTrue);
      expect(LeadAccessPolicy.canEdit(user: editorWithViewAll, lead: otherAssignedLead), isTrue);

      expect(LeadAccessPolicy.canEdit(user: editorWithAssigned, lead: assignedLead), isTrue);
      expect(LeadAccessPolicy.canEdit(user: editorWithAssigned, lead: otherAssignedLead), isFalse);

      expect(LeadAccessPolicy.canEdit(user: updateWithoutView, lead: assignedLead), isFalse);
    });

    test('canDelete requires leadDelete and optional view access', () {
      final deleter = createUserWithPermissions({
        CrmPermissions.leadDelete,
        CrmPermissions.leadViewAssigned,
      }, id: 'user-1');
      final globalDeleter = createUserWithPermissions({
        CrmPermissions.leadDelete,
        CrmPermissions.leadViewAll,
      });

      expect(LeadAccessPolicy.canDelete(user: deleter), isTrue);
      expect(LeadAccessPolicy.canDelete(user: deleter, lead: assignedLead), isTrue);
      expect(LeadAccessPolicy.canDelete(user: deleter, lead: otherAssignedLead), isFalse);

      expect(LeadAccessPolicy.canDelete(user: globalDeleter, lead: otherAssignedLead), isTrue);
      expect(LeadAccessPolicy.canDelete(user: baseLeadUser), isFalse);
    });

    test('canAssign requires leadAssign permission', () {
      final assigner = createUserWithPermissions({CrmPermissions.leadAssign});
      expect(LeadAccessPolicy.canAssign(assigner), isTrue);
      expect(LeadAccessPolicy.canAssign(baseLeadUser), isFalse);
    });
  });

  group('LeadAccessPolicy - Import & Export Operations', () {
    test('import operations verify specific granular permissions', () {
      final csvImporter = createUserWithPermissions({CrmPermissions.leadImportCsv});
      final xlsxImporter = createUserWithPermissions({CrmPermissions.leadImportXlsx});

      expect(LeadAccessPolicy.canImportCsv(csvImporter), isTrue);
      expect(LeadAccessPolicy.canImportXlsx(csvImporter), isFalse);
      expect(LeadAccessPolicy.canImport(csvImporter), isTrue);

      expect(LeadAccessPolicy.canImportCsv(xlsxImporter), isFalse);
      expect(LeadAccessPolicy.canImportXlsx(xlsxImporter), isTrue);
      expect(LeadAccessPolicy.canImport(xlsxImporter), isTrue);

      expect(LeadAccessPolicy.canImport(baseLeadUser), isFalse);
    });

    test('export operations verify specific granular permissions', () {
      final csvExporter = createUserWithPermissions({CrmPermissions.leadExportCsv});
      final xlsxExporter = createUserWithPermissions({CrmPermissions.leadExportXlsx});
      final pdfExporter = createUserWithPermissions({CrmPermissions.leadExportPdf});

      expect(LeadAccessPolicy.canExportCsv(csvExporter), isTrue);
      expect(LeadAccessPolicy.canExportXlsx(csvExporter), isFalse);
      expect(LeadAccessPolicy.canExportPdf(csvExporter), isFalse);
      expect(LeadAccessPolicy.canExport(csvExporter), isTrue);

      expect(LeadAccessPolicy.canExportCsv(xlsxExporter), isFalse);
      expect(LeadAccessPolicy.canExportXlsx(xlsxExporter), isTrue);
      expect(LeadAccessPolicy.canExportPdf(xlsxExporter), isFalse);
      expect(LeadAccessPolicy.canExport(xlsxExporter), isTrue);

      expect(LeadAccessPolicy.canExportCsv(pdfExporter), isFalse);
      expect(LeadAccessPolicy.canExportXlsx(pdfExporter), isFalse);
      expect(LeadAccessPolicy.canExportPdf(pdfExporter), isTrue);
      expect(LeadAccessPolicy.canExport(pdfExporter), isTrue);

      expect(LeadAccessPolicy.canExport(baseLeadUser), isFalse);
    });
  });
}
