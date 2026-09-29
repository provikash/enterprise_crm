import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_employee_store.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ToggleFailurePayrollRepository extends MockPayrollRepository {
  bool failNext = false;
  _ToggleFailurePayrollRepository({super.store});

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async {
    if (failNext) {
      throw const PayrollException('Simulated temporary network failure');
    }
    return super.getPayrollRecordsForPeriod(periodId);
  }
}

void main() {
  group('HR-6.10 — Full End-to-End Payroll Workflows', () {
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

    setUp(() {
      employeeStore = MockEmployeeStore();
      employeeRepository = MockEmployeeRepository(store: employeeStore);
      payrollStore = MockPayrollStore(seedInitialData: true);
      payrollRepository = MockPayrollRepository(store: payrollStore);
    });

    testWidgets('Workflow 1 — Payroll Overview: open from directory, select period, view records', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(
            user: adminUser,
            repository: employeeRepository,
            payrollRepository: payrollRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Payroll Overview in AppBar
      final payrollBtn = find.byKey(const Key('employee_directory_payroll_button'));
      expect(payrollBtn, findsOneWidget);
      await tester.tap(payrollBtn);
      await tester.pumpAndSettle();

      // On Payroll Overview
      expect(find.byType(PayrollOverviewScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsOneWidget);

      // Select period from dropdown
      final dropdown = find.byKey(const Key('payroll_period_dropdown'));
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final item = find.byKey(const Key('payroll_period_item_period_2026_01')).last;
      await tester.tap(item);
      await tester.pumpAndSettle();

      // Verify period 1 records are visible
      expect(find.text('3 records found'), findsOneWidget);
    });

    testWidgets('Workflow 2 — Payroll Details: select record from overview, view details, back to overview', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // Tap on mobile card pay_rec_101
      final recordCard = find.byKey(const Key('payroll_record_card_pay_rec_101'));
      expect(recordCard, findsOneWidget);
      await tester.tap(recordCard);
      await tester.pumpAndSettle();

      // On Payroll Details
      expect(find.byType(PayrollDetailsScreen), findsOneWidget);
      expect(find.text('Payroll Details'), findsOneWidget);
      expect(find.byKey(const Key('payroll_details_scaffold')), findsOneWidget);

      // Verify stored compensation values are present without computation
      expect(find.text('USD 72,000.00'), findsOneWidget); // Net Salary
      expect(find.text('USD 85,000.00'), findsOneWidget); // Gross Salary

      // Pop back to overview
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollOverviewScreen), findsOneWidget);
    });

    testWidgets('Workflow 3 — Employee Payroll History: directory -> employee details -> payroll history -> record details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDetailsScreen(
            user: adminUser,
            employeeId: 'emp_1',
            repository: employeeRepository,
            payrollRepository: payrollRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to payroll tile and tap
      final payrollTile = find.byKey(const Key('employee_payroll_tile'));
      expect(payrollTile, findsOneWidget);
      await tester.ensureVisible(payrollTile);
      await tester.pumpAndSettle();
      await tester.tap(payrollTile);
      await tester.pumpAndSettle();

      // On Employee Payroll History
      expect(find.byType(EmployeePayrollHistoryScreen), findsOneWidget);
      expect(find.text('Alice Johnson — Payroll History'), findsOneWidget);

      // Open a record
      final recordAction = find.byKey(const Key('payroll_history_record_action_pay_rec_101'));
      expect(recordAction, findsOneWidget);
      await tester.tap(recordAction);
      await tester.pumpAndSettle();

      // On Details
      expect(find.byType(PayrollDetailsScreen), findsOneWidget);
    });

    testWidgets('Workflow 4 — Period Switching: Period 1 -> Period 2 -> Empty Period 3', (tester) async {
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

      expect(find.text('3 records found'), findsOneWidget);

      // Change initialPeriodId via widget update to Period 3 (empty period)
      await tester.pumpWidget(
        MaterialApp(
          home: PayrollOverviewScreen(
            user: adminUser,
            payrollRepository: payrollRepository,
            employeeRepository: employeeRepository,
            initialPeriodId: 'period_2026_03',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show empty message for period 3
      expect(find.byKey(const Key('payroll_overview_empty_message')), findsOneWidget);
    });

    testWidgets('Workflow 5 — Employee Isolation: Employee 1 and Employee 2 records never overlap', (tester) async {
      final emp1 = (await employeeRepository.getEmployeeById('emp_1'))!;
      final emp2 = (await employeeRepository.getEmployeeById('emp_2'))!;

      // Step A: Employee 1
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
      expect(find.byKey(const Key('payroll_history_card_pay_rec_201')), findsOneWidget);
      expect(find.byKey(const Key('payroll_history_card_pay_rec_102')), findsNothing);

      // Step B: Employee 2
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
      expect(find.byKey(const Key('payroll_history_card_pay_rec_202')), findsOneWidget);
      expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsNothing);
    });

    testWidgets('Workflow 6 — Authorization: Access is revoked immediately upon session switch', (tester) async {
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

      final restrictedUser = CurrentUser(
        id: 'user_restricted',
        displayName: 'HR Generalist',
        accountType: AccountType.user,
        modules: const {CrmModule.hrPayroll},
        permissions: const {CrmPermissions.hrView}, // lacks payroll.view
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

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsNothing);
    });

    testWidgets('Workflow 7 — Error Recovery: repository failure shows error state and retry restores data', (tester) async {
      final repo = _ToggleFailurePayrollRepository(store: payrollStore);
      repo.failNext = true;

      await tester.pumpWidget(
        MaterialApp(
          home: PayrollOverviewScreen(
            user: adminUser,
            payrollRepository: repo,
            employeeRepository: employeeRepository,
            initialPeriodId: 'period_2026_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.byKey(const Key('payroll_overview_error_icon')), findsOneWidget);
      expect(find.byKey(const Key('payroll_overview_retry_button')), findsOneWidget);

      // Disable failure and tap retry
      repo.failNext = false;
      await tester.tap(find.byKey(const Key('payroll_overview_retry_button')));
      await tester.pumpAndSettle();

      // Restored
      expect(find.text('3 records found'), findsOneWidget);
    });
  });
}
