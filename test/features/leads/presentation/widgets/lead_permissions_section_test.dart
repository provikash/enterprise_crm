import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_source.dart';
import 'package:enterprise_crm/features/leads/domain/entities/lead_status.dart';
import 'package:enterprise_crm/features/leads/presentation/widgets/lead_permissions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final assignedLead = Lead(
    id: 'lead-test-1',
    name: 'Alice Johnson',
    phone: '+1 555-0100',
    email: 'alice@example.com',
    status: const LeadStatus('Contacted'),
    source: LeadSource.manual,
    assignedUserId: 'agent-10',
    assignedUserName: 'Sarah Jenkins',
    createdAt: DateTime(2026, 1, 15, 10, 30),
    updatedAt: DateTime(2026, 1, 16, 14, 00),
  );

  final unassignedLead = Lead(
    id: 'lead-test-2',
    name: 'Charlie Brown',
    phone: '+1 555-0300',
    status: const LeadStatus('New'),
    source: LeadSource.csv,
    createdAt: DateTime(2026, 1, 12),
  );

  final adminUser = CurrentUser(
    id: 'admin-1',
    displayName: 'Super Admin',
    accountType: AccountType.admin,
    modules: CrmModule.values.toSet(),
    permissions: const {},
  );

  final assignedEditorUser = CurrentUser(
    id: 'agent-10',
    displayName: 'Sarah Jenkins',
    accountType: AccountType.user,
    modules: const {CrmModule.leadManagement},
    permissions: const {
      CrmPermissions.leadViewAssigned,
      CrmPermissions.leadUpdate,
    },
  );

  final assignedViewerUser = CurrentUser(
    id: 'agent-10',
    displayName: 'Sarah Jenkins',
    accountType: AccountType.user,
    modules: const {CrmModule.leadManagement},
    permissions: const {CrmPermissions.leadViewAssigned},
  );

  final otherStandardUser = CurrentUser(
    id: 'agent-99',
    displayName: 'Other Agent',
    accountType: AccountType.user,
    modules: const {CrmModule.leadManagement},
    permissions: const {
      CrmPermissions.leadViewAssigned,
      CrmPermissions.leadUpdate,
    },
  );

  final globalEditorUser = CurrentUser(
    id: 'agent-50',
    displayName: 'Global Lead Manager',
    accountType: AccountType.user,
    modules: const {CrmModule.leadManagement},
    permissions: const {
      CrmPermissions.leadViewAll,
      CrmPermissions.leadUpdate,
    },
  );

  final globalViewerUser = CurrentUser(
    id: 'agent-51',
    displayName: 'Global Auditor',
    accountType: AccountType.user,
    modules: const {CrmModule.leadManagement},
    permissions: const {CrmPermissions.leadViewAll},
  );

  Widget buildWidget({
    required Lead lead,
    CurrentUser? user,
    ThemeData? theme,
    Size size = const Size(800, 600),
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: SingleChildScrollView(
              child: LeadPermissionsSection(
                lead: lead,
                currentUser: user,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('LeadPermissionsSection Tests', () {
    testWidgets('renders all section fields for assigned lead', (tester) async {
      await tester.pumpWidget(buildWidget(lead: assignedLead));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lead_permissions_section')), findsOneWidget);
      expect(find.text('Access & Permissions'), findsOneWidget);
      expect(find.text('Role & Assignee Scoped'), findsOneWidget);
      expect(find.text('RBAC & Assignee Ownership'), findsOneWidget);
      expect(find.text('Admin & Assigned (Sarah Jenkins)'), findsOneWidget);
      expect(
        find.text('Admin (Full) · Assignee (Contact fields only)'),
        findsOneWidget,
      );
      expect(find.text('Admin Only (Reassign & Allocate)'), findsOneWidget);
      expect(find.text('lead.view_assigned, lead.update'), findsOneWidget);
    });

    testWidgets('renders correctly for unassigned lead', (tester) async {
      await tester.pumpWidget(buildWidget(lead: unassignedLead));
      await tester.pumpAndSettle();

      expect(find.text('Admin Only'), findsOneWidget);
      expect(
        find.text('Restricted (Admin only until assigned)'),
        findsOneWidget,
      );
      expect(find.text('Admin (Full access)'), findsOneWidget);
    });

    testWidgets('displays Administrator effective access accurately', (tester) async {
      await tester.pumpWidget(buildWidget(lead: assignedLead, user: adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Administrator (Unrestricted access)'), findsOneWidget);
      expect(find.text('Full Access'), findsOneWidget);
    });

    testWidgets('displays Assigned Editor effective access accurately', (tester) async {
      await tester.pumpWidget(
        buildWidget(lead: assignedLead, user: assignedEditorUser),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Assigned Editor (Contact info modifiable)'),
        findsOneWidget,
      );
      expect(find.text('Editor'), findsOneWidget);
    });

    testWidgets('displays Assigned Viewer effective access accurately', (tester) async {
      await tester.pumpWidget(
        buildWidget(lead: assignedLead, user: assignedViewerUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assigned Viewer (Read-only access)'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
    });

    testWidgets('displays Restricted effective access for unassigned user', (tester) async {
      await tester.pumpWidget(
        buildWidget(lead: assignedLead, user: otherStandardUser),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Restricted (Not assigned to your account)'),
        findsOneWidget,
      );
      expect(find.text('Restricted'), findsOneWidget);
    });

    testWidgets('displays Global Editor effective access accurately', (tester) async {
      await tester.pumpWidget(
        buildWidget(lead: unassignedLead, user: globalEditorUser),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Global Editor (All leads modifiable)'),
        findsOneWidget,
      );
      expect(find.text('Editor'), findsOneWidget);
    });

    testWidgets('displays Global Viewer effective access accurately', (tester) async {
      await tester.pumpWidget(
        buildWidget(lead: assignedLead, user: globalViewerUser),
      );
      await tester.pumpAndSettle();

      expect(find.text('Global Viewer (All leads readable)'), findsOneWidget);
      expect(find.text('Viewer'), findsOneWidget);
    });

    testWidgets('renders cleanly across narrow viewports without overflow', (tester) async {
      const sizes = [
        Size(320, 568),
        Size(360, 640),
        Size(768, 1024),
        Size(1200, 800),
      ];

      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildWidget(
            lead: assignedLead,
            user: assignedEditorUser,
            theme: ThemeData.dark(useMaterial3: true),
            size: size,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('lead_permissions_section')),
          findsOneWidget,
        );
      }
    });
  });
}
