import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/mock/mock_employee_kpi_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_kpi.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_kpi_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingSummaryRepo implements EmployeeKpiRepository {
  @override
  Future<List<EmployeeKpi>> getKpis({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    throw const EmployeeKpiException('Simulated repository summary failure');
  }

  @override
  Future<List<EmployeeKpi>> getKpisForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<EmployeeKpi?> getKpiById(String id) async => null;

  @override
  Future<EmployeeKpi> createKpi({
    required String employeeId,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    String? remarks,
  }) async => throw UnimplementedError();

  @override
  Future<EmployeeKpi> updateKpi({
    required String id,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    bool clearScore = false,
    String? remarks,
    bool clearRemarks = false,
  }) async => throw UnimplementedError();
}

void main() {
  late MockEmployeeKpiStore store;
  late MockEmployeeKpiRepository kpiRepository;
  late MockEmployeeRepository employeeRepository;

  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrViewerUser = CurrentUser(
    id: 'usr_hr_viewer',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_sales',
    displayName: 'Sales Rep',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {CrmPermissions.leadViewAssigned},
  );

  setUp(() {
    store = MockEmployeeKpiStore();
    kpiRepository = MockEmployeeKpiRepository(store: store);
    employeeRepository = MockEmployeeRepository();
  });

  Widget buildTestWidget({
    required CurrentUser user,
    EmployeeKpiRepository? repo,
    Size size = const Size(1200, 800),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: EmployeeKpiSummaryScreen(
          user: user,
          kpiRepository: repo ?? kpiRepository,
          employeeRepository: employeeRepository,
        ),
      ),
    );
  }

  group('EmployeeKpiSummaryScreen Widget Tests (HR-5.7)', () {
    testWidgets('unauthorized user is blocked with AccessRestrictedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.byKey(const Key('employee_kpi_summary_scaffold')),
        findsNothing,
      );
    });

    testWidgets(
      'authorized user sees KPI summary dashboard with all approved cards',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(user: hrViewerUser));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('employee_kpi_summary_scaffold')),
          findsOneWidget,
        );
        expect(find.text('KPI Performance Summary'), findsOneWidget);

        // Verify Summary stat cards
        expect(find.byKey(const Key('kpi_summary_card_total')), findsOneWidget);
        expect(find.text('Total KPI Records'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_summary_card_total')),
            matching: find.text('5'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('kpi_summary_card_employees')),
          findsOneWidget,
        );
        expect(find.text('Employees Evaluated'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_summary_card_employees')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('kpi_summary_card_scores_recorded')),
          findsOneWidget,
        );
        expect(find.text('Scores Recorded'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_summary_card_scores_recorded')),
            matching: find.text('5'),
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('kpi_summary_card_scores_pending')),
          findsOneWidget,
        );
        expect(find.text('Pending Evaluation'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('kpi_summary_card_scores_pending')),
            matching: find.text('0'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('metric distribution card renders distinct metrics', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('kpi_summary_metric_distribution')),
        findsOneWidget,
      );
      expect(find.text('Tracked Metrics Breakdown'), findsOneWidget);
      expect(find.text('Employee Retention Rate'), findsAtLeastNWidgets(1));
      expect(find.text('Time to Hire (Days)'), findsAtLeastNWidgets(1));
      expect(find.text('Inventory Accuracy'), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'per-metric target vs actual comparisons display approved values without speculative formulas',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(user: adminUser));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('kpi_summary_comparisons_section')),
          findsOneWidget,
        );
        expect(
          find.text('Per-Metric Target vs Actual Records'),
          findsOneWidget,
        );

        // Verify target and actual values from seed fixtures are displayed
        expect(find.text('90.0'), findsAtLeastNWidgets(1));
        expect(find.text('92.5'), findsAtLeastNWidgets(1));
        expect(find.text('Score: 95.0'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('period selection modal allows switching measurement period', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      final periodBtn = find.byKey(const Key('kpi_summary_period_button'));
      expect(periodBtn, findsOneWidget);
      await tester.tap(periodBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kpi_summary_period_all')), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_summary_period_q3_2026')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kpi_summary_period_custom')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('kpi_summary_period_q3_2026')));
      await tester.pumpAndSettle();

      expect(find.text('Q3 2026 (Jul–Sep)'), findsOneWidget);
    });

    testWidgets('shows empty state when no KPI records exist for period', (
      tester,
    ) async {
      // Clear store to test empty state
      store.reset();
      final emptyRepo = MockEmployeeKpiRepository(
        store: MockEmployeeKpiStore(seedInitialData: false),
      );

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, repo: emptyRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('kpi_summary_empty_state')), findsOneWidget);
      expect(
        find.text('No KPI records found for the selected period.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('kpi_summary_reset_period_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows error state with functional retry button on repository error',
      (tester) async {
        final failingRepo = FailingSummaryRepo();
        await tester.pumpWidget(
          buildTestWidget(user: adminUser, repo: failingRepo),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load KPI summary'), findsOneWidget);
        expect(
          find.text('Simulated repository summary failure'),
          findsOneWidget,
        );

        final retryBtn = find.byKey(const Key('kpi_summary_retry_button'));
        expect(retryBtn, findsOneWidget);
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        expect(find.text('Failed to load KPI summary'), findsOneWidget);
      },
    );

    testWidgets(
      'responsive layout across multiple screen sizes without overflow',
      (tester) async {
        const screenSizes = [
          Size(320, 568),
          Size(360, 640),
          Size(768, 1024),
          Size(1200, 800),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(buildTestWidget(user: adminUser, size: size));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('employee_kpi_summary_scaffold')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
      },
    );

    testWidgets('dark theme renders cleanly without visual regression', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(user: adminUser, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('employee_kpi_summary_scaffold')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
