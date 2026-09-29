import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_employee_store.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Employee Payroll History Navigation & Isolation Tests (HR-6.7)', () {
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

    final payrollUser = CurrentUser(
      id: 'payroll_user_1',
      displayName: 'Payroll Officer',
      accountType: AccountType.user,
      modules: const {CrmModule.hrPayroll},
      permissions: const {CrmPermissions.hrView, CrmPermissions.payrollView},
    );

    final hrGeneralistUser = CurrentUser(
      id: 'hr_user_1',
      displayName: 'HR Generalist',
      accountType: AccountType.user,
      modules: const {CrmModule.hrPayroll},
      permissions: const {CrmPermissions.hrView},
    );

    setUp(() {
      employeeStore = MockEmployeeStore();
      employeeRepository = MockEmployeeRepository(store: employeeStore);
      payrollStore = MockPayrollStore(seedInitialData: true);
      payrollRepository = MockPayrollRepository(store: payrollStore);
    });

    testWidgets(
      'Admin in EmployeeDetailsScreen sees Payroll History tile and can navigate to history and details',
      (tester) async {
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

        // Payroll History tile must be visible
        final payrollTile = find.byKey(const Key('employee_payroll_tile'));
        expect(payrollTile, findsOneWidget);

        // Ensure tile is scrolled into view and tap
        await tester.ensureVisible(payrollTile);
        await tester.pumpAndSettle();
        await tester.tap(payrollTile);
        await tester.pumpAndSettle();

        // Verify on EmployeePayrollHistoryScreen
        expect(find.byType(EmployeePayrollHistoryScreen), findsOneWidget);
        expect(find.text('Alice Johnson — Payroll History'), findsOneWidget);

        // Tap a record to open PayrollDetailsScreen
        final recordAction = find.byKey(
          const Key('payroll_history_record_action_pay_rec_101'),
        );
        expect(recordAction, findsOneWidget);
        await tester.tap(recordAction);
        await tester.pumpAndSettle();

        // Verify on PayrollDetailsScreen
        expect(find.byType(PayrollDetailsScreen), findsOneWidget);
        expect(find.text('Payroll Details'), findsOneWidget);

        // Pop back to History
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byType(EmployeePayrollHistoryScreen), findsOneWidget);

        // Pop back to Employee Details
        final historyBackButton = find.byKey(
          const Key('employee_payroll_history_back_button'),
        );
        expect(historyBackButton, findsOneWidget);
        await tester.tap(historyBackButton);
        await tester.pumpAndSettle();

        expect(find.byType(EmployeeDetailsScreen), findsOneWidget);
      },
    );

    testWidgets(
      'HR user with only hr.view cannot see Payroll History tile in EmployeeDetailsScreen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDetailsScreen(
              user: hrGeneralistUser,
              employeeId: 'emp_1',
              repository: employeeRepository,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Documents and Attendance should be visible, but Payroll must NOT be visible
        expect(find.byKey(const Key('employee_documents_tile')), findsOneWidget);
        expect(find.byKey(const Key('employee_attendance_tile')), findsOneWidget);
        expect(find.byKey(const Key('employee_payroll_tile')), findsNothing);
        expect(find.byKey(const Key('employee_details_payroll_card')), findsNothing);
      },
    );

    testWidgets(
      'Payroll user with payroll.view sees Payroll History tile in EmployeeDetailsScreen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDetailsScreen(
              user: payrollUser,
              employeeId: 'emp_1',
              repository: employeeRepository,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_payroll_tile')), findsOneWidget);
      },
    );

    testWidgets(
      'Employee A and Employee B payroll data remain strictly isolated without cross-leakage',
      (tester) async {
        final emp1 = (await employeeRepository.getEmployeeById('emp_1'))!;
        final emp2 = (await employeeRepository.getEmployeeById('emp_2'))!;

        // Step 1: Open Employee A (emp_1)
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

        // Verify only emp_1 records are present
        expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsOneWidget);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_201')), findsOneWidget);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_102')), findsNothing);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_202')), findsNothing);

        // Step 2: Open Employee B (emp_2)
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

        // Verify only emp_2 records are present and emp_1 records are gone
        expect(find.byKey(const Key('payroll_history_card_pay_rec_102')), findsOneWidget);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_202')), findsOneWidget);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsNothing);
        expect(find.byKey(const Key('payroll_history_card_pay_rec_201')), findsNothing);
      },
    );
  });
}
