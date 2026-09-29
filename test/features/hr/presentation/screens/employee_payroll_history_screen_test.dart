import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingPayrollHistoryRepo implements PayrollRepository {
  bool shouldFail;
  _FailingPayrollHistoryRepo({this.shouldFail = true});

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async => [];

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async => null;

  @override
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId) async {
    if (shouldFail) {
      throw const PayrollException('Simulated repository failure');
    }
    return [
      PayrollRecord(
        id: 'rec_retried',
        employeeId: employeeId,
        payrollPeriodId: 'period_2026_01',
        grossSalary: 60000.0,
        netSalary: 50000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
      ),
    ];
  }

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async => null;
}

void main() {
  group('EmployeePayrollHistoryScreen Tests (HR-6.7)', () {
    late MockPayrollStore store;
    late MockPayrollRepository repository;
    late MockEmployeeRepository employeeRepository;

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
      permissions: const {CrmPermissions.payrollView},
    );

    final hrOnlyUser = CurrentUser(
      id: 'hr_user_1',
      displayName: 'HR Generalist',
      accountType: AccountType.user,
      modules: const {CrmModule.hrPayroll},
      permissions: const {CrmPermissions.hrView},
    );

    final unauthorizedUser = CurrentUser(
      id: 'unauth_user_1',
      displayName: 'Regular Staff',
      accountType: AccountType.user,
      modules: const {CrmModule.leadManagement},
    );

    final testEmployee1 = Employee(
      id: 'emp_1',
      fullName: 'Vikash Chaurasiya',
      email: 'vikash@example.com',
      department: 'Engineering',
      designation: 'Tech Lead',
    );

    final testEmployeeNoRecords = Employee(
      id: 'emp_empty',
      fullName: 'New Hire',
      email: 'newhire@example.com',
      department: 'Marketing',
      designation: 'Associate',
    );

    setUp(() {
      store = MockPayrollStore(seedInitialData: true);
      repository = MockPayrollRepository(store: store);
      employeeRepository = MockEmployeeRepository();
    });

    testWidgets('unauthorized user without payroll.view is blocked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: hrOnlyUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(EmployeePayrollHistoryScreen), findsOneWidget);
      expect(find.byKey(const Key('employee_payroll_history_scaffold')), findsNothing);
    });

    testWidgets('unauthorized user without hr module is blocked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: unauthorizedUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('employee_payroll_history_scaffold')), findsNothing);
    });

    testWidgets('authorized payroll user can view history screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: payrollUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsNothing);
      expect(find.byKey(const Key('employee_payroll_history_scaffold')), findsOneWidget);
      expect(find.text('Vikash Chaurasiya — Payroll History'), findsOneWidget);
      expect(find.byKey(const Key('employee_payroll_history_id_badge')), findsOneWidget);
      expect(find.text('ID: emp_1'), findsOneWidget);
    });

    testWidgets('admin user can view history and populated records', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: adminUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_list')), findsOneWidget);
      // emp_1 has 2 seed records: pay_rec_101 and pay_rec_201
      expect(find.byKey(const Key('payroll_history_card_pay_rec_101')), findsOneWidget);
      expect(find.byKey(const Key('payroll_history_card_pay_rec_201')), findsOneWidget);

      // Verify period names and amounts
      expect(find.text('January 2026'), findsOneWidget);
      expect(find.text('February 2026'), findsOneWidget);
      expect(find.text('USD 72,000.00'), findsNWidgets(2));
    });

    testWidgets('empty state renders when employee has no payroll records', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: adminUser,
            employee: testEmployeeNoRecords,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_empty_state')), findsOneWidget);
      expect(find.text('No Payroll Records Found'), findsOneWidget);
      expect(find.byKey(const Key('payroll_history_list')), findsNothing);
    });

    testWidgets('error state renders on repository failure and retry works', (tester) async {
      final failingRepo = _FailingPayrollHistoryRepo(shouldFail: true);

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: adminUser,
            employee: testEmployee1,
            repository: failingRepo,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_error_icon')), findsOneWidget);
      expect(find.byKey(const Key('payroll_history_retry_button')), findsOneWidget);

      // Restore repository and tap retry
      failingRepo.shouldFail = false;
      await tester.tap(find.byKey(const Key('payroll_history_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_list')), findsOneWidget);
    });

    testWidgets('tapping record card navigates to PayrollDetailsScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: adminUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final recordCard = find.byKey(const Key('payroll_history_card_pay_rec_101'));
      expect(recordCard, findsOneWidget);

      await tester.tap(recordCard);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollDetailsScreen), findsOneWidget);
      expect(find.text('Payroll Details'), findsOneWidget);
    });

    testWidgets('refresh button in AppBar reloads history', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeePayrollHistoryScreen(
            user: adminUser,
            employee: testEmployee1,
            repository: repository,
            employeeRepository: employeeRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_list')), findsOneWidget);

      final refreshBtn = find.byKey(const Key('payroll_history_refresh_button'));
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_history_list')), findsOneWidget);
    });
  });
}
