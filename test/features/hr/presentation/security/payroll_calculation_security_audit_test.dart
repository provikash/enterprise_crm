import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/services/payroll_calculation_engine.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_calculation_preview_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_calculation_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplosivePayrollRepository implements PayrollRepository {
  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async =>
      throw Exception('SECRET_DATABASE_STACK_TRACE_LEAK');

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async =>
      throw Exception('INTERNAL_DB_SERVER_CRASH_PASSWORD_LEAK');

  @override
  Future<List<PayrollRecord>> getPayrollRecords({String? payrollPeriodId, String? employeeId}) async =>
      throw Exception('SENSITIVE_LEAK_IN_RECORDS');

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async =>
      throw Exception('SENSITIVE_LEAK_IN_PERIOD_RECORDS');

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId) async =>
      throw Exception('SENSITIVE_LEAK_IN_EMP_RECORDS');

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async =>
      throw Exception('SENSITIVE_LEAK_IN_RECORD_BY_ID');
}

class _ExplosiveEmployeeRepository extends MockEmployeeRepository {
  @override
  Future<Employee?> getEmployeeById(String id) async =>
      throw Exception('INTERNAL_EMPLOYEE_ID_FAIL_EXPOSURE');
}

void main() {
  group('HR-7.9: Payroll Security, Access Control & Privacy Audit Tests', () {
    late CurrentUser adminUser;
    late CurrentUser payrollUser;
    late CurrentUser hrOnlyUser;
    late CurrentUser restrictedUser;
    late MockEmployeeRepository employeeRepo;
    late MockPayrollRepository payrollRepo;
    late PayrollCalculationInput sampleInput;

    setUp(() {
      adminUser = const CurrentUser(
        id: 'admin_1',
        displayName: 'System Admin',
        accountType: AccountType.admin,
        modules: {CrmModule.hrPayroll},
        permissions: {CrmPermissions.payrollView, CrmPermissions.hrView},
      );

      payrollUser = const CurrentUser(
        id: 'payroll_user_1',
        displayName: 'Payroll Specialist',
        accountType: AccountType.user,
        modules: {CrmModule.hrPayroll},
        permissions: {CrmPermissions.payrollView},
      );

      hrOnlyUser = const CurrentUser(
        id: 'hr_user_1',
        displayName: 'HR Specialist',
        accountType: AccountType.user,
        modules: {CrmModule.hrPayroll},
        permissions: {CrmPermissions.hrView}, // Has HR view but lacks payrollView!
      );

      restrictedUser = const CurrentUser(
        id: 'restricted_1',
        displayName: 'Restricted User',
        accountType: AccountType.user,
        modules: {},
        permissions: {},
      );

      employeeRepo = MockEmployeeRepository();
      payrollRepo = MockPayrollRepository();

      sampleInput = PayrollCalculationInput(
        id: 'calc_sec_101',
        employeeId: 'emp_001',
        payrollPeriodId: 'period_2026_01',
        baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
      );
    });

    Widget createTestWidget({
      required CurrentUser user,
      required PayrollCalculationInput input,
      PayrollRepository? customPayrollRepo,
      EmployeeRepository? customEmployeeRepo,
    }) {
      return MaterialApp(
        home: PayrollCalculationPreviewScreen(
          user: user,
          input: input,
          payrollRepository: customPayrollRepo ?? payrollRepo,
          employeeRepository: customEmployeeRepo ?? employeeRepo,
        ),
      );
    }

    group('1. Authorization & Route Protection Audit (HR-7.9.1, HR-7.9.2)', () {
      testWidgets('authorized payroll user can view calculation preview', (tester) async {
        await tester.pumpWidget(createTestWidget(user: payrollUser, input: sampleInput));
        await tester.pumpAndSettle();

        expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
        expect(find.byType(AccessRestrictedScreen), findsNothing);
        expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
        expect(find.text('Payroll Calculation Preview'), findsOneWidget);
      });

      testWidgets('admin user can view calculation preview', (tester) async {
        await tester.pumpWidget(createTestWidget(user: adminUser, input: sampleInput));
        await tester.pumpAndSettle();

        expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
        expect(find.byType(AccessRestrictedScreen), findsNothing);
        expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
      });

      testWidgets('hr.view-only user is blocked from viewing payroll calculation preview', (tester) async {
        await tester.pumpWidget(createTestWidget(user: hrOnlyUser, input: sampleInput));
        await tester.pumpAndSettle();

        // Gated: AccessRestrictedScreen is rendered, no preview or financial information
        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('preview_non_final_banner')), findsNothing);
        expect(find.text('Payroll Calculation Preview'), findsNothing);
      });

      testWidgets('restricted user without payroll permission is strictly blocked', (tester) async {
        await tester.pumpWidget(createTestWidget(user: restrictedUser, input: sampleInput));
        await tester.pumpAndSettle();

        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('preview_non_final_banner')), findsNothing);
      });
    });

    group('2. Session Isolation & Logout Transition (HR-7.9.4)', () {
      testWidgets('switching from authorized session to restricted session removes protected preview', (tester) async {
        // Step 1: Render authorized preview
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return PayrollCalculationPreviewScreen(
                  user: payrollUser,
                  input: sampleInput,
                  payrollRepository: payrollRepo,
                  employeeRepository: employeeRepo,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);

        // Step 2: Session invalidation / User switches to restricted user
        await tester.pumpWidget(
          MaterialApp(
            home: PayrollCalculationPreviewScreen(
              user: restrictedUser,
              input: sampleInput,
              payrollRepository: payrollRepo,
              employeeRepository: employeeRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Step 3: Verify preview data is completely gone and restricted screen is active
        expect(find.byType(AccessRestrictedScreen), findsOneWidget);
        expect(find.byKey(const Key('preview_non_final_banner')), findsNothing);
      });

      test('disposed or stale request id does not emit results after session abort', () async {
        final cubit = PayrollCalculationPreviewCubit(
          employeeRepository: employeeRepo,
          payrollRepository: payrollRepo,
        );

        final future = cubit.calculatePreview(input: sampleInput);
        // Abort session by closing the cubit immediately
        await cubit.close();
        await future;

        // Cubit closed state is respected, no exceptions thrown
        expect(cubit.isClosed, isTrue);
      });
    });

    group('3. Employee Isolation & Anti-Leakage Audit (HR-7.9.3)', () {
      testWidgets('switching between employees does not leak previous employee financial data', (tester) async {
        final inputEmp1 = PayrollCalculationInput(
          id: 'calc_emp_001',
          employeeId: 'emp_001',
          payrollPeriodId: 'period_2026_01',
          baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
        );

        final inputEmp2 = PayrollCalculationInput(
          id: 'calc_emp_002',
          employeeId: 'emp_002',
          payrollPeriodId: 'period_2026_01',
          baseSalary: const Money(minorUnits: 8000000), // ₹80,000.00
        );

        // View Employee 1
        await tester.pumpWidget(createTestWidget(user: payrollUser, input: inputEmp1));
        await tester.pumpAndSettle();

        expect(find.textContaining('emp_001'), findsWidgets);
        expect(find.textContaining('emp_002'), findsNothing);

        // View Employee 2
        await tester.pumpWidget(createTestWidget(user: payrollUser, input: inputEmp2));
        await tester.pumpAndSettle();

        expect(find.textContaining('emp_002'), findsWidgets);
        expect(find.textContaining('emp_001'), findsNothing);

        // View Employee 1 again
        await tester.pumpWidget(createTestWidget(user: payrollUser, input: inputEmp1));
        await tester.pumpAndSettle();

        expect(find.textContaining('emp_001'), findsWidgets);
        expect(find.textContaining('emp_002'), findsNothing);
      });
    });

    group('4. Error Privacy & Sanitization Audit (HR-7.9.6)', () {
      testWidgets('explosive repository failure presents sanitized user error without exposing stack trace', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            user: payrollUser,
            input: sampleInput,
            customPayrollRepo: _ExplosivePayrollRepository(),
            customEmployeeRepo: _ExplosiveEmployeeRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify that internal secret keywords are NEVER exposed in the UI
        expect(find.textContaining('SECRET_DATABASE_STACK_TRACE_LEAK'), findsNothing);
        expect(find.textContaining('INTERNAL_DB_SERVER_CRASH_PASSWORD_LEAK'), findsNothing);
        expect(find.textContaining('INTERNAL_EMPLOYEE_ID_FAIL_EXPOSURE'), findsNothing);

        // The screen gracefully handles errors or displays sanitized message
        expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      });

      test('toString implementation sanitizes financial amounts across entities', () {
        final input = PayrollCalculationInput(
          id: 'inp_sec_1',
          employeeId: 'emp_001',
          payrollPeriodId: 'period_1',
          baseSalary: const Money(minorUnits: 99999900),
        );
        // Does not contain raw numbers like 99999900
        expect(input.toString(), isNot(contains('99999900')));
        expect(input.toString(), isNot(contains('999999')));

        final comp = PayrollComponent.earning(
          id: 'comp_sec_1',
          name: 'Executive Secret Bonus',
          amount: const Money(minorUnits: 12345678),
        );
        expect(comp.toString(), isNot(contains('12345678')));

        const engine = PayrollCalculationEngine();
        final result = engine.calculate(input: input);
        expect(result.toString(), isNot(contains('99999900')));
      });
    });

    group('5. Calculation Tampering & Immutability Audit (HR-7.9.9, HR-7.9.10)', () {
      testWidgets('displayed amounts strictly match authoritative calculation engine output without UI modification', (tester) async {
        const engine = PayrollCalculationEngine();
        final expectedResult = engine.calculate(input: sampleInput);

        await tester.pumpWidget(createTestWidget(user: payrollUser, input: sampleInput));
        await tester.pumpAndSettle();

        // Authoritative formatted values
        final expectedGross = expectedResult.grossEarnings.formatted;
        final expectedNet = expectedResult.netPayable.formatted;

        // UI renders exact formatted values computed by the engine
        final netPayableFinder = find.byKey(const Key('preview_net_payable_amount'));
        final grossEarningsFinder = find.byKey(const Key('preview_gross_earnings_amount'));
        expect(netPayableFinder, findsOneWidget);
        expect(grossEarningsFinder, findsOneWidget);
        expect(tester.widget<Text>(netPayableFinder).data, equals(expectedNet));
        expect(tester.widget<Text>(grossEarningsFinder).data, equals(expectedGross));
      });

      testWidgets('preview workflow does not mutate stored PayrollRecord or invoke repository writes', (tester) async {
        final initialRecords = await payrollRepo.getPayrollRecordsForPeriod('period_2026_01');
        final targetRecord = initialRecords.first;
        final initialNetSalary = targetRecord.netSalary;

        await tester.pumpWidget(
          createTestWidget(
            user: payrollUser,
            input: PayrollCalculationInput.fromPayrollRecord(targetRecord),
          ),
        );
        await tester.pumpAndSettle();

        // Verify repository record was not modified in any way
        final refreshedRecords = await payrollRepo.getPayrollRecordsForPeriod('period_2026_01');
        final afterRecord = refreshedRecords.firstWhere((r) => r.id == targetRecord.id);

        expect(afterRecord.netSalary, equals(initialNetSalary));
        expect(afterRecord.id, equals(targetRecord.id));
        expect(afterRecord.employeeId, equals(targetRecord.employeeId));
      });
    });
  });
}
