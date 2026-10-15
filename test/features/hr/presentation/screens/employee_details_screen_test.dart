import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_kpi_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockEmployeeRepository repository;

  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrStandardUser = CurrentUser(
    id: 'usr_hr',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_sales',
    displayName: 'Sales User',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {CrmPermissions.leadViewAssigned},
  );

  setUp(() {
    repository = MockEmployeeRepository();
  });

  Widget buildTestWidget({
    required CurrentUser user,
    required String employeeId,
  }) {
    return MaterialApp(
      home: EmployeeDetailsScreen(
        user: user,
        employeeId: employeeId,
        repository: repository,
      ),
    );
  }

  group('EmployeeDetailsScreen', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(user: unauthorizedUser, employeeId: 'emp_1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.byKey(const Key('employee_details_scaffold')), findsNothing);
    });

    testWidgets('admin user sees employee details and Edit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(user: adminUser, employeeId: 'emp_1'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('employee_details_scaffold')),
        findsOneWidget,
      );
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);
      expect(find.text('Human Resources'), findsOneWidget);
      expect(find.text('HR Manager'), findsOneWidget);
      expect(find.text('alice.johnson@enterprise.com'), findsOneWidget);
      expect(
        find.byKey(const Key('employee_details_edit_button')),
        findsOneWidget,
      );
    });

    testWidgets('standard user sees employee details but NO Edit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(user: hrStandardUser, employeeId: 'emp_1'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('employee_details_scaffold')),
        findsOneWidget,
      );
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(
        find.byKey(const Key('employee_details_edit_button')),
        findsNothing,
      );
    });

    testWidgets('shows not found view when employee does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(user: adminUser, employeeId: 'emp_invalid_999'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('employee_details_not_found_icon')),
        findsOneWidget,
      );
      expect(find.text('Employee Not Found'), findsOneWidget);
      expect(
        find.byKey(const Key('employee_details_edit_button')),
        findsNothing,
      );
    });

    testWidgets(
      'admin user sees KPI card and tapping it navigates to EmployeeKpiListScreen',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(user: adminUser, employeeId: 'emp_1'),
        );
        await tester.pumpAndSettle();

        final kpiCard = find.byKey(const Key('employee_details_kpi_card'));
        expect(kpiCard, findsOneWidget);

        await tester.tap(kpiCard);
        await tester.pumpAndSettle();

        expect(find.byType(EmployeeKpiListScreen), findsOneWidget);
      },
    );

    testWidgets(
      'admin user sees Payroll card and tapping opens compensation overview modal',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(user: adminUser, employeeId: 'emp_1'),
        );
        await tester.pumpAndSettle();

        final payrollCard = find.byKey(const Key('employee_details_payroll_card'));
        expect(payrollCard, findsOneWidget);

        await tester.tap(payrollCard);
        await tester.pumpAndSettle();

        expect(find.text('Compensation Overview'), findsOneWidget);
        expect(find.text('Monthly (30 Days)'), findsOneWidget);
        expect(find.text('INR (₹)'), findsOneWidget);
      },
    );

    testWidgets(
      'standard user without payroll permission does not see payroll card',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(user: hrStandardUser, employeeId: 'emp_1'),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_details_payroll_card')), findsNothing);
      },
    );
  });
}
