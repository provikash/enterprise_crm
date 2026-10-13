import 'package:enterprise_crm/features/auth/data/repositories/mock_user_lead_link_repository.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_call_activity_repository.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_follow_up_repository.dart';
import 'package:enterprise_crm/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:enterprise_crm/features/dashboard/presentation/screens/user_dashboard_screen.dart';
import 'package:enterprise_crm/features/dashboard/presentation/screens/user_lead_workspace_screen.dart';
import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'System Admin',
    accountType: AccountType.admin,
    modules: {CrmModule.leadManagement, CrmModule.dispatch, CrmModule.inventory},
    permissions: {},
  );

  const standardUser = CurrentUser(
    id: 'usr_user',
    displayName: 'Sales Rep',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement, CrmModule.calling},
    permissions: {CrmPermissions.leadViewAssigned, CrmPermissions.callingUse},
  );

  final viewports = <String, Size>{
    'Size(510, 230)': const Size(510, 230),
    'Size(400, 445)': const Size(400, 445),
    'Size(400, 800)': const Size(400, 800),
    'Size(320, 568)': const Size(320, 568),
    'Size(600, 350)': const Size(600, 350),
    'Size(700, 400)': const Size(700, 400),
    'Size(800, 400)': const Size(800, 400),
    'Size(1200, 800)': const Size(1200, 800),
  };

  group('AdminDashboardScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('AdminDashboardScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: AdminDashboardScreen(
              user: adminUser,
              onLogout: () {},
              onOpenLeadManagement: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('UserDashboardScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('UserDashboardScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final linkRepo = MockUserLeadLinkRepository();
        final leadRepo = MockLeadRepository();
        final callRepo = MockLeadCallActivityRepository();
        final followUpRepo = MockLeadFollowUpRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: UserDashboardScreen(
              user: standardUser,
              onLogout: () {},
              userLeadLinkRepository: linkRepo,
              leadRepository: leadRepo,
              callActivityRepository: callRepo,
              leadFollowUpRepository: followUpRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('UserLeadWorkspaceScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('UserLeadWorkspaceScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final linkRepo = MockUserLeadLinkRepository();
        final leadRepo = MockLeadRepository();
        final callRepo = MockLeadCallActivityRepository();
        final followUpRepo = MockLeadFollowUpRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: UserLeadWorkspaceScreen(
              user: standardUser,
              linkRepository: linkRepo,
              leadRepository: leadRepo,
              callActivityRepository: callRepo,
              leadFollowUpRepository: followUpRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });
}
