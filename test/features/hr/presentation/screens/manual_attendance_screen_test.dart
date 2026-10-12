import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/auth/presentation/screens/access_restricted_screen.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/manual_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const admin = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin',
    accountType: AccountType.admin,
  );
  const viewer = CurrentUser(
    id: 'usr_hr_viewer',
    displayName: 'HR Viewer',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  testWidgets('blocks HR viewer without attendance.manage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualAttendanceScreen(
          user: viewer,
          repository: MockAttendanceRepository(),
          employeeRepository: MockEmployeeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AccessRestrictedScreen), findsOneWidget);
  });

  testWidgets('admin can save reason-required manual attendance', (
    tester,
  ) async {
    final attendance = MockAttendanceRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1100)),
          child: ManualAttendanceScreen(
            user: admin,
            repository: attendance,
            employeeRepository: MockEmployeeRepository(),
            initialDate: DateTime(2026, 10, 12),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('manual_attendance_employee')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Alice Johnson').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manual_attendance_status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Absent').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual_attendance_reason')),
      'Biometric terminal unavailable',
    );
    final submit = find.byKey(const Key('manual_attendance_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final records = await attendance.getAttendanceForDate(
      DateTime(2026, 10, 12),
    );
    expect(records.any((record) => record.employeeId == 'emp_1'), isTrue);
  });
}
