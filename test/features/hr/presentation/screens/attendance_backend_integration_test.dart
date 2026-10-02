import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/attendance_list_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/attendance_list_screen.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendAttendanceRepository repository;

  final adminUser = const CurrentUser(
    id: 'usr_admin_01',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.hrPayroll},
    permissions: {'hr_view', 'hr_edit'},
  );

  setUp(() {
    transport = MockApiTransport();
    config = BackendConfig.staging(
      baseUrl: 'https://api.crm.example.com',
      mode: BackendMode.backend,
    );
    apiClient = ApiClient(
      config: config,
      transport: transport,
      authTokenProvider: () => 'jwt_token_admin',
    );
    repository = BackendAttendanceRepository(apiClient: apiClient);
  });

  group('HR-10.6 Attendance - Cubit & Screen Integration', () {
    test('AttendanceListCubit loads attendance records via BackendAttendanceRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_101",
            "employee_id": "emp_1",
            "date": "2026-09-21",
            "status": "Present",
            "check_in": "2026-09-21T09:00:00Z",
            "check_out": "2026-09-21T18:00:00Z"
          },
          {
            "id": "att_102",
            "employee_id": "emp_2",
            "date": "2026-09-21",
            "status": "Half-day"
          }
        ]
        ''',
      );

      final cubit = AttendanceListCubit(repository);
      expect(cubit.state.records, isEmpty);

      await cubit.loadAttendance();

      expect(cubit.state.records.length, 2);
      expect(cubit.state.records.first.id, 'att_101');
      expect(cubit.state.filteredRecords.length, 2);

      // Status filtering
      cubit.setStatusFilter('Half-day');
      expect(cubit.state.filteredRecords.length, 1);
      expect(cubit.state.filteredRecords.first.attendanceStatus, 'Half-day');

      await cubit.close();
    });

    testWidgets('AttendanceListScreen renders backend records and handles retry on failure', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": "Internal server error"}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceListScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message and retry button
      expect(find.textContaining('Backend server error (500)'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now register success on transport and tap Retry
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_101",
            "employee_id": "emp_1",
            "date": "2026-09-21",
            "status": "Present",
            "check_in": "2026-09-21T09:00:00Z",
            "check_out": "2026-09-21T18:00:00Z"
          }
        ]
        ''',
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Present'), findsWidgets);
    });

    testWidgets('Responsive rendering: AttendanceListScreen renders without overflow on mobile and desktop', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_101",
            "employee_id": "emp_1",
            "date": "2026-09-21",
            "status": "Present",
            "check_in": "2026-09-21T09:00:00Z",
            "check_out": "2026-09-21T18:00:00Z"
          }
        ]
        ''',
      );

      // Mobile 360x640
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceListScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Attendance Management'), findsOneWidget);

      // Desktop 1200x800
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceListScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Attendance Management'), findsOneWidget);
    });
  });
}
