import 'package:enterprise_crm/features/auth/data/repositories/mock_user_lead_link_repository.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_call_activity_repository.dart';
import 'package:enterprise_crm/features/calling/data/repositories/mock_lead_follow_up_repository.dart';
import 'package:enterprise_crm/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:enterprise_crm/features/dashboard/presentation/screens/user_dashboard_screen.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:enterprise_crm/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:enterprise_crm/features/leads/data/repositories/mock_lead_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  group('Dispatch Navigation Tests', () {
    testWidgets('AdminDashboard navigates to DispatchWorkspaceScreen on tap', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final dispatchRepo = MockDispatchRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardScreen(
            user: MockAuthTestFixtures.admin,
            onLogout: () {},
            onOpenLeadManagement: () {},
            inventoryRepository: MockInventoryRepository(),
            dispatchRepository: dispatchRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byKey(const Key('module_card_dispatch')), findsOneWidget);

      await tester.tap(find.byKey(const Key('module_card_dispatch')));
      await tester.pumpAndSettle();

      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.text('Dispatch Management'), findsOneWidget);

      // Back navigation
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('UserDashboard navigates to DispatchWorkspaceScreen when module is assigned', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const dispatcherUser = CurrentUser(
        id: 'usr_disp_1',
        displayName: 'Dispatcher Dave',
        accountType: AccountType.user,
        modules: {CrmModule.dispatch},
        permissions: {},
      );

      final dispatchRepo = MockDispatchRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: UserDashboardScreen(
            user: dispatcherUser,
            onLogout: () {},
            userLeadLinkRepository: MockUserLeadLinkRepository(),
            leadRepository: MockLeadRepository(),
            callActivityRepository: MockLeadCallActivityRepository(),
            leadFollowUpRepository: MockLeadFollowUpRepository(),
            inventoryRepository: MockInventoryRepository(),
            dispatchRepository: dispatchRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserDashboardScreen), findsOneWidget);
      expect(find.byKey(const Key('module_card_dispatch')), findsOneWidget);

      await tester.tap(find.byKey(const Key('module_card_dispatch')));
      await tester.pumpAndSettle();

      expect(find.byType(DispatchWorkspaceScreen), findsOneWidget);
      expect(find.text('Dispatch Management'), findsOneWidget);

      // Back navigation
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(UserDashboardScreen), findsOneWidget);
    });
  });
}
