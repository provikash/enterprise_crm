import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_payroll_history_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_calculation_preview_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authorizedUser = CurrentUser(
    id: 'usr_payroll_admin',
    displayName: 'Payroll Admin',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.payrollView},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_standard',
    displayName: 'Standard User',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {},
  );

  late MockPayrollRepository payrollRepo;
  late MockEmployeeRepository employeeRepo;

  setUp(() {
    payrollRepo = MockPayrollRepository();
    employeeRepo = MockEmployeeRepository();
  });

  Widget buildTestWidget(Widget child, {Size size = const Size(1200, 800)}) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('HR-7.8: Payroll Integration (Overview -> Preview)', () {
    testWidgets('authorized user can trigger calculation preview directly from Overview table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestWidget(
          PayrollOverviewScreen(
            user: authorizedUser,
            payrollRepository: payrollRepo,
            employeeRepository: employeeRepo,
            initialPeriodId: 'period_2026_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find preview button for the first record in active period (period_2026_01)
      final records = await payrollRepo.getPayrollRecordsForPeriod('period_2026_01');
      final targetRecord = records.first;
      final previewButton = find.byKey(Key('payroll_overview_preview_button_${targetRecord.id}'));
      expect(previewButton, findsOneWidget);

      // Tap preview button
      await tester.ensureVisible(previewButton);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      // Verify that PayrollCalculationPreviewScreen is displayed
      expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);

      // Verify employee identity and period are preserved
      expect(find.textContaining(targetRecord.employeeId), findsWidgets);

      // Back navigation returns to Overview cleanly
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollOverviewScreen), findsOneWidget);
    });

    testWidgets('mobile card layout allows triggering calculation preview directly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestWidget(
          PayrollOverviewScreen(
            user: authorizedUser,
            payrollRepository: payrollRepo,
            employeeRepository: employeeRepo,
            initialPeriodId: 'period_2026_01',
          ),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      final records = await payrollRepo.getPayrollRecordsForPeriod('period_2026_01');
      final targetRecord = records.first;
      final previewButton = find.byKey(Key('payroll_overview_preview_button_${targetRecord.id}'));
      expect(previewButton, findsOneWidget);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
    });
  });

  group('HR-7.8: Payroll Integration (Details -> Preview)', () {
    testWidgets('Details screen provides prominent Preview Calculation actions that preserve record context', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final records = await payrollRepo.getPayrollRecordsForPeriod('period_2026_01');
      final targetRecord = records.first;

      await tester.pumpWidget(
        buildTestWidget(
          PayrollDetailsScreen(
            user: authorizedUser,
            recordId: targetRecord.id,
            payrollRepository: payrollRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both AppBar action and Financials card button exist
      final appbarPreviewButton = find.byKey(const Key('payroll_details_preview_calculation_action'));
      final cardPreviewButton = find.byKey(const Key('payroll_details_preview_calculation_button'));

      expect(appbarPreviewButton, findsOneWidget);
      expect(cardPreviewButton, findsOneWidget);

      // Verify stored record values are present before navigating
      expect(find.text('Stored Compensation Breakdown'), findsOneWidget);

      // Tap AppBar preview action
      await tester.tap(appbarPreviewButton);
      await tester.pumpAndSettle();

      // Verify preview screen loaded
      expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
      expect(find.textContaining(targetRecord.employeeId), findsWidgets);

      // Navigate back to Details
      final backButton = find.byTooltip('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollDetailsScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_details_financials_card')), findsOneWidget);
    });
  });

  group('HR-7.8: Payroll Integration (Employee History -> Preview)', () {
    testWidgets('Employee History allows direct preview and isolates employee context', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const employee1 = Employee(
        id: 'emp_1',
        fullName: 'Alice Smith',
        email: 'alice@example.com',
        employmentStatus: EmploymentStatus.active,
      );

      await tester.pumpWidget(
        buildTestWidget(
          EmployeePayrollHistoryScreen(
            user: authorizedUser,
            employee: employee1,
            repository: payrollRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final empRecords = await payrollRepo.getPayrollRecordsForEmployee('emp_1');
      expect(empRecords.isNotEmpty, isTrue);
      final targetRecord = empRecords.first;

      final previewButton = find.byKey(Key('payroll_history_preview_button_${targetRecord.id}'));
      expect(previewButton, findsOneWidget);

      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      expect(find.textContaining('emp_1'), findsWidgets);
    });
  });

  group('HR-7.8: Immutability & Read-Only Invariant', () {
    testWidgets('generating calculation previews does not mutate stored PayrollRecord or repository', (tester) async {
      final recordsBefore = await payrollRepo.getPayrollRecords();
      final initialCount = recordsBefore.length;

      final targetRecord = recordsBefore.first;

      await tester.pumpWidget(
        buildTestWidget(
          PayrollDetailsScreen(
            user: authorizedUser,
            recordId: targetRecord.id,
            payrollRepository: payrollRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Launch preview
      await tester.tap(find.byKey(const Key('payroll_details_preview_calculation_button')));
      await tester.pumpAndSettle();

      // Switch attendance proration policy on preview screen
      final fixed30Chip = find.byKey(const Key('policy_chip_fixed30'));
      if (fixed30Chip.evaluate().isNotEmpty) {
        await tester.tap(fixed30Chip);
        await tester.pumpAndSettle();
      }

      // Return back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Verify repository records remain exactly untouched
      final recordsAfter = await payrollRepo.getPayrollRecords();
      expect(recordsAfter.length, equals(initialCount));
      for (var i = 0; i < recordsBefore.length; i++) {
        expect(recordsAfter[i].id, equals(recordsBefore[i].id));
        expect(recordsAfter[i].grossSalary, equals(recordsBefore[i].grossSalary));
        expect(recordsAfter[i].netSalary, equals(recordsBefore[i].netSalary));
        expect(recordsAfter[i].paymentStatus, equals(recordsBefore[i].paymentStatus));
      }
    });
  });

  group('HR-7.8: Authorization & Security Guard', () {
    testWidgets('unauthorized user cannot view Details or trigger Preview', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PayrollDetailsScreen(
            user: unauthorizedUser,
            recordId: 'rec_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_details_preview_calculation_button')), findsNothing);
    });
  });
}
