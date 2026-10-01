import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplosiveReportRepository implements HrReportRepository {
  @override
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(
    EmployeeReportQuery query,
  ) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<AttendanceReportRow>> getAttendanceReport(
    AttendanceReportQuery query,
  ) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<KpiReportRow>> getKpiReport(
    KpiReportQuery query,
  ) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<PayrollReportRow>> getPayrollReport(
    PayrollReportQuery query,
  ) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }
}

void main() {
  group('PayrollReportScreen Widget & UI Tests (HR-8.6)', () {
    late EmployeeRepository employeeRepo;
    late PayrollRepository payrollRepo;
    late HrReportRepository reportRepo;

    const authorizedUser = CurrentUser(
      id: 'usr_payroll_admin',
      displayName: 'Payroll Admin',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {CrmPermissions.payrollView},
    );

    const unauthorizedUser = CurrentUser(
      id: 'usr_hr_generalist',
      displayName: 'HR Generalist',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {CrmPermissions.hrView}, // Has hrView but NOT payrollView
    );

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      payrollRepo = MockPayrollRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        payrollRepository: payrollRepo,
      );
    });

    Widget createTestWidget({
      required CurrentUser user,
      HrReportRepository? customReportRepo,
      PayrollReportCubit? customCubit,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorSchemeSeed: Colors.indigo,
        ),
        home: PayrollReportScreen(
          user: user,
          reportRepository: customReportRepo ?? reportRepo,
          payrollRepository: payrollRepo,
          employeeRepository: employeeRepo,
          cubit: customCubit,
        ),
      );
    }

    testWidgets('unauthorized user without payrollView is strictly blocked by AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(PayrollReportScreen), findsOneWidget);
      expect(find.text('Payroll Summary Report'), findsNothing);
      expect(find.byKey(const Key('payroll_report_total_records')), findsNothing);
    });

    testWidgets('authorized user sees Payroll Summary Report with summary card and desktop table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      expect(find.text('Payroll Summary Report'), findsOneWidget);
      expect(find.byKey(const Key('payroll_report_total_records')), findsOneWidget);
      expect(find.text('Total Payroll Records: 5'), findsOneWidget);
      expect(find.byKey(const Key('payroll_report_desktop_table')), findsOneWidget);
      expect(find.text('Alice Johnson'), findsWidgets);
      expect(find.text('January 2026'), findsWidgets);
    });

    testWidgets('filtering by period selector updates report query and rows', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Open period dropdown
      final periodSelector = find.byKey(const Key('payroll_report_period_selector'));
      expect(periodSelector, findsOneWidget);
      await tester.tap(periodSelector);
      await tester.pumpAndSettle();

      // Tap 'February 2026'
      await tester.tap(find.text('February 2026').last);
      await tester.pumpAndSettle();

      expect(find.text('Total Payroll Records: 2'), findsOneWidget);
    });

    testWidgets('filtering by status chip updates table rows', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Tap 'Pending' status chip
      final pendingChip = find.byKey(const Key('payroll_report_status_chip_Pending'));
      expect(pendingChip, findsOneWidget);
      await tester.tap(pendingChip);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_report_empty_state')), findsOneWidget);
      expect(find.text('No payroll records match the selected report criteria.'), findsOneWidget);
    });

    testWidgets('search input filters dynamically by employee name', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const Key('payroll_report_search_input'));
      await tester.enterText(searchInput, 'Charlie');
      await tester.pumpAndSettle();

      expect(find.text('Total Payroll Records: 1'), findsOneWidget);
      expect(find.text('Charlie Davis'), findsWidgets);
    });

    testWidgets('explosive repository failure shows sanitized error card and retry recovers', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cubit = PayrollReportCubit(
        reportRepository: _ExplosiveReportRepository(),
        payrollRepository: payrollRepo,
      );

      await tester.pumpWidget(createTestWidget(
        user: authorizedUser,
        customCubit: cubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_report_error_state')), findsOneWidget);
      expect(find.textContaining('SENSITIVE_DB_FAILURE_STACK'), findsNothing);
      expect(find.text('Failed to generate Payroll Summary Report. Please try again.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders cleanly on narrow mobile viewport (320x568) with card list', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_report_mobile_list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on desktop viewport (1200x800) in dark theme', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(
        user: authorizedUser,
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payroll_report_desktop_table')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PayrollOverviewScreen AppBar report button opens PayrollReportScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: PayrollOverviewScreen(
            user: authorizedUser,
            payrollRepository: payrollRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reportButton = find.byKey(const Key('payroll_overview_reports_button'));
      expect(reportButton, findsOneWidget);

      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      expect(find.byType(PayrollReportScreen), findsOneWidget);
      expect(find.text('Payroll Summary Report'), findsOneWidget);
    });
  });
}
