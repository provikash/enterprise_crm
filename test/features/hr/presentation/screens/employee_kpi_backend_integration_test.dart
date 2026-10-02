import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_kpi_list_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_kpi_list_state.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_kpi_list_screen.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeKpiRepository repository;

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
    repository = BackendEmployeeKpiRepository(apiClient: apiClient);
  });

  group('HR-10.7 KPI / Performance - Cubit & Screen Integration', () {
    test('EmployeeKpiListCubit loads KPI records via BackendEmployeeKpiRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "kpi_101",
            "employee_id": "emp_1",
            "metric_name": "Employee Retention Rate",
            "period_start": "2026-07-01",
            "period_end": "2026-09-30",
            "target_value": 90.0,
            "actual_value": 92.5,
            "score": 95.0
          },
          {
            "id": "kpi_102",
            "employee_id": "emp_1",
            "metric_name": "Time to Hire",
            "period_start": "2026-07-01",
            "period_end": "2026-09-30",
            "target_value": 25.0,
            "actual_value": 22.0
          }
        ]
        ''',
      );

      final cubit = EmployeeKpiListCubit(repository: repository);
      expect(cubit.state.kpis, isEmpty);

      await cubit.loadKpis();

      expect(cubit.state.status, equals(EmployeeKpiListStatus.loaded));
      expect(cubit.state.kpis.length, equals(2));
      expect(cubit.state.kpis[0].metricName, equals('Employee Retention Rate'));
      expect(cubit.state.kpis[0].score, equals(95.0));
      expect(cubit.state.kpis[1].metricName, equals('Time to Hire'));
    });

    testWidgets('EmployeeKpiListScreen renders backend KPI records and handles retry on failure', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": "Internal Server Error"}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeKpiListScreen(
            user: adminUser,
            kpiRepository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Error message should be rendered
      expect(find.byKey(const Key('kpi_error_state')), findsOneWidget);

      // Now register success for retry
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "kpi_101",
            "employee_id": "emp_1",
            "metric_name": "Backend Retention Rate",
            "period_start": "2026-07-01",
            "period_end": "2026-09-30",
            "target_value": 90.0,
            "actual_value": 92.5,
            "score": 95.0
          }
        ]
        ''',
      );

      // Tap Retry button
      final retryButton = find.byKey(const Key('kpi_retry_button'));
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Should now display the loaded KPI record
      expect(find.text('Backend Retention Rate'), findsOneWidget);
    });
  });
}
