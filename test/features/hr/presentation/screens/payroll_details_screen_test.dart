import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SparsePayrollRepository extends MockPayrollRepository {
  final PayrollRecord sparseRecord;
  _SparsePayrollRepository(this.sparseRecord, {super.store});

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async {
    if (id == sparseRecord.id) return sparseRecord;
    return super.getPayrollRecordById(id);
  }
}

void main() {
  group('PayrollDetailsScreen Tests (HR-6.6)', () {
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
      required String recordId,
      PayrollRepository? customRepository,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: PayrollDetailsScreen(
          user: user,
          recordId: recordId,
          payrollRepository: customRepository ?? repository,
          employeeRepository: employeeRepository,
        ),
      );
    }

    testWidgets('unauthorized user with only hr.view is blocked by AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(user: hrOnlyUser, recordId: 'pay_rec_101'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('payroll_details_scaffold')), findsNothing);
    });

    testWidgets('allows access for admin and user with payroll.view', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(user: payrollUser, recordId: 'pay_rec_101'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsNothing);
      expect(find.byKey(const Key('payroll_details_scaffold')), findsOneWidget);
      expect(find.text('Payroll Details'), findsOneWidget);
    });

    testWidgets('renders all stored domain fields and resolved entities accurately', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(user: adminUser, recordId: 'pay_rec_101'),
      );
      await tester.pumpAndSettle();

      // Overview Card
      expect(find.byKey(const Key('payroll_details_overview_card')), findsOneWidget);
      expect(find.text('pay_rec_101'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('2026-02-01'), findsOneWidget);

      // Employee Card
      expect(find.byKey(const Key('payroll_details_employee_card')), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('emp_1'), findsOneWidget);

      // Period Card
      expect(find.byKey(const Key('payroll_details_period_card')), findsOneWidget);
      expect(find.text('January 2026'), findsOneWidget);
      expect(find.text('period_2026_01'), findsOneWidget);
      expect(find.text('2026-01-01 – 2026-01-31'), findsOneWidget);

      // Financials Card
      expect(find.byKey(const Key('payroll_details_financials_card')), findsOneWidget);
      expect(find.text('USD 85,000.00'), findsOneWidget);
      expect(find.text('USD 10,000.00'), findsOneWidget);
      expect(find.text('USD 23,000.00'), findsOneWidget);
      expect(find.text('USD 72,000.00'), findsOneWidget);

      // Remarks Card
      expect(find.byKey(const Key('payroll_details_metadata_card')), findsOneWidget);
      expect(find.text('Regular monthly disbursement'), findsOneWidget);
    });

    testWidgets('missing optional fields safely render as dash without calculation', (tester) async {
      // Add a record with missing optional compensation data
      final sparseRecord = PayrollRecord(
        id: 'pay_rec_sparse',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
      );
      final sparseRepo = _SparsePayrollRepository(sparseRecord, store: store);

      await tester.pumpWidget(
        buildTestWidget(
          user: adminUser,
          recordId: 'pay_rec_sparse',
          customRepository: sparseRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_details_scaffold')), findsOneWidget);

      // Null fields should render as '—'
      expect(find.text('—'), findsWidgets);
      // Ensure no zeros were fabricated
      expect(find.text('0.00'), findsNothing);
      expect(find.text('USD 0.00'), findsNothing);
    });

    testWidgets('displays notFound state when record ID is unknown and back button pops', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_details_btn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PayrollDetailsScreen(
                          user: adminUser,
                          recordId: 'non_existent_rec',
                          payrollRepository: repository,
                          employeeRepository: employeeRepository,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.byKey(const Key('open_details_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_details_not_found_message')),
        findsOneWidget,
      );
      expect(
        find.text('Payroll record was not found.'),
        findsOneWidget,
      );

      // Tap Back to Overview button
      await tester.tap(
        find.byKey(const Key('payroll_details_not_found_back_button')),
      );
      await tester.pumpAndSettle();

      // Popped back to initial screen
      expect(find.byKey(const Key('open_details_btn')), findsOneWidget);
    });

    testWidgets('displays error state on repository failure and retry recovers', (tester) async {
      store.setSimulatedFailure(true);

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, recordId: 'pay_rec_101'),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('payroll_details_error_message')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('payroll_details_retry_button')), findsOneWidget);

      // Clear failure and tap retry
      store.setSimulatedFailure(false);
      await tester.tap(find.byKey(const Key('payroll_details_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_details_overview_card')), findsOneWidget);
      expect(find.text('USD 85,000.00'), findsOneWidget);
    });

    testWidgets('appbar refresh button reloads details', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(user: adminUser, recordId: 'pay_rec_101'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_details_refresh_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('payroll_details_refresh_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_details_overview_card')), findsOneWidget);
    });

    testWidgets('end-to-end Overview to Details navigation and back works seamlessly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: PayrollOverviewScreen(
            user: adminUser,
            payrollRepository: repository,
            employeeRepository: employeeRepository,
            initialPeriodId: 'period_2026_01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Overview screen, tap pay_rec_101 card
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsOneWidget);
      await tester.tap(find.byKey(const Key('payroll_record_card_pay_rec_101')));
      await tester.pumpAndSettle();

      // Now on Details screen
      expect(find.byKey(const Key('payroll_details_scaffold')), findsOneWidget);
      expect(find.text('USD 85,000.00'), findsOneWidget);

      // Tap Back button in AppBar
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Returned to Overview screen
      expect(find.byKey(const Key('payroll_overview_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('payroll_record_card_pay_rec_101')), findsOneWidget);
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
          buildTestWidget(user: adminUser, recordId: 'pay_rec_101'),
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
          recordId: 'pay_rec_101',
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_details_scaffold')), findsOneWidget);
      expect(find.byKey(const Key('payroll_details_overview_card')), findsOneWidget);
    });
  });
}
