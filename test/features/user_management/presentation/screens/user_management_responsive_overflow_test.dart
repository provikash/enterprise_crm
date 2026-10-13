import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/user_management/data/mock/mock_account_store.dart';
import 'package:enterprise_crm/features/user_management/data/repositories/mock_user_management_repository.dart';
import 'package:enterprise_crm/features/user_management/presentation/screens/create_user_screen.dart';
import 'package:enterprise_crm/features/user_management/presentation/screens/edit_user_screen.dart';
import 'package:enterprise_crm/features/user_management/presentation/screens/user_details_screen.dart';
import 'package:enterprise_crm/features/user_management/presentation/screens/users_and_access_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'System Admin',
    accountType: AccountType.admin,
    modules: {CrmModule.leadManagement},
    permissions: {},
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

  group('UsersAndAccessScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('UsersAndAccessScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockUserManagementRepository(accountStore: MockAccountStore.seeded());
        await tester.pumpWidget(
          MaterialApp(
            home: UsersAndAccessScreen(
              user: adminUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('CreateUserScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('CreateUserScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockUserManagementRepository(accountStore: MockAccountStore.seeded());
        await tester.pumpWidget(
          MaterialApp(
            home: CreateUserScreen(
              currentUser: adminUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('UserDetailsScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('UserDetailsScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockUserManagementRepository(accountStore: MockAccountStore.seeded());
        final targetUser = MockUserManagementRepository.defaultSeeds.first;

        await tester.pumpWidget(
          MaterialApp(
            home: UserDetailsScreen(
              currentUser: adminUser,
              user: targetUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('EditUserScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('EditUserScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockUserManagementRepository(accountStore: MockAccountStore.seeded());
        final targetUser = MockUserManagementRepository.defaultSeeds.first;

        await tester.pumpWidget(
          MaterialApp(
            home: EditUserScreen(
              currentUser: adminUser,
              user: targetUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });
}
