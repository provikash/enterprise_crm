import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_period_selection_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/payroll_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_auth_test_fixtures.dart';

void main() {
  late MockPayrollStore store;
  late MockPayrollRepository repository;

  // Custom user with payroll view permission
  const payrollUser = CurrentUser(
    id: 'usr_payroll',
    displayName: 'Payroll Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.payrollView},
  );

  // General HR user with hr.view but NOT payroll.view
  const generalHrUser = CurrentUser(
    id: 'usr_hr',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  setUp(() {
    store = MockPayrollStore();
    repository = MockPayrollRepository(store: store);
  });

  Widget buildScreen({
    required CurrentUser user,
    String? initialPeriodId,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: brightness,
        ),
      ),
      home: PayrollPeriodSelectionScreen(
        user: user,
        payrollRepository: repository,
        initialPeriodId: initialPeriodId,
      ),
    );
  }

  group('PayrollPeriodSelectionScreen Authorization Tests (HR-6.4)', () {
    testWidgets('allows access to Admin user', (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.admin));
      await tester.pumpAndSettle();

      expect(find.byType(PayrollPeriodSelectionScreen), findsOneWidget);
      expect(find.text('Payroll Period Selection'), findsOneWidget);
      expect(find.byType(PayrollPeriodSelector), findsOneWidget);
      expect(find.byType(AccessRestrictedScreen), findsNothing);
    });

    testWidgets('allows access to user with payroll.view permission', (tester) async {
      await tester.pumpWidget(buildScreen(user: payrollUser));
      await tester.pumpAndSettle();

      expect(find.byType(PayrollPeriodSelectionScreen), findsOneWidget);
      expect(find.text('Payroll Period Selection'), findsOneWidget);
      expect(find.byType(PayrollPeriodSelector), findsOneWidget);
      expect(find.byType(AccessRestrictedScreen), findsNothing);
    });

    testWidgets('blocks user with only hr.view permission (financial privacy invariant)', (tester) async {
      await tester.pumpWidget(buildScreen(user: generalHrUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(PayrollPeriodSelector), findsNothing);
    });

    testWidgets('blocks standard user without HR/Payroll access', (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.standardUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(PayrollPeriodSelector), findsNothing);
    });
  });

  group('PayrollPeriodSelectionScreen Selection Flow Tests (HR-6.4)', () {
    testWidgets('shows placeholder card when no period is selected initially', (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.admin));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_no_period_selected_card')), findsOneWidget);
      expect(find.text('Please select a payroll period above to view details.'), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_info_card')), findsNothing);
    });

    testWidgets('shows period details when initialPeriodId is provided', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          user: MockAuthTestFixtures.admin,
          initialPeriodId: 'period_2026_01',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_info_card')), findsOneWidget);
      expect(find.byKey(const Key('info_row_id')), findsOneWidget);
      expect(find.text('period_2026_01'), findsOneWidget);
      expect(find.text('January 2026'), findsWidgets);
      expect(find.text('2026-01-01 – 2026-01-31'), findsWidgets);
      expect(find.text('2026-02-01'), findsOneWidget);
    });

    testWidgets('selecting a period from dropdown updates summary card with metadata', (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.admin));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_no_period_selected_card')), findsOneWidget);

      // Open dropdown and pick February 2026
      await tester.tap(find.byKey(const Key('payroll_period_dropdown')));
      await tester.pumpAndSettle();

      final febItem = find.byKey(const Key('payroll_period_item_period_2026_02')).last;
      await tester.tap(febItem);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_period_info_card')), findsOneWidget);
      expect(find.text('period_2026_02'), findsOneWidget);
      expect(find.text('February 2026'), findsWidgets);
      expect(find.text('2026-02-01 – 2026-02-28'), findsWidgets);
      expect(find.text('2026-03-01'), findsOneWidget);
    });

    testWidgets('refresh button triggers reload of periods', (tester) async {
      await tester.pumpWidget(buildScreen(user: MockAuthTestFixtures.admin));
      await tester.pumpAndSettle();

      final refreshBtn = find.byKey(const Key('payroll_period_refresh_button'));
      expect(refreshBtn, findsOneWidget);

      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollPeriodSelector), findsOneWidget);
    });
  });

  group('PayrollPeriodSelectionScreen Responsive & Theme Tests (HR-6.4)', () {
    testWidgets('renders cleanly in Dark theme', (tester) async {
      await tester.pumpWidget(
        buildScreen(
          user: MockAuthTestFixtures.admin,
          initialPeriodId: 'period_2026_01',
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PayrollPeriodSelectionScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_period_info_card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on all responsive viewports without overflow', (tester) async {
      final viewports = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(768, 1024),
        const Size(1200, 800),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        await tester.pumpWidget(
          buildScreen(
            user: MockAuthTestFixtures.admin,
            initialPeriodId: 'period_2026_01',
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(caughtDetails, isNull);
        expect(find.byType(PayrollPeriodSelectionScreen), findsOneWidget);
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
