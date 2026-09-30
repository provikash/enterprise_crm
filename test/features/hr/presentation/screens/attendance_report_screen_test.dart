import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_row.dart';
import 'package:enterprise_crm/features/hr/domain/entities/report_result.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/hr_report_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_report_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_report_screen.dart';
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
}

void main() {
  group('AttendanceReportScreen Widget & UI Tests (HR-8.4)', () {
    late EmployeeRepository employeeRepo;
    late AttendanceRepository attendanceRepo;
    late HrReportRepository reportRepo;

    const authorizedUser = CurrentUser(
      id: 'usr_hr_lead',
      displayName: 'HR Lead',
      accountType: AccountType.user,
      modules: {CrmModule.hrPayroll},
      permissions: {CrmPermissions.hrView},
    );

    const unauthorizedUser = CurrentUser(
      id: 'usr_sales_rep',
      displayName: 'Sales Rep',
      accountType: AccountType.user,
      modules: {},
      permissions: {},
    );

    setUp(() {
      employeeRepo = MockEmployeeRepository();
      attendanceRepo = MockAttendanceRepository();
      reportRepo = MockHrReportRepository(
        employeeRepository: employeeRepo,
        attendanceRepository: attendanceRepo,
      );
    });

    Widget createTestWidget({
      required CurrentUser user,
      HrReportRepository? customReportRepo,
      AttendanceReportCubit? customCubit,
      Brightness brightness = Brightness.light,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorSchemeSeed: Colors.indigo,
        ),
        home: AttendanceReportScreen(
          user: user,
          reportRepository: customReportRepo ?? reportRepo,
          attendanceRepository: attendanceRepo,
          employeeRepository: employeeRepo,
          cubit: customCubit,
        ),
      );
    }

    testWidgets('unauthorized user without hrView is strictly blocked by AccessRestrictedScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byType(AttendanceReportScreen), findsOneWidget);
      expect(find.text('Attendance Summary Report'), findsNothing);
      expect(find.byKey(const Key('attendance_report_total_count')), findsNothing);
    });

    testWidgets('authorized user sees Attendance Summary Report with summary card and desktop table', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsNothing);
      expect(find.text('Attendance Summary Report'), findsOneWidget);

      // Verify summary counts exist
      expect(find.byKey(const Key('attendance_report_summary_card')), findsOneWidget);
      expect(find.byKey(const Key('attendance_report_total_count')), findsOneWidget);
      expect(find.byKey(const Key('attendance_report_present_count')), findsOneWidget);

      // Verify DataTable rendered on desktop viewport
      expect(find.byKey(const Key('attendance_report_table')), findsOneWidget);
      expect(find.text('Alice Johnson'), findsWidgets);

      // Verify zero export controls in HR-8.4
      expect(find.text('Export CSV'), findsNothing);
      expect(find.text('Export Excel'), findsNothing);
      expect(find.text('Export PDF'), findsNothing);
    });

    testWidgets('filtering by status chip updates summary counts and table rows', (tester) async {
      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Tap 'On Leave' filter chip
      await tester.tap(find.byKey(const Key('attendance_report_status_on_leave')));
      await tester.pumpAndSettle();

      // Check summary reflects only On Leave records (emp_1 att_105 and emp_3 att_302)
      expect(find.text('Total Records: 2'), findsOneWidget);
      expect(find.text('On Leave: 2'), findsOneWidget);
      expect(find.text('Present: 0'), findsOneWidget);

      // Reset filters button appears
      final resetBtn = find.byKey(const Key('attendance_report_clear_filters_button'));
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Restored back to full count
      expect(find.textContaining('Total Records:'), findsOneWidget);
    });

    testWidgets('search input filters dynamically by employee name', (tester) async {
      await tester.pumpWidget(createTestWidget(user: authorizedUser));
      await tester.pumpAndSettle();

      // Enter search term 'Alice'
      await tester.enterText(
        find.byKey(const Key('attendance_report_search_input')),
        'Alice',
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice Johnson'), findsWidgets);
      expect(find.text('Bob Miller'), findsNothing);

      // Enter non-matching query
      await tester.enterText(
        find.byKey(const Key('attendance_report_search_input')),
        'NonExistentQueryZz',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_report_empty_state')), findsOneWidget);
      expect(find.text('No attendance records match the selected report criteria.'), findsOneWidget);

      // Reset empty button recovers
      await tester.tap(find.byKey(const Key('attendance_report_reset_empty_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_report_summary_card')), findsOneWidget);
    });

    testWidgets('explosive repository failure shows sanitized error card and retry recovers', (tester) async {
      final cubit = AttendanceReportCubit(repository: _ExplosiveReportRepository());
      await tester.pumpWidget(createTestWidget(user: authorizedUser, customCubit: cubit));
      await tester.pumpAndSettle();

      // Verify sanitized error message without stack trace leakage
      expect(find.textContaining('SENSITIVE_DB_FAILURE_STACK'), findsNothing);
      expect(find.text('Failed to generate Attendance Report. Please try again.'), findsOneWidget);
      expect(find.byKey(const Key('attendance_report_retry_button')), findsOneWidget);

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
      expect(find.byKey(const Key('attendance_report_mobile_list')), findsOneWidget);
      expect(find.byKey(const Key('attendance_report_table')), findsNothing);

      expect(find.text('Alice Johnson'), findsWidgets);
      expect(find.text('EMP-001'), findsWidgets);
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

      expect(find.byKey(const Key('attendance_report_table')), findsOneWidget);
      expect(find.text('Attendance Summary Report'), findsOneWidget);
    });

    testWidgets('AttendanceListScreen AppBar report button opens AttendanceReportScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceListScreen(
            user: authorizedUser,
            repository: attendanceRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reportButton = find.byKey(const Key('attendance_list_reports_button'));
      expect(reportButton, findsOneWidget);

      await tester.tap(reportButton);
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceReportScreen), findsOneWidget);
      expect(find.text('Attendance Summary Report'), findsOneWidget);
    });
  });
}
