import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_details_dialog.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/widgets/attendance_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAttendanceRepository repository;

  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrViewerUser = CurrentUser(
    id: 'usr_hr_viewer',
    displayName: 'HR Viewer',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  const unauthorizedUser = CurrentUser(
    id: 'usr_sales',
    displayName: 'Sales User',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {CrmPermissions.leadViewAssigned},
  );

  setUp(() {
    repository = MockAttendanceRepository();
  });

  Widget buildTestWidget({
    required CurrentUser user,
    Size size = const Size(800, 1200),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: AttendanceListScreen(user: user, repository: repository),
      ),
    );
  }

  group('AttendanceListScreen Widget Tests', () {
    testWidgets('unauthorized user sees AccessRestrictedScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(user: unauthorizedUser));
      await tester.pumpAndSettle();

      expect(find.byType(AccessRestrictedScreen), findsOneWidget);
      expect(find.byKey(const Key('attendance_list_scaffold')), findsNothing);
    });

    testWidgets('authorized user sees attendance list and seeded records', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(user: hrViewerUser));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_list_scaffold')), findsOneWidget);
      expect(find.text('Attendance Management'), findsOneWidget);
      expect(find.byKey(const Key('attendance_search_field')), findsOneWidget);
      expect(
        find.byKey(const Key('attendance_view_mode_toggle')),
        findsOneWidget,
      );
    });

    testWidgets('search filters attendance records', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('attendance_search_field')),
        'casual leave',
      );
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceStatusBadge), findsOneWidget);
      expect(find.text('emp_1'), findsOneWidget);
      expect(find.text('emp_2'), findsNothing);
    });

    testWidgets('status filter chips filter records', (tester) async {
      await tester.pumpWidget(buildTestWidget(user: adminUser));
      await tester.pumpAndSettle();

      final absentChip = find.byKey(const Key('attendance_filter_chip_Absent'));
      expect(absentChip, findsOneWidget);
      await tester.tap(absentChip);
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceStatusBadge), findsOneWidget);
      expect(find.text('emp_2'), findsOneWidget);
      expect(find.text('emp_1'), findsNothing);
    });

    testWidgets(
      'switching to calendar view displays calendar grid and month header',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(user: adminUser));
        await tester.pumpAndSettle();

        // Tap Calendar segment in toggle
        final calendarSegment = find.text('Calendar');
        expect(calendarSegment, findsOneWidget);
        await tester.tap(calendarSegment);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('calendar_month_title')), findsOneWidget);
        expect(find.text('September 2026'), findsOneWidget);
        expect(
          find.byKey(const Key('calendar_prev_month_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('calendar_next_month_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('desktop view renders DataTable (width >= 600px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('attendance_desktop_table_scroll')),
        findsOneWidget,
      );
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('mobile view renders ListView cards (width < 600px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(400, 800)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attendance_mobile_list')), findsOneWidget);
    });

    testWidgets('tapping Details button opens AttendanceDetailsDialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      final detailsBtn = find.text('Details').first;
      await tester.ensureVisible(detailsBtn);
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceDetailsDialog), findsOneWidget);
      expect(
        find.byKey(const Key('attendance_details_dialog')),
        findsOneWidget,
      );
      expect(find.text('Attendance Details'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('attendance_details_close_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceDetailsDialog), findsNothing);
    });

    testWidgets('employee filter dropdown filters records by selected employee ID', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      // Find the employee dropdown filter
      final dropdownFinder = find.byKey(const Key('attendance_employee_filter'));
      expect(dropdownFinder, findsOneWidget);

      // Tap dropdown to open menu
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Tap Alice Johnson (emp_1)
      final empItem = find.byKey(const Key('attendance_employee_item_emp_1')).last;
      await tester.tap(empItem);
      await tester.pumpAndSettle();

      // In DataTable rows, verify only emp_1 is shown
      expect(find.text('emp_1'), findsWidgets);
      expect(find.text('emp_2'), findsNothing);
      expect(find.text('emp_3'), findsNothing);
    });

    testWidgets('calendar view month navigation handles next and previous month transitions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      // Switch to calendar view
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);

      // Navigate to previous month (August 2026)
      await tester.tap(find.byKey(const Key('calendar_prev_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);

      // Navigate to next month twice (September 2026, then October 2026)
      await tester.tap(find.byKey(const Key('calendar_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('calendar_next_month_button')));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('calendar date selection filters records and displays empty state for empty dates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 900)),
      );
      await tester.pumpAndSettle();

      // Switch to calendar
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Select Day 21 (has 3 records)
      final day21 = find.byKey(const Key('calendar_day_21'));
      expect(day21, findsOneWidget);
      await tester.tap(day21);
      await tester.pumpAndSettle();

      expect(find.text('Records for 2026-09-21'), findsOneWidget);
      expect(find.byType(AttendanceStatusBadge), findsNWidgets(3));

      // Select Day 20 (Sunday, has 0 records)
      final day20 = find.byKey(const Key('calendar_day_20'));
      expect(day20, findsOneWidget);
      await tester.tap(day20);
      await tester.pumpAndSettle();

      expect(find.text('Records for 2026-09-20'), findsOneWidget);
      expect(find.byKey(const Key('calendar_empty_state')), findsOneWidget);
      expect(
        find.text('No attendance records found for this selection.'),
        findsOneWidget,
      );
    });

    testWidgets('reset filters button clears active filters and restores full list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(user: adminUser, size: const Size(1200, 800)),
      );
      await tester.pumpAndSettle();

      // Apply Absent filter
      final absentChip = find.byKey(const Key('attendance_filter_chip_Absent'));
      await tester.tap(absentChip);
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceStatusBadge), findsOneWidget);

      // Tap Reset button
      final resetBtn = find.byKey(const Key('attendance_reset_filters_button'));
      expect(resetBtn, findsOneWidget);
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // All 12 rows restored in desktop table
      expect(find.byType(AttendanceStatusBadge), findsNWidgets(12));
    });
  });
}
