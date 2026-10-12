import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_home_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/manual_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'admin',
    displayName: 'Admin',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );
  const unauthorized = CurrentUser(
    id: 'sales',
    displayName: 'Sales',
    accountType: AccountType.user,
    modules: {CrmModule.leadManagement},
    permissions: {CrmPermissions.leadViewAssigned},
  );

  Widget buildApp({
    CurrentUser user = admin,
    Size size = const Size(1000, 800),
    bool includeEmployees = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: AttendanceHomeScreen(
          user: user,
          repository: MockAttendanceRepository(),
          initialDate: DateTime.utc(2026, 9, 24),
          employeeRepository: includeEmployees
              ? MockEmployeeRepository()
              : null,
        ),
      ),
    );
  }

  testWidgets('denies direct access without HR permission', (tester) async {
    await tester.pumpWidget(buildApp(user: unauthorized));
    await tester.pumpAndSettle();

    expect(find.byType(AccessRestrictedScreen), findsOneWidget);
    expect(find.byKey(const Key('attendance_home_scaffold')), findsNothing);
  });

  testWidgets('shows date-scoped summary and only implemented features', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attendance_home_scaffold')), findsOneWidget);
    expect(find.byKey(const Key('attendance_summary_grid')), findsOneWidget);
    expect(find.text('Recorded'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('On Leave'), findsOneWidget);
    expect(find.text('Corrections'), findsNothing);
    expect(find.text('Shifts'), findsNothing);
    expect(find.text('Exceptions'), findsNothing);
  });

  testWidgets('selected-date card opens a filtered attendance list', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('attendance_feature_daily_records')));
    await tester.pumpAndSettle();

    expect(find.byType(AttendanceListScreen), findsOneWidget);
    expect(find.text('2026-09-24'), findsWidgets);
    expect(find.text('2026-09-21'), findsNothing);
  });

  testWidgets('calendar card opens attendance in calendar mode', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('attendance_feature_calendar')));
    await tester.pumpAndSettle();

    expect(find.byType(AttendanceListScreen), findsOneWidget);
    expect(find.byKey(const Key('calendar_month_title')), findsOneWidget);
  });

  testWidgets('admin sees team and manual attendance operations', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(includeEmployees: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attendance_feature_team')), findsOneWidget);
    final manualCard = find.byKey(
      const Key('attendance_feature_manual_entry'),
    );
    expect(manualCard, findsOneWidget);
    await tester.ensureVisible(manualCard);
    await tester.tap(manualCard);
    await tester.pumpAndSettle();
    expect(find.byType(ManualAttendanceScreen), findsOneWidget);
  });

  testWidgets('renders without overflow at required widths', (tester) async {
    const sizes = [
      Size(320, 568),
      Size(390, 844),
      Size(768, 1024),
      Size(1200, 800),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(buildApp(size: size));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance_home_scaffold')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
