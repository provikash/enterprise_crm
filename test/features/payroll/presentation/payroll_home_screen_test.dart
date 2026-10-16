import 'package:enterprise_crm/core/config/app_config.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/payroll/presentation/screens/payroll_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const allowed = CurrentUser(
    id: 'payroll-user',
    displayName: 'Payroll User',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.payrollRunView},
  );
  const denied = CurrentUser(
    id: 'sales-user',
    displayName: 'Sales User',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
  );

  testWidgets('renders enabled foundations and disabled future modules', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PayrollHomeScreen(user: allowed, config: AppConfig.development),
      ),
    );
    expect(find.byKey(const Key('payroll_home_screen')), findsOneWidget);
    expect(find.text('Payroll workspace'), findsOneWidget);
    expect(find.text('Configuration'), findsWidgets);
    expect(find.text('Not enabled'), findsWidgets);
  });

  testWidgets('fails closed when user lacks Payroll access', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PayrollHomeScreen(user: denied, config: AppConfig.development),
      ),
    );
    expect(find.byType(AccessRestrictedScreen), findsOneWidget);
    expect(find.byKey(const Key('payroll_home_screen')), findsNothing);
  });
}
