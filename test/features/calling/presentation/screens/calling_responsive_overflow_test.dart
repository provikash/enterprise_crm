import 'package:enterprise_crm/features/auth/data/repositories/mock_user_lead_link_repository.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_call_activity_repository.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_follow_up_repository.dart';
import 'package:enterprise_crm/features/calling/presentation/screens/record_call_outcome_screen.dart';
import 'package:enterprise_crm/features/calling/presentation/screens/user_calling_workspace_screen.dart';
import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callerUser = CurrentUser(
    id: 'usr_standard',
    displayName: 'Caller Rep',
    accountType: AccountType.user,
    modules: {CrmModule.calling, CrmModule.leadManagement},
    permissions: {CrmPermissions.callingUse, CrmPermissions.leadViewAssigned},
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

  group('UserCallingWorkspaceScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('UserCallingWorkspaceScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final leadRepo = MockLeadRepository();
        final linkRepo = MockUserLeadLinkRepository();
        final callActivityRepo = MockLeadCallActivityRepository();
        final followUpRepo = MockLeadFollowUpRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: UserCallingWorkspaceScreen(
              user: callerUser,
              leadRepository: leadRepo,
              linkRepository: linkRepo,
              callActivityRepository: callActivityRepo,
              leadFollowUpRepository: followUpRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('RecordCallOutcomeScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('RecordCallOutcomeScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final leadRepo = MockLeadRepository();
        final linkRepo = MockUserLeadLinkRepository();
        final callActivityRepo = MockLeadCallActivityRepository();
        final followUpRepo = MockLeadFollowUpRepository();

        await tester.pumpWidget(
          MaterialApp(
            home: RecordCallOutcomeScreen(
              user: callerUser,
              leadId: 'lead_001',
              leadRepository: leadRepo,
              linkRepository: linkRepo,
              callActivityRepository: callActivityRepo,
              followUpRepository: followUpRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });
}
