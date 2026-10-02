import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/payroll_repository_factory.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendPayrollRepository repository;

  setUp(() {
    transport = MockApiTransport();
    config = BackendConfig.staging(
      baseUrl: 'https://api.crm.example.com',
      mode: BackendMode.backend,
    );
    apiClient = ApiClient(
      config: config,
      transport: transport,
      authTokenProvider: () => 'payroll_token_valid',
    );
    repository = BackendPayrollRepository(apiClient: apiClient);
  });

  group('BackendPayrollRepository - getPayrollPeriods()', () {
    test('fetches payroll periods from direct JSON array', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "period_2026_01",
            "name": "January 2026",
            "start_date": "2026-01-01",
            "end_date": "2026-01-31",
            "payment_date": "2026-02-05"
          },
          {
            "id": "period_2026_02",
            "name": "February 2026",
            "start_date": "2026-02-01",
            "end_date": "2026-02-28"
          }
        ]
        ''',
      );

      final periods = await repository.getPayrollPeriods();

      expect(periods.length, equals(2));
      expect(periods[0].id, equals('period_2026_01'));
      expect(periods[0].name, equals('January 2026'));
      expect(periods[1].id, equals('period_2026_02'));
      expect(periods[1].paymentDate, isNull);
    });

    test('fetches payroll periods from envelope with data key', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "data": [
            {
              "id": "period_2026_03",
              "name": "March 2026",
              "start_date": "2026-03-01",
              "end_date": "2026-03-31"
            }
          ]
        }
        ''',
      );

      final periods = await repository.getPayrollPeriods();

      expect(periods.length, equals(1));
      expect(periods.first.id, equals('period_2026_03'));
      expect(periods.first.name, equals('March 2026'));
    });

    test('translates 401 Unauthorized into PayrollException', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 401,
        jsonBody: '{"error": "Unauthorized"}',
      );

      expect(
        () => repository.getPayrollPeriods(),
        throwsA(
          isA<PayrollException>().having(
            (e) => e.code,
            'code',
            'UNAUTHORIZED',
          ),
        ),
      );
    });

    test('translates 403 Forbidden into PayrollException', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": "Forbidden"}',
      );

      expect(
        () => repository.getPayrollPeriods(),
        throwsA(
          isA<PayrollException>().having(
            (e) => e.code,
            'code',
            'FORBIDDEN',
          ),
        ),
      );
    });
  });

  group('BackendPayrollRepository - getPayrollPeriodById()', () {
    test('fetches single period by ID', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods/period_2026_01',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "period_2026_01",
          "name": "January 2026",
          "start_date": "2026-01-01",
          "end_date": "2026-01-31"
        }
        ''',
      );

      final period = await repository.getPayrollPeriodById('period_2026_01');

      expect(period, isNotNull);
      expect(period!.id, equals('period_2026_01'));
      expect(period.name, equals('January 2026'));
    });

    test('returns null when period is not found (404)', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/periods/period_missing',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "Not Found"}',
      );

      final period = await repository.getPayrollPeriodById('period_missing');
      expect(period, isNull);
    });
  });

  group('BackendPayrollRepository - getPayrollRecords()', () {
    test('fetches records and forwards query parameters', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "pay_101",
            "employee_id": "emp_1",
            "payroll_period_id": "period_2026_01",
            "gross_salary": 8500.0,
            "net_salary": 7200.0,
            "currency": "INR",
            "payment_status": "Paid"
          }
        ]
        ''',
      );

      final records = await repository.getPayrollRecords(
        payrollPeriodId: 'period_2026_01',
        employeeId: 'emp_1',
      );

      expect(records.length, equals(1));
      expect(records.first.id, equals('pay_101'));
      expect(records.first.grossSalary, equals(8500.0));
      expect(records.first.netSalary, equals(7200.0));
      expect(records.first.currency, equals('INR'));

      expect(transport.recordedRequests.length, equals(1));
      final req = transport.recordedRequests.first;
      expect(req.uri.queryParameters['period_id'], equals('period_2026_01'));
      expect(req.uri.queryParameters['employee_id'], equals('emp_1'));
    });

    test('getPayrollRecordsForPeriod() delegates with period_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getPayrollRecordsForPeriod('period_2026_02');

      expect(transport.recordedRequests.length, equals(1));
      expect(
        transport.recordedRequests.first.uri.queryParameters['period_id'],
        equals('period_2026_02'),
      );
    });

    test('getPayrollRecordsForEmployee() delegates with employee_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getPayrollRecordsForEmployee('emp_5');

      expect(transport.recordedRequests.length, equals(1));
      expect(
        transport.recordedRequests.first.uri.queryParameters['employee_id'],
        equals('emp_5'),
      );
    });

    test('getPayrollRecordById() fetches single record', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records/pay_101',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "pay_101",
          "employee_id": "emp_1",
          "payroll_period_id": "period_2026_01",
          "gross_salary": 9000.0,
          "net_salary": 7800.0,
          "currency": "USD"
        }
        ''',
      );

      final record = await repository.getPayrollRecordById('pay_101');

      expect(record, isNotNull);
      expect(record!.id, equals('pay_101'));
      expect(record.grossSalary, equals(9000.0));
      expect(record.currency, equals('USD'));
    });

    test('getPayrollRecordById() returns null on 404', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records/pay_missing',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "Not Found"}',
      );

      final record = await repository.getPayrollRecordById('pay_missing');
      expect(record, isNull);
    });
  });

  group('PayrollRepositoryFactory - Controlled Cutover', () {
    test('returns BackendPayrollRepository when config is BackendMode.backend', () {
      final backendConfig = BackendConfig.staging(
        baseUrl: 'https://api.crm.example.com',
        mode: BackendMode.backend,
      );
      final repo = PayrollRepositoryFactory.create(
        config: backendConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<BackendPayrollRepository>());
    });

    test('returns MockPayrollRepository when config is BackendMode.mock', () {
      final mockConfig = BackendConfig.staging(
        baseUrl: 'https://api.crm.example.com',
        mode: BackendMode.mock,
      );
      final repo = PayrollRepositoryFactory.create(
        config: mockConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<MockPayrollRepository>());
    });
  });
}
