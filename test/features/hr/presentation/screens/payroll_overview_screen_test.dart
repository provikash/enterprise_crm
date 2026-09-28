import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollOverviewScreen Tests (HR-6.5)', () {
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

    setUp(() {
      store = MockPayrollStore(seedInitialData: true);
      repository = MockPayrollRepository(store: store);
      employeeRepository = MockEmployeeRepository();
    });

    Widget buildTestWidget({
      required CurrentUser user,
      String? initialPeriodId,
      ValueChanged<String>? onRecordTap,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: PayrollOverviewScreen(
          user: user,
          payrollRepository: repository,
          employeeRepository: employeeRepository,
          initialPeriodId: initialPeriodId,
          onRecordTap: onRecordTap,
        ),
      );
    }

    testWidgets('unauthorized user with only hr.view is blocked by AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: hrOnlyUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsNothing);
    });

    testWidgets('allows access for admin user and user with payroll.view', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: payrollUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsNothing);
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsOneWidget);
      expect(find.text('Payroll Overview'), findsOneWidget);
    });

    testWidgets('loads and renders payroll records for initial period on mobile view', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
        ),
      );
      await tester.pumpAndSettle();

      // Period selector is present
      expect(find.byKey(const Key('payroll_period_selector_card')), findsOneWidget);

      // Verify records are loaded
      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_102')), findsOneWidget);

      // Verify stored compensation display
      expect(find.text('USD 85,000.00'), findsOneWidget);
      expect(find.text('USD 72,000.00'), findsOneWidget);

      // Verify record count summary
      expect(find.text('3 records found'), findsOneWidget);

      // Scroll to reveal card 3
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payroll_record_card_pay_rec_103')), findsOneWidget);
    });

    testWidgets('tapping mobile card invokes onRecordTap callback with record ID', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? tappedRecordId;

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
          onRecordTap: (id) => tappedRecordId = id,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('payroll_record_card_pay_rec_101')));
      await tester.pumpAndSettle();

      expect(tappedRecordId, 'pay_rec_101');
    });

    testWidgets('shows empty state message when selected period has no records', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_03',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_overview_empty_message')),
        findsOneWidget,
      );
      expect(
        find.text('No payroll records are available for this period.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error message and retry button on repository failure', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      store.setSimulatedFailure(true);

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_overview_error_message')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('payroll_overview_retry_button')), findsOneWidget);

      // Resolve failure and tap retry
      store.setSimulatedFailure(false);
      await tester.tap(find.byKey(const Key('payroll_overview_retry_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_record_card_pay_rec_101')),
        findsOneWidget,
      );
    });

    testWidgets('search filters records in real time and clear button resets list', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
        ),
      );
      await tester.pumpAndSettle();

      // Initially 3 records
      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_102')), findsOneWidget);

      // Type search for pay_rec_101
      await tester.enterText(
        find.byKey(const Key('payroll_overview_search_field')),
        'pay_rec_101',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_102')), findsNothing);
      expect(find.text('Showing 1 of 3 records'), findsOneWidget);

      // Type search that returns 0 matches
      await tester.enterText(
        find.byKey(const Key('payroll_overview_search_field')),
        'nomatch_xyz',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_overview_no_results_message')),
        findsOneWidget,
      );

      // Clear search via clear button
      await tester.tap(
        find.byKey(const Key('payroll_overview_clear_search_empty_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_102')), findsOneWidget);
    });

    testWidgets('renders desktop DataTable on wide screen (>=600px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? tappedRecordId;

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
          onRecordTap: (id) => tappedRecordId = id,
        ),
      );
      await tester.pumpAndSettle();

      // DataTable is rendered
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('pay_rec_101'), findsOneWidget);
      expect(find.text('pay_rec_102'), findsOneWidget);

      // Ensure action button is scrolled into view in horizontal table and tap
      await tester.ensureVisible(
        find.byKey(const Key('payroll_record_action_pay_rec_101')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('payroll_record_action_pay_rec_101')),
      );
      await tester.pumpAndSettle();

      expect(tappedRecordId, 'pay_rec_101');
    });

    testWidgets('responsive layout renders without overflow across viewports', (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(768, 1024),
        const Size(1200, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildTestWidget(
            user: adminUser,
            initialPeriodId: 'period_2026_01',
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on $size');
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('renders cleanly in Dark theme', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          initialPeriodId: 'period_2026_01',
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_overview_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
    });
  });
}
