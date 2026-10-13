import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_documents_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_kpi_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adminUser = CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.hrPayroll},
    permissions: {},
  );

  const sampleEmployee = Employee(
    id: 'emp_001',
    fullName: 'Test Employee',
    email: 'test@example.com',
  );

  final viewports = <String, Size>{
    'Size(510, 230)': const Size(510, 230),
    'Size(400, 445)': const Size(400, 445),
    'Size(400, 800)': const Size(400, 800),
    'Size(320, 568)': const Size(320, 568),
    'Size(600, 350)': const Size(600, 350),
    'Size(700, 400)': const Size(700, 400),
    'Size(800, 400)': const Size(800, 400),
    'Size(1200, 800)': const Size(1200, 800),
  };

  group('EmployeeDirectoryScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('EmployeeDirectoryScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockEmployeeRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDirectoryScreen(
              user: adminUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('AttendanceListScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('AttendanceListScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockAttendanceRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: AttendanceListScreen(
              user: adminUser,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('EmployeeKpiListScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('EmployeeKpiListScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockEmployeeKpiRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeKpiListScreen(
              user: adminUser,
              kpiRepository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });

  group('EmployeeDocumentsScreen Responsive Overflow Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('EmployeeDocumentsScreen renders without overflow at ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = MockEmployeeDocumentRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: EmployeeDocumentsScreen(
              user: adminUser,
              employee: sampleEmployee,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at size ${entry.key}');
      });
    }
  });
}
