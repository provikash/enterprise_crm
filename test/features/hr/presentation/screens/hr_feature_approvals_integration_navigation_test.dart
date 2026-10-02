import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/payroll_overview_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/pending_approvals_screen.dart';

void main() {
  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.hrPayroll, CrmModule.approvalsNotifications},
    permissions: {},
  );

  group('HR Feature Approvals Navigation Integration Tests (HR-9.6)', () {
    testWidgets('AttendanceListScreen approvals button navigates to PendingApprovalsScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final attendanceRepo = MockAttendanceRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceListScreen(
            user: adminUser,
            repository: attendanceRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final approvalsBtn = find.byKey(const Key('attendance_list_approvals_button'));
      expect(approvalsBtn, findsOneWidget);

      await tester.tap(approvalsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PendingApprovalsScreen), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
      expect(find.text('Approvals & Requests'), findsOneWidget);
    });

    testWidgets('PayrollOverviewScreen approvals button navigates to PendingApprovalsScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PayrollOverviewScreen(
            user: adminUser,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final approvalsBtn = find.byKey(const Key('payroll_overview_approvals_button'));
      expect(approvalsBtn, findsOneWidget);

      await tester.tap(approvalsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PendingApprovalsScreen), findsOneWidget);
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
      expect(find.text('Approvals & Requests'), findsOneWidget);
    });
  });
}
