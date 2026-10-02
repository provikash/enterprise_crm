import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_details_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_directory_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_details_screen.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_directory_screen.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeRepository repository;

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
    repository = BackendEmployeeRepository(apiClient: apiClient);
  });

  group('HR-10.4 Employee Management - Cubit & Screen Integration', () {
    test('EmployeeDirectoryCubit loads employees via BackendEmployeeRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "emp_101",
            "full_name": "Aarav Sharma",
            "department": "Engineering",
            "status": "Active"
          },
          {
            "id": "emp_102",
            "full_name": "Priya Patel",
            "department": "Design",
            "status": "Active"
          }
        ]
        ''',
      );

      final cubit = EmployeeDirectoryCubit(repository: repository);
      expect(cubit.state.employees, isEmpty);

      await cubit.loadEmployees();

      expect(cubit.state.employees.length, 2);
      expect(cubit.state.employees.first.fullName, 'Aarav Sharma');
      expect(cubit.state.filteredEmployees.length, 2);

      // Apply search query
      cubit.setSearchQuery('Priya');
      expect(cubit.state.filteredEmployees.length, 1);
      expect(cubit.state.filteredEmployees.first.fullName, 'Priya Patel');

      await cubit.close();
    });

    test('EmployeeDetailsCubit loads single employee via BackendEmployeeRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "emp_101",
          "full_name": "Aarav Sharma",
          "department": "Engineering",
          "designation": "Staff Engineer",
          "status": "Active"
        }
        ''',
      );

      final cubit = EmployeeDetailsCubit(repository: repository);
      await cubit.loadEmployee('emp_101');

      expect(cubit.state.employee, isNotNull);
      expect(cubit.state.employee!.fullName, 'Aarav Sharma');
      expect(cubit.state.employee!.department, 'Engineering');

      await cubit.close();
    });

    testWidgets('EmployeeDirectoryScreen renders backend employees and handles retry on failure', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": "Internal server error"}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error state is rendered
      expect(find.textContaining('Backend server error (500)'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now register success on transport and tap Retry
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "emp_101",
            "full_name": "Aarav Sharma",
            "department": "Engineering",
            "status": "Active"
          }
        ]
        ''',
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
    });

    testWidgets('EmployeeDetailsScreen renders backend employee information', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "emp_101",
          "full_name": "Aarav Sharma",
          "department": "Engineering",
          "designation": "Principal Engineer",
          "email": "aarav.sharma@example.com",
          "phone": "+91 98765 43210",
          "status": "Active"
        }
        ''',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDetailsScreen(
            user: adminUser,
            employeeId: 'emp_101',
            repository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('Engineering'), findsWidgets);
      expect(find.text('Principal Engineer'), findsWidgets);
      expect(find.text('aarav.sharma@example.com'), findsWidgets);
    });

    testWidgets('Responsive rendering: EmployeeDirectoryScreen renders on mobile and desktop without overflow', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "emp_101",
            "full_name": "Aarav Sharma",
            "department": "Engineering",
            "status": "Active"
          }
        ]
        ''',
      );

      // 1. Mobile viewport 360x640
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aarav Sharma'), findsOneWidget);

      // 2. Desktop viewport 1200x800
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDirectoryScreen(
            user: adminUser,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aarav Sharma'), findsOneWidget);
    });
  });
}
