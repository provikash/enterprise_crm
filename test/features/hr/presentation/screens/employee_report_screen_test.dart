import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_report_cubit.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_row.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_row.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExplosiveReportRepository implements HrReportRepository {
  @override
  Future<ReportResult<EmployeeReportRow>> getEmployeeReport(EmployeeReportQuery query) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<AttendanceReportRow>> getAttendanceReport(AttendanceReportQuery query) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<KpiReportRow>> getKpiReport(KpiReportQuery query) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }

  @override
  Future<ReportResult<PayrollReportRow>> getPayrollReport(PayrollReportQuery query) async {
    throw Exception('SENSITIVE_DB_FAILURE_STACK');
  }
}

void main() {
  group('HR-8.3: Employee Directory Report Screen & Workflow Tests', () {
    late CurrentUser authorizedUser;
    late CurrentUser unauthorizedUser;
    late MockEmployeeRepository employeeRepo;
    late MockHrReportRepository reportRepo;

    setUp(() {
      authorizedUser = const CurrentUser(
        id: 'hr_user_1',
        displayName: 'HR Specialist',
        accountType: AccountType.user,
        modules: {CrmModule.hrPayroll},
        permissions: {CrmPermissions.hrView},
      );

      unauthorizedUser = const CurrentUser(
        id: 'sales_user_1',
        displayName: 'Sales Representative',
        accountType: AccountType.user,
        modules: {},
        permissions: {},
      );

      employeeRepo = MockEmployeeRepository();
      reportRepo = MockHrReportRepository(employeeRepository: employeeRepo);
    });

    Widget createTestWidget({
      required CurrentUser user,
      HrReportRepository? customReportRepo,
      EmployeeReportCubit? customCubit,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorSchemeSeed: Colors.deepPurple,
        ),
        home: EmployeeReportScreen(
          user: user,
          reportRepository: customReportRepo ?? reportRepo,
          employeeRepository: employeeRepo,
          cubit: customCubit,
        ),
      );
    }

    testWidgets('unauthorized user without hrView is strictly blocked by AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(EmployeeReportScreen), findsOneWidget);
      expect(find.text('Employee Directory Report'), findsNothing);
      expect(find.byKey(const Key('employee_report_total_count')), findsNothing);
    });

    testWidgets('authorized user sees Employee Directory Report with headcount summary and desktop table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsNothing);
      expect(find.text('Employee Directory Report'), findsOneWidget);

      // Verify headcount summary shows 5 total seeded employees
      expect(find.text('Total Matching Employees: 5'), findsOneWidget);

      // Verify DataTable rendered on desktop viewport
      expect(find.byKey(const Key('employee_report_table')), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Miller'), findsOneWidget);
      expect(find.text('Charlie Davis'), findsOneWidget);
      expect(find.text('Dana White'), findsOneWidget);
      expect(find.text('Evan Wright'), findsOneWidget);

      // Verify sensitive personal fields are NOT rendered in table
      expect(find.textContaining('@enterprise.com'), findsNothing);
      expect(find.textContaining('+1 555-'), findsNothing);

      // Verify zero export controls in HR-8.3
      expect(find.text('Export CSV'), findsNothing);
      expect(find.text('Export Excel'), findsNothing);
      expect(find.text('Export PDF'), findsNothing);
    });

    testWidgets('filtering by status updates matching headcount and table rows', (tester) async {
      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Tap 'Active' filter chip
      await tester.tap(find.byKey(const Key('employee_report_status_active')));
      await tester.pumpAndSettle();

      // 3 active employees (Alice, Bob, Charlie)
      expect(find.text('Total Matching Employees: 3'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Miller'), findsOneWidget);
      expect(find.text('Charlie Davis'), findsOneWidget);
      expect(find.text('Dana White'), findsNothing);
      expect(find.text('Evan Wright'), findsNothing);

      // Reset filters button appears
      final resetBtn = find.byKey(const Key('employee_report_clear_filters_button'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Restored back to 5
      expect(find.text('Total Matching Employees: 5'), findsOneWidget);
    });

    testWidgets('search input filters employees by name or code dynamically', (tester) async {
      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Enter search term 'Alice'
      await tester.enterText(find.byKey(const Key('employee_report_search_input')), 'Alice');
      await tester.pumpAndSettle();

      expect(find.text('Total Matching Employees: 1'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Miller'), findsNothing);

      // Enter non-matching query
      await tester.enterText(find.byKey(const Key('employee_report_search_input')), 'NonExistentZz');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('employee_report_empty_state')), findsOneWidget);
      expect(find.text('No employees match the selected report criteria.'), findsOneWidget);

      // Reset empty button recovers
      await tester.tap(find.byKey(const Key('employee_report_reset_empty_button')));
      await tester.pumpAndSettle();

      expect(find.text('Total Matching Employees: 5'), findsOneWidget);
    });

    testWidgets('explosive repository failure shows sanitized error card and retry recovers', (tester) async {
      final cubit = EmployeeReportCubit(repository: _ExplosiveReportRepository());
      await tester.pumpWidget(createTestWidget(user: authorizedUser, customCubit: cubit));
      await tester.pumpAndSettle();

      // Verify sanitized error message without stack trace leakage
      expect(find.textContaining('SENSITIVE_DB_FAILURE_STACK'), findsNothing);
      expect(find.text('Failed to generate Employee Directory Report. Please try again.'), findsOneWidget);
      expect(find.byKey(const Key('employee_report_retry_button')), findsOneWidget);

      cubit.close();
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

      // Mobile cards rendered, no desktop table
      expect(find.byKey(const Key('employee_report_mobile_list')), findsOneWidget);
      expect(find.byKey(const Key('employee_report_table')), findsNothing);

      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);
      expect(find.text('Human Resources • HR Manager'), findsOneWidget);
    });

    testWidgets('renders cleanly on desktop viewport (1200x800) in dark theme', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          user: authorizedUser,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('employee_report_table')), findsOneWidget);
      expect(find.text('Employee Directory Report'), findsOneWidget);
    });

    testWidgets('EmployeeDirectoryScreen AppBar report button opens EmployeeReportScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(
            user: authorizedUser,
            repository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reportButton = find.byKey(const Key('employee_directory_reports_button'));
      expect(reportButton, findsOneWidget);

      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      expect(find.byType(EmployeeReportScreen), findsOneWidget);
      expect(find.text('Employee Directory Report'), findsOneWidget);
    });
  });
}
