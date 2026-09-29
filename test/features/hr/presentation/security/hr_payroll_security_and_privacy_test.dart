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
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_details_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_overview_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_period_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplosivePayrollRepository implements PayrollRepository {
  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async {
    throw Exception('SENSITIVE_DB_URL=postgres://admin:secret@10.0.0.1:5432/payroll');
  }

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async {
    throw Exception('SENSITIVE_CONNECTION_SECRET_LEAK');
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecords({String? payrollPeriodId, String? employeeId}) async {
    throw Exception('SENSITIVE_QUERY_FAILURE_STACK');
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async {
    throw Exception('SENSITIVE_INTERNAL_SERVER_ERROR');
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId) async {
    throw Exception('SENSITIVE_TABLE_SELECT_ERROR');
  }

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async {
    throw Exception('SENSITIVE_KEY_DECRYPT_FAILURE');
  }
}

void main() {
  group('HR-6.8 — Payroll Permissions & Data Privacy Audit Tests', () {
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

    final hrOnlyUser = CurrentUser(
      id: 'hr_user_1',
      displayName: 'HR Generalist',
      accountType: AccountType.user,
      modules: const {CrmModule.hrPayroll},
      permissions: const {CrmPermissions.hrView},
    );

    final standardCrmUser = CurrentUser(
      id: 'sales_user_1',
      displayName: 'Sales Representative',
      accountType: AccountType.user,
      modules: const {CrmModule.leadManagement},
      permissions: const {CrmPermissions.leadViewAssigned},
    );

    final testEmployee = Employee(
      id: 'emp_1',
      fullName: 'Alice Johnson',
      email: 'alice.johnson@enterprise.com',
      department: 'Human Resources',
      designation: 'HR Manager',
    );

    setUp(() {
      employeeStore = MockEmployeeStore();
      employeeRepository = MockEmployeeRepository(store: employeeStore);
      payrollStore = MockPayrollStore(seedInitialData: true);
      payrollRepository = MockPayrollRepository(store: payrollStore);
    });

    group('1. Direct-Route Access Control Enforcement', () {
      testWidgets('PayrollOverviewScreen blocks user with only hr.view', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: hrOnlyUser,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('payroll_overview_scaffold')), findsNothing);
      });

      testWidgets('PayrollOverviewScreen blocks standard user without HR access', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollOverviewScreen(
              user: standardCrmUser,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('payroll_overview_scaffold')), findsNothing);
      });

      testWidgets('PayrollDetailsScreen blocks user with only hr.view', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollDetailsScreen(
              user: hrOnlyUser,
              recordId: 'pay_rec_101',
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('payroll_details_scaffold')), findsNothing);
      });

      testWidgets('PayrollPeriodSelectionScreen blocks user with only hr.view', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollPeriodSelectionScreen(
              user: hrOnlyUser,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      });

      testWidgets('EmployeePayrollHistoryScreen blocks user with only hr.view', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeePayrollHistoryScreen(
              user: hrOnlyUser,
              employee: testEmployee,
              repository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('employee_payroll_history_scaffold')), findsNothing);
      });
    });

    group('2. Entry Point Visibility and Separation from General HR', () {
      testWidgets('EmployeeDirectoryScreen hides Payroll Overview button for hr.view only user', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDirectoryScreen(
              user: hrOnlyUser,
              repository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_directory_payroll_button')), findsNothing);
      });

      testWidgets('EmployeeDirectoryScreen shows Payroll Overview button for authorized payroll user', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDirectoryScreen(
              user: payrollUser,
              repository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_directory_payroll_button')), findsOneWidget);
      });

      testWidgets('EmployeeDirectoryScreen shows Payroll Overview button for admin user', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDirectoryScreen(
              user: adminUser,
              repository: employeeRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_directory_payroll_button')), findsOneWidget);
      });

      testWidgets('EmployeeDetailsScreen hides Payroll History card for hr.view only user', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDetailsScreen(
              user: hrOnlyUser,
              employeeId: 'emp_1',
              repository: employeeRepository,
              payrollRepository: payrollRepository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('employee_payroll_tile')), findsNothing);
        expect(find.byKey(const Key('employee_details_payroll_card')), findsNothing);
      });

      testWidgets('EmployeeDetailsScreen shows Payroll History card for payroll.view user', (tester) async {
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
      });
    });

    group('3. Employee Data Privacy and Isolation', () {
      test('Employee A records cannot be retrieved via Employee B query in repository', () async {
        final recordsEmp1 = await payrollRepository.getPayrollRecordsForEmployee('emp_1');
        final recordsEmp2 = await payrollRepository.getPayrollRecordsForEmployee('emp_2');

        expect(recordsEmp1.every((r) => r.employeeId == 'emp_1'), isTrue);
        expect(recordsEmp2.every((r) => r.employeeId == 'emp_2'), isTrue);
        expect(recordsEmp1.any((r) => r.employeeId == 'emp_2'), isFalse);
        expect(recordsEmp2.any((r) => r.employeeId == 'emp_1'), isFalse);
      });

      test('Nonexistent employee returns empty record list without leaking other data', () async {
        final recordsUnknown = await payrollRepository.getPayrollRecordsForEmployee('emp_9999');
        expect(recordsUnknown, isEmpty);
      });
    });

    group('4. Sanitized Error Messaging (No Sensitive Data Leakage)', () {
      test('PayrollOverviewCubit sanitizes repository exceptions', () async {
        final explosiveRepo = _ExplosivePayrollRepository();
        final cubit = PayrollOverviewCubit(
          repository: explosiveRepo,
          initialPeriodId: 'period_2026_01',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.errorMessage, isNotNull);
        expect(cubit.state.errorMessage!.contains('secret'), isFalse);
        expect(cubit.state.errorMessage!.contains('postgres'), isFalse);
        expect(cubit.state.errorMessage!.contains('password'), isFalse);
        cubit.close();
      });

      test('PayrollDetailsCubit sanitizes repository exceptions', () async {
        final explosiveRepo = _ExplosivePayrollRepository();
        final cubit = PayrollDetailsCubit(
          repository: explosiveRepo,
          initialRecordId: 'pay_rec_101',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.errorMessage, isNotNull);
        expect(cubit.state.errorMessage!.contains('secret'), isFalse);
        expect(cubit.state.errorMessage!.contains('DECRYPT'), isFalse);
        cubit.close();
      });
    });
  });
}
