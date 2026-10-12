import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/dispatch/data/repositories/mock_dispatch_repository.dart';
import 'package:enterprise_crm/features/dispatch/presentation/screens/dispatch_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.dispatch},
    permissions: {
      CrmPermissions.dispatchView,
      CrmPermissions.dispatchCreate,
    },
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

  for (final entry in viewports.entries) {
    testWidgets('renders cleanly at ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = MockDispatchRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: DispatchWorkspaceScreen(
            user: adminUser,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
    });
  }
}
