import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_calculation_input.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_component.dart';
import 'package:enterprise_crm/features/hr/domain/value_objects/money.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_calculation_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  const payrollUser = CurrentUser(
    id: 'usr_payroll',
    displayName: 'Payroll Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.payrollView},
  );

  final testInput = PayrollCalculationInput(
    id: 'calc_ui_01',
    employeeId: 'emp_1',
    payrollPeriodId: 'period_2026_01',
    baseSalary: const Money(minorUnits: 5000000), // ₹50,000.00
    unpaidLeaveDays: 2,
    components: [
      PayrollComponent.earning(
        id: 'comp_hra',
        name: 'House Rent Allowance',
        amount: const Money(minorUnits: 2500000), // ₹25,000.00
      ),
      PayrollComponent.deduction(
        id: 'comp_pf',
        name: 'Provident Fund',
        amount: const Money(minorUnits: 180000), // ₹1,800.00
      ),
      PayrollComponent.deduction(
        id: 'comp_pt',
        name: 'Professional Tax',
        amount: const Money(minorUnits: 20000), // ₹200.00
      ),
    ],
  );

  Widget buildScreen({
    required CurrentUser user,
    PayrollCalculationInput? input,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: PayrollCalculationPreviewScreen(
        user: user,
        input: input ?? testInput,
        employeeRepository: MockEmployeeRepository(),
        payrollRepository: MockPayrollRepository(),
      ),
    );
  }

  group('PayrollCalculationPreviewScreen Widget Tests (HR-7.6)', () {
    testWidgets('unauthorized user without payroll.view is blocked with AccessRestrictedScreen',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(user: MockAuthTestFixtures.standardUser),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(PayrollCalculationPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_calculation_preview_scaffold')), findsNothing);
    });

    testWidgets('authorized user sees preview screen with non-final banner and breakdown',
        (tester) async {
      await tester.pumpWidget(buildScreen(user: payrollUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_calculation_preview_scaffold')), findsOneWidget);
      expect(find.text('Payroll Calculation Preview'), findsOneWidget);

      // 1. Mandatory Non-Final Banner
      expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
      expect(find.text('PREVIEW ONLY — NON-FINAL CALCULATION'), findsOneWidget);

      // 2. Context Card
      expect(find.byKey(const Key('preview_context_card')), findsOneWidget);

      // 3. Hero Net Payable Card
      expect(find.byKey(const Key('preview_net_payable_card')), findsOneWidget);
      expect(find.byKey(const Key('preview_net_payable_amount')), findsOneWidget);

      // 4. Earnings Breakdown Card
      expect(find.byKey(const Key('preview_earnings_card')), findsOneWidget);
      expect(find.text('Earnings Breakdown'), findsOneWidget);
      expect(find.text('House Rent Allowance'), findsOneWidget);
      expect(find.byKey(const Key('preview_gross_earnings_amount')), findsOneWidget);

      // 5. Deductions Breakdown Card
      expect(find.byKey(const Key('preview_deductions_card')), findsOneWidget);
      expect(find.text('Deductions Breakdown'), findsOneWidget);
      expect(find.text('Provident Fund'), findsOneWidget);
      expect(find.text('Professional Tax'), findsOneWidget);
      expect(find.byKey(const Key('preview_total_deductions_amount')), findsOneWidget);

      // 6. Interactive Policy Selector
      expect(find.byKey(const Key('preview_policy_selector_card')), findsOneWidget);
    });

    testWidgets('interactive policy chip switching recalculates and updates deduction totals',
        (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.admin));
      await tester.pumpAndSettle();

      // Initially on 'unresolved' (LOP deferred -> total deductions = PF + PT = ₹2,000.00)
      expect(find.text('₹2,000.00'), findsOneWidget);

      // Tap 'Fixed 30 Days' policy chip
      final fixed30Chip = find.byKey(const Key('policy_chip_fixed30'));
      expect(fixed30Chip, findsOneWidget);
      await tester.tap(fixed30Chip);
      await tester.pumpAndSettle();

      // Now LOP is added: Base ₹50k, 2 days -> 50,000 * 2 / 30 = ₹3,333.33 LOP
      // Total deductions: ₹2,000 + ₹3,333.33 = ₹5,333.33
      expect(find.text('₹5,333.33'), findsOneWidget);
      expect(find.textContaining('Loss of Pay (2 days)'), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow mobile viewport (320x568) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildScreen(user: payrollUser));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('preview_scroll_view')), findsOneWidget);
    });

    testWidgets('renders cleanly on desktop viewport (1200x800) in dark theme without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildScreen(user: MockAuthTestFixtures.admin, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('preview_scroll_view')), findsOneWidget);
      expect(find.byKey(const Key('preview_non_final_banner')), findsOneWidget);
    });

    testWidgets('refresh action button triggers recalculation', (tester) async {
      await tester.pumpWidget(buildScreen(user: payrollUser));
      await tester.pumpAndSettle();

      final refreshBtn = find.byKey(const Key('preview_refresh_button'));
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preview_net_payable_amount')), findsOneWidget);
    });
  });
}
