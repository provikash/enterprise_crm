import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/auth/domain/policies/crm_permissions.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_hr_approval_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/hr_approval_request_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/pending_approvals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockEmployeeRepository employeeRepository;
  late MockHrApprovalRepository approvalRepository;

  const hrAdminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {},
    permissions: {},
  );

  const hrStandardUser = CurrentUser(
    id: 'usr_hr',
    displayName: 'HR Specialist',
    accountType: AccountType.user,
    modules: {CrmModule.hrPayroll},
    permissions: {CrmPermissions.hrView},
  );

  setUp(() {
    employeeRepository = MockEmployeeRepository();
    approvalRepository = MockHrApprovalRepository();
  });

  Widget buildRootWidget({
    required CurrentUser user,
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(1200, 800),
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: EmployeeDirectoryScreen(
          user: user,
          repository: employeeRepository,
          approvalRepository: approvalRepository,
        ),
      ),
    );
  }

  group('Approval Navigation and Responsive Integration', () {
    testWidgets('navigates from EmployeeDirectory to PendingApprovals and then to HrApprovalRequest', (tester) async {
      await tester.pumpWidget(buildRootWidget(user: hrAdminUser));
      await tester.pumpAndSettle();

      // Find and tap approvals action in AppBar
      final approvalsButton = find.byKey(const Key('employee_directory_approvals_button'));
      expect(approvalsButton, findsOneWidget);
      await tester.tap(approvalsButton);
      await tester.pumpAndSettle();

      // Verify we are on PendingApprovalsScreen
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
      expect(find.text('Approvals & Requests'), findsOneWidget);

      // Tap 'New Request' button
      final newRequestButton = find.byKey(const Key('pending_approvals_new_request_button'));
      expect(newRequestButton, findsOneWidget);
      await tester.tap(newRequestButton);
      await tester.pumpAndSettle();

      // Verify we are on HrApprovalRequestScreen
      expect(find.byKey(const Key('hr_approval_request_scaffold')), findsOneWidget);
      expect(find.text('New Approval Request'), findsOneWidget);
    });

    for (final size in [
      const Size(320, 568),  // Small Mobile
      const Size(360, 640),  // Standard Mobile
      const Size(768, 1024), // Tablet
      const Size(1200, 800), // Desktop Web
    ]) {
      testWidgets('PendingApprovals renders without overflow on ${size.width}x${size.height}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: PendingApprovalsScreen(
                user: hrAdminUser,
                repository: approvalRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
      });

      testWidgets('HrApprovalRequest renders without overflow on ${size.width}x${size.height}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: HrApprovalRequestScreen(
                user: hrAdminUser,
                repository: approvalRepository,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('hr_approval_request_scaffold')), findsOneWidget);
      });
    }

    testWidgets('Dark theme renders correctly for pending approvals screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: PendingApprovalsScreen(
            user: hrStandardUser,
            repository: approvalRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('pending_approvals_scaffold')), findsOneWidget);
    });
  });
}
