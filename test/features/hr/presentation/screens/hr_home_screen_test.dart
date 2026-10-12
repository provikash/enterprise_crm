import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_home_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_kpi_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_home_screen.dart';
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

  const hrViewerUser = CurrentUser(
    id: 'usr_hr_viewer',
    displayName: 'HR Viewer',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  const hrPayrollUser = CurrentUser(
    id: 'usr_payroll',
    displayName: 'HR Payroll Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView, CrmPermissions.payrollView},
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

  Widget buildWidget({
    required CurrentUser user,
    Size size = const Size(1000, 800),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: HrHomeScreen(user: user, repository: repository),
      ),
    );
  }

  group('HrHomeScreen Tests', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('hr_home_scaffold')), findsNothing);
    });

    testWidgets('authorized viewer sees main grid without payroll card', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: hrViewerUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_home_scaffold')), findsOneWidget);
      expect(find.text('HR & Payroll Management'), findsOneWidget);
      expect(
        find.byKey(const Key('hr_feature_card_employees')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('hr_feature_card_attendance')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('hr_feature_card_kpi')), findsOneWidget);
      expect(
        find.byKey(const Key('hr_feature_card_documents')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('hr_feature_card_payroll')), findsNothing);
    });

    testWidgets(
      'user with payrollView sees payroll card and can open overview',
      (tester) async {
        await tester.pumpWidget(buildWidget(user: hrPayrollUser));
        await tester.pumpAndSettle();

        final payrollCard = find.byKey(const Key('hr_feature_card_payroll'));
        expect(payrollCard, findsOneWidget);

        await tester.ensureVisible(payrollCard);
        await tester.tap(payrollCard);
        await tester.pumpAndSettle();

        expect(find.text('Compensation Overview'), findsOneWidget);
        expect(find.text('Monthly (30 Days)'), findsOneWidget);
        expect(find.text('INR (₹)'), findsOneWidget);
      },
    );

    testWidgets('tapping Employees navigates to EmployeeDirectoryScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hr_feature_card_employees')));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeDirectoryScreen), findsOneWidget);
    });

    testWidgets('tapping Attendance navigates to AttendanceHomeScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hr_feature_card_attendance')));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceHomeScreen), findsOneWidget);
      expect(find.byKey(const Key('attendance_home_scaffold')), findsOneWidget);
    });

    testWidgets('tapping KPI navigates to EmployeeKpiListScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hr_feature_card_kpi')));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeKpiListScreen), findsOneWidget);
    });

    testWidgets('tapping Documents navigates to EmployeeDirectoryScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(user: adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('hr_feature_card_documents')));
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeDirectoryScreen), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow across responsive widths', (
      tester,
    ) async {
      const testSizes = [
        Size(320, 568),
        Size(360, 640),
        Size(390, 844),
        Size(768, 1024),
        Size(1024, 768),
        Size(1200, 800),
        Size(1440, 900),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildWidget(user: adminUser, size: size));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('hr_home_scaffold')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: HrHomeScreen(user: adminUser, repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hr_home_scaffold')), findsOneWidget);
      expect(find.text('HR & Payroll Management'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
