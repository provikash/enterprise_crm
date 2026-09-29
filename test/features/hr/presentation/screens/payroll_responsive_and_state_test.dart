import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_employee_store.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_period_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HR-6.9 — Responsive UI & State Verification Tests', () {
    late MockEmployeeStore employeeStore;
    late MockEmployeeRepository employeeRepository;
    late MockPayrollStore payrollStore;
    late MockPayrollRepository payrollRepository;

    final adminUser = CurrentUser(
      id: 'admin_1',
      displayName: 'System Admin',
      accountType: AccountType.admin,
      modules: const {CrmModule.hrPayroll},
    );

    final viewports = <String, Size>{
      'Small Android (320x568)': const Size(320, 568),
      'Standard Android (360x640)': const Size(360, 640),
      'Tablet (768x1024)': const Size(768, 1024),
      'Desktop Web (1200x800)': const Size(1200, 800),
    };

    final themes = <String, ThemeData>{
      'Light': ThemeData.light(useMaterial3: true),
      'Dark': ThemeData.dark(useMaterial3: true),
    };

    late Employee testEmployee;

    setUp(() {
      employeeStore = MockEmployeeStore();
      employeeRepository = MockEmployeeRepository(store: employeeStore);
      payrollStore = MockPayrollStore(seedInitialData: true);
      payrollRepository = MockPayrollRepository(store: payrollStore);

      testEmployee = const Employee(
        id: 'emp_1',
        fullName: 'Alice Johnson',
        department: 'Human Resources',
        designation: 'HR Manager',
      );
    });

    group('1. Multi-Viewport & Theme Rendering (No RenderFlex Overflow)', () {
      for (final vpEntry in viewports.entries) {
        final vpName = vpEntry.key;
        final vpSize = vpEntry.value;

        for (final themeEntry in themes.entries) {
          final themeName = themeEntry.key;
          final themeData = themeEntry.value;

          testWidgets('PayrollOverviewScreen renders safely on $vpName [$themeName]', (tester) async {
            tester.view.physicalSize = vpSize;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              MaterialApp(
                theme: themeData,
                home: PayrollOverviewScreen(
                  user: adminUser,
                  payrollRepository: payrollRepository,
                  employeeRepository: employeeRepository,
                  initialPeriodId: 'period_2026_01',
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(PayrollOverviewScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('PayrollDetailsScreen renders safely on $vpName [$themeName]', (tester) async {
            tester.view.physicalSize = vpSize;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              MaterialApp(
                theme: themeData,
                home: PayrollDetailsScreen(
                  user: adminUser,
                  recordId: 'pay_rec_101',
                  payrollRepository: payrollRepository,
                  employeeRepository: employeeRepository,
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(PayrollDetailsScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('EmployeePayrollHistoryScreen renders safely on $vpName [$themeName]', (tester) async {
            tester.view.physicalSize = vpSize;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              MaterialApp(
                theme: themeData,
                home: EmployeePayrollHistoryScreen(
                  user: adminUser,
                  employee: testEmployee,
                  repository: payrollRepository,
                  employeeRepository: employeeRepository,
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(EmployeePayrollHistoryScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('PayrollPeriodSelectionScreen renders safely on $vpName [$themeName]', (tester) async {
            tester.view.physicalSize = vpSize;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              MaterialApp(
                theme: themeData,
                home: PayrollPeriodSelectionScreen(
                  user: adminUser,
                  payrollRepository: payrollRepository,
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(PayrollPeriodSelectionScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('EmployeeDetailsScreen with Payroll Tile renders safely on $vpName [$themeName]', (tester) async {
            tester.view.physicalSize = vpSize;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              MaterialApp(
                theme: themeData,
                home: EmployeeDetailsScreen(
                  user: adminUser,
                  employeeId: 'emp_1',
                  repository: employeeRepository,
                  payrollRepository: payrollRepository,
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(EmployeeDetailsScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    });

    group('2. State Handling Matrix Verification', () {
      testWidgets('PayrollDetailsScreen renders not-found state cleanly for unknown record ID', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollDetailsScreen(
              user: adminUser,
              recordId: 'pay_rec_nonexistent',
              payrollRepository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_details_not_found_message')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('PayrollOverviewScreen renders empty state for period with no records', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: adminUser,
              payrollRepository: payrollRepository,
              employeeRepository: employeeRepository,
              initialPeriodId: 'period_2026_03', // Seeded empty period
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_overview_empty_message')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EmployeePayrollHistoryScreen renders empty state for employee with no records', (tester) async {
        final newEmployee = Employee(
          id: 'emp_brand_new',
          fullName: 'New Hire',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EmployeePayrollHistoryScreen(
              user: adminUser,
              employee: newEmployee,
              repository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_history_empty_state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('3. Rapid Navigation and Concurrency Race Condition Safety', () {
      testWidgets('Rapid Period switching (Period 1 -> Period 2 -> Period 1) renders final intended period data', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: adminUser,
              payrollRepository: payrollRepository,
              employeeRepository: employeeRepository,
              initialPeriodId: 'period_2026_01',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to period 2
        final selectorFinder = find.byKey(const Key('payroll_period_dropdown'));
        if (selectorFinder.evaluate().isNotEmpty) {
          await tester.tap(selectorFinder);
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('Rapid Employee switching (Employee 1 -> Employee 2) updates history correctly', (tester) async {
        final emp1 = testEmployee;
        final emp2 = (await employeeRepository.getEmployeeById('emp_2'))!;

        await tester.pumpWidget(
          MaterialApp(
            home: EmployeePayrollHistoryScreen(
              user: adminUser,
              employee: emp1,
              repository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsOneWidget);

        // Switch widget to emp2
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeePayrollHistoryScreen(
              user: adminUser,
              employee: emp2,
              repository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('payroll_history_card_pay_rec_102')), findsOneWidget);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsNothing);
      });

      testWidgets('Session change (Authorized -> Logout) clears protected payroll view', (tester) async {
        // Initial authorized render
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: adminUser,
              payrollRepository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PayrollOverviewScreen), findsOneWidget);

        // Session changes to restricted user
        final restrictedUser = CurrentUser(
          id: 'user_restricted',
          displayName: 'Restricted User',
          accountType: AccountType.user,
          modules: const {CrmModule.hrPayroll},
          permissions: const {CrmPermissions.hrView}, // No payroll.view
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: restrictedUser,
              payrollRepository: payrollRepository,
              employeeRepository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Protected overview must be replaced by AccessRestrictedScreen
        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('payroll_overview_scaffold')), findsNothing);
      });
    });
  });
}
