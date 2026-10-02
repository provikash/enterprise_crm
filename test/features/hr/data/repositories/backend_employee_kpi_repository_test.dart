import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/employee_kpi_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_kpi_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeKpiRepository repository;

  setUp(() {
    transport = MockApiTransport();
    config = BackendConfig.staging(
      baseUrl: 'https://api.crm.example.com',
      mode: BackendMode.backend,
    );
    apiClient = ApiClient(
      config: config,
      transport: transport,
      authTokenProvider: () => 'valid_bearer_token',
    );
    repository = BackendEmployeeKpiRepository(apiClient: apiClient);
  });

  group('BackendEmployeeKpiRepository - getKpis()', () {
    test('fetches KPI list from direct JSON array', () async {
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
            "score": 95.0,
            "remarks": "Exceeded target"
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

      final records = await repository.getKpis();

      expect(records.length, 2);
      expect(records[0].id, equals('kpi_101'));
      expect(records[0].employeeId, equals('emp_1'));
      expect(records[0].metricName, equals('Employee Retention Rate'));
      expect(records[0].targetValue, equals(90.0));
      expect(records[0].actualValue, equals(92.5));
      expect(records[0].score, equals(95.0));
      expect(records[1].id, equals('kpi_102'));
      expect(records[1].score, isNull);
    });

    test('fetches KPI list from envelope with data key', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "data": [
            {
              "id": "kpi_201",
              "employee_id": "emp_2",
              "metric_name": "Inventory Accuracy",
              "period_start": "2026-07-01",
              "period_end": "2026-09-30",
              "target_value": 98.0,
              "actual_value": 96.5,
              "score": 85.0
            }
          ]
        }
        ''',
      );

      final records = await repository.getKpis();

      expect(records.length, 1);
      expect(records.first.id, equals('kpi_201'));
      expect(records.first.metricName, equals('Inventory Accuracy'));
    });

    test('forwards query parameters: employee_id, start_date, end_date', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getKpis(
        employeeId: 'emp_3',
        startDate: DateTime.utc(2026, 7, 1),
        endDate: DateTime.utc(2026, 9, 30),
      );

      expect(transport.recordedRequests.length, 1);
      final req = transport.recordedRequests.first;
      expect(req.uri.queryParameters['employee_id'], equals('emp_3'));
      expect(req.uri.queryParameters['start_date'], equals('2026-07-01'));
      expect(req.uri.queryParameters['end_date'], equals('2026-09-30'));
    });

    test('getKpisForEmployee() delegates to getKpis() with employee_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getKpisForEmployee('emp_5');

      expect(transport.recordedRequests.length, 1);
      expect(transport.recordedRequests.first.uri.queryParameters['employee_id'], equals('emp_5'));
    });

    test('translates 401 Unauthorized into EmployeeKpiException', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 401,
        jsonBody: '{"error": "Unauthorized"}',
      );

      expect(
        () => repository.getKpis(),
        throwsA(
          isA<EmployeeKpiException>().having(
            (e) => e.code,
            'code',
            'UNAUTHORIZED',
          ),
        ),
      );
    });

    test('translates 403 Forbidden into EmployeeKpiException', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": "Forbidden"}',
      );

      expect(
        () => repository.getKpis(),
        throwsA(
          isA<EmployeeKpiException>().having(
            (e) => e.code,
            'code',
            'FORBIDDEN',
          ),
        ),
      );
    });
  });

  group('BackendEmployeeKpiRepository - getKpiById()', () {
    test('fetches single KPI by ID', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis/kpi_101',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "kpi_101",
          "employee_id": "emp_1",
          "metric_name": "Employee Retention Rate",
          "period_start": "2026-07-01",
          "period_end": "2026-09-30",
          "target_value": 90.0,
          "actual_value": 92.5,
          "score": 95.0
        }
        ''',
      );

      final record = await repository.getKpiById('kpi_101');

      expect(record, isNotNull);
      expect(record!.id, equals('kpi_101'));
      expect(record.metricName, equals('Employee Retention Rate'));
      expect(record.score, equals(95.0));
    });

    test('returns null when KPI record is not found (404)', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis/kpi_999',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "Not Found"}',
      );

      final record = await repository.getKpiById('kpi_999');
      expect(record, isNull);
    });

    test('throws EmployeeKpiException if ID is empty', () async {
      expect(
        () => repository.getKpiById('   '),
        throwsA(isA<EmployeeKpiException>()),
      );
    });
  });

  group('BackendEmployeeKpiRepository - createKpi()', () {
    test('sends POST and parses created KPI record', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.post,
        statusCode: 201,
        jsonBody: '''
        {
          "id": "kpi_new_1",
          "employee_id": "emp_10",
          "metric_name": "Project Delivery",
          "period_start": "2026-10-01",
          "period_end": "2026-12-31",
          "target_value": 10.0,
          "actual_value": 12.0,
          "score": 100.0,
          "remarks": "On time delivery"
        }
        ''',
      );

      final created = await repository.createKpi(
        employeeId: 'emp_10',
        metricName: 'Project Delivery',
        periodStart: DateTime.utc(2026, 10, 1),
        periodEnd: DateTime.utc(2026, 12, 31),
        targetValue: 10.0,
        actualValue: 12.0,
        score: 100.0,
        remarks: 'On time delivery',
      );

      expect(created.id, equals('kpi_new_1'));
      expect(created.metricName, equals('Project Delivery'));
      expect(created.score, equals(100.0));
      expect(transport.recordedRequests.length, 1);
      final req = transport.recordedRequests.first;
      expect(req.method, equals(HttpMethod.post));
      final parsedBody = jsonDecode(req.body!) as Map<String, dynamic>;
      expect(parsedBody['employee_id'], equals('emp_10'));
      expect(parsedBody['period_start'], equals('2026-10-01'));
    });

    test('throws EmployeeKpiException if end date precedes start date', () async {
      expect(
        () => repository.createKpi(
          employeeId: 'emp_10',
          metricName: 'Metric',
          periodStart: DateTime.utc(2026, 10, 31),
          periodEnd: DateTime.utc(2026, 10, 1),
          targetValue: 10,
          actualValue: 5,
        ),
        throwsA(isA<EmployeeKpiException>()),
      );
    });

    test('handles 409 Conflict gracefully', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.post,
        statusCode: 409,
        jsonBody: '{"error": "KPI for this metric and period already exists"}',
      );

      expect(
        () => repository.createKpi(
          employeeId: 'emp_10',
          metricName: 'Duplicate Metric',
          periodStart: DateTime.utc(2026, 10, 1),
          periodEnd: DateTime.utc(2026, 12, 31),
          targetValue: 10,
          actualValue: 5,
        ),
        throwsA(
          isA<EmployeeKpiException>().having(
            (e) => e.message,
            'message',
            contains('conflicting KPI record'),
          ),
        ),
      );
    });
  });

  group('BackendEmployeeKpiRepository - updateKpi()', () {
    test('sends PUT and parses updated KPI record', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis/kpi_101',
        method: HttpMethod.put,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "kpi_101",
          "employee_id": "emp_1",
          "metric_name": "Updated Retention Rate",
          "period_start": "2026-07-01",
          "period_end": "2026-09-30",
          "target_value": 95.0,
          "actual_value": 94.0,
          "score": 90.0,
          "remarks": "Updated score"
        }
        ''',
      );

      final updated = await repository.updateKpi(
        id: 'kpi_101',
        metricName: 'Updated Retention Rate',
        periodStart: DateTime.utc(2026, 7, 1),
        periodEnd: DateTime.utc(2026, 9, 30),
        targetValue: 95.0,
        actualValue: 94.0,
        score: 90.0,
        remarks: 'Updated score',
      );

      expect(updated.id, equals('kpi_101'));
      expect(updated.metricName, equals('Updated Retention Rate'));
      expect(updated.targetValue, equals(95.0));
      expect(updated.score, equals(90.0));
      expect(transport.recordedRequests.length, 1);
      final req = transport.recordedRequests.first;
      expect(req.method, equals(HttpMethod.put));
      expect(req.uri.path, equals('/api/v1/hr/kpis/kpi_101'));
    });

    test('handles 404 Not Found on update', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis/kpi_missing',
        method: HttpMethod.put,
        statusCode: 404,
        jsonBody: '{"error": "Not Found"}',
      );

      expect(
        () => repository.updateKpi(
          id: 'kpi_missing',
          metricName: 'Metric',
          periodStart: DateTime.utc(2026, 7, 1),
          periodEnd: DateTime.utc(2026, 9, 30),
          targetValue: 10,
          actualValue: 5,
        ),
        throwsA(
          isA<EmployeeKpiException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });
  });

  group('EmployeeKpiRepositoryFactory - Controlled Cutover', () {
    test('returns BackendEmployeeKpiRepository when config is BackendMode.backend', () {
      final backendConfig = BackendConfig.staging(
        baseUrl: 'https://api.crm.example.com',
        mode: BackendMode.backend,
      );
      final repo = EmployeeKpiRepositoryFactory.create(
        config: backendConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<BackendEmployeeKpiRepository>());
    });

    test('returns MockEmployeeKpiRepository when config is BackendMode.mock', () {
      final mockConfig = BackendConfig.staging(
        baseUrl: 'https://api.crm.example.com',
        mode: BackendMode.mock,
      );
      final repo = EmployeeKpiRepositoryFactory.create(
        config: mockConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<MockEmployeeKpiRepository>());
    });
  });
}
