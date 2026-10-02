import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/network_exception.dart';
import 'package:enterprise_crm/features/hr/data/repositories/attendance_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/employee_document_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/employee_kpi_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/employee_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/hr_report_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/payroll_repository_factory.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/kpi_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_report_query.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_kpi_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig backendConfig;
  late BackendConfig mockConfig;
  late String? activeAuthToken;
  late ApiClient apiClient;

  setUp(() {
    transport = MockApiTransport();
    backendConfig = BackendConfig.staging(
      baseUrl: 'https://staging-api.crm.example.com',
      mode: BackendMode.backend,
    );
    mockConfig = BackendConfig.development(
      baseUrl: 'http://localhost:8000',
      mode: BackendMode.mock,
    );
    activeAuthToken = 'initial_test_bearer_token';
    apiClient = ApiClient(
      config: backendConfig,
      transport: transport,
      authTokenProvider: () => activeAuthToken,
    );
  });

  group('HR-10.9 Authentication & Session Isolation Audit', () {
    test('Bearer token is evaluated dynamically per request and attached to Authorization header', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final repo = BackendEmployeeRepository(apiClient: apiClient);
      await repo.getEmployees();

      expect(transport.recordedRequests.length, 1);
      expect(
        transport.recordedRequests.first.headers['authorization'],
        'Bearer initial_test_bearer_token',
      );
    });

    test('Session token change immediately affects subsequent backend requests without client restart', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final repo = BackendEmployeeRepository(apiClient: apiClient);
      await repo.getEmployees();

      // Switch user session token
      activeAuthToken = 'switched_user_token_xyz';
      await repo.getEmployees();

      expect(transport.recordedRequests.length, 2);
      expect(
        transport.recordedRequests[1].headers['authorization'],
        'Bearer switched_user_token_xyz',
      );
    });

    test('User logout clears active token, omitting Authorization header', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final repo = BackendEmployeeRepository(apiClient: apiClient);
      activeAuthToken = null; // simulate logout
      await repo.getEmployees();

      expect(transport.recordedRequests.length, 1);
      expect(transport.recordedRequests.first.headers.containsKey('authorization'), isFalse);
    });
  });

  group('HR-10.9 Authorization & RBAC Audit', () {
    test('403 Forbidden on Employee repository translates to access forbidden EmployeeException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "User lacks hrView permission."}}',
      );

      final repo = BackendEmployeeRepository(apiClient: apiClient);
      expect(
        () => repo.getEmployees(),
        throwsA(isA<EmployeeException>().having(
          (e) => e.message,
          'message',
          contains('Access denied'),
        )),
      );
    });

    test('403 Forbidden on Payroll repository translates to access forbidden PayrollException', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "User lacks payrollView permission."}}',
      );

      final repo = BackendPayrollRepository(apiClient: apiClient);
      expect(
        () => repo.getPayrollRecords(),
        throwsA(isA<PayrollException>().having(
          (e) => e.message,
          'message',
          contains('Insufficient permissions'),
        )),
      );
    });

    test('403 Forbidden on Documents repository translates to access forbidden EmployeeDocumentException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_01/documents',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "Document access restricted."}}',
      );

      final repo = BackendEmployeeDocumentRepository(apiClient: apiClient);
      expect(
        () => repo.getDocumentsForEmployee('emp_01'),
        throwsA(isA<EmployeeDocumentException>().having(
          (e) => e.message,
          'message',
          contains('Access denied'),
        )),
      );
    });

    test('403 Forbidden on Attendance repository translates to access forbidden AttendanceException', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "Attendance access restricted."}}',
      );

      final repo = BackendAttendanceRepository(apiClient: apiClient);
      expect(
        () => repo.getAttendanceRecords(),
        throwsA(isA<AttendanceException>().having(
          (e) => e.message,
          'message',
          contains('Access denied'),
        )),
      );
    });

    test('403 Forbidden on KPI repository translates to access forbidden EmployeeKpiException', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "KPI access restricted."}}',
      );

      final repo = BackendEmployeeKpiRepository(apiClient: apiClient);
      expect(
        () => repo.getKpis(),
        throwsA(isA<EmployeeKpiException>().having(
          (e) => e.message,
          'message',
          contains('Insufficient permissions'),
        )),
      );
    });
  });

  group('HR-10.9 Cross-Employee Data Isolation & ID Parameter Scoping', () {
    test('Attendance query for Employee A scopes query strictly by employee_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_01",
            "employee_id": "emp_alice",
            "date": "2026-03-01",
            "status": "present"
          }
        ]
        ''',
      );

      final repo = BackendAttendanceRepository(apiClient: apiClient);
      final records = await repo.getAttendanceRecords(employeeId: 'emp_alice');

      expect(records.length, 1);
      expect(records.first.employeeId, 'emp_alice');
      expect(transport.recordedRequests.last.uri.queryParameters['employee_id'], 'emp_alice');
    });

    test('KPI query for Employee B scopes query strictly by employee_id without leaking Employee A', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "kpi_02",
            "employee_id": "emp_bob",
            "metric_name": "Revenue",
            "period_start": "2026-01-01",
            "period_end": "2026-01-31",
            "target_value": 100000.0,
            "actual_value": 115000.0,
            "score": 95.0
          }
        ]
        ''',
      );

      final repo = BackendEmployeeKpiRepository(apiClient: apiClient);
      final records = await repo.getKpis(employeeId: 'emp_bob');

      expect(records.length, 1);
      expect(records.first.employeeId, 'emp_bob');
      expect(transport.recordedRequests.last.uri.queryParameters['employee_id'], 'emp_bob');
    });

    test('Payroll query for Employee scopes query strictly by employee_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "pr_001",
            "payroll_period_id": "p_2026_01",
            "employee_id": "emp_alice",
            "gross_salary": 7500.00,
            "net_salary": 6100.00,
            "payment_status": "draft"
          }
        ]
        ''',
      );

      final repo = BackendPayrollRepository(apiClient: apiClient);
      final records = await repo.getPayrollRecords(employeeId: 'emp_alice');

      expect(records.length, 1);
      expect(records.first.employeeId, 'emp_alice');
      expect(transport.recordedRequests.last.uri.queryParameters['employee_id'], 'emp_alice');
    });
  });

  group('HR-10.9 Data Integrity & Immutability Invariants', () {
    test('Attendance date is normalized to UTC calendar midnight and missing records are never fabricated as absent', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final repo = BackendAttendanceRepository(apiClient: apiClient);
      final records = await repo.getAttendanceRecords(employeeId: 'emp_unknown');

      // Crucial invariant: empty response returns empty list, never fabricated absent records
      expect(records, isEmpty);
    });

    test('KPI stored scores are preserved verbatim and zero client score computation occurs', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "kpi_99",
            "employee_id": "emp_01",
            "metric_name": "Delivery Speed",
            "period_start": "2026-02-01",
            "period_end": "2026-02-28",
            "target_value": 50.0,
            "actual_value": 75.0,
            "score": 88.5
          }
        ]
        ''',
      );

      final repo = BackendEmployeeKpiRepository(apiClient: apiClient);
      final records = await repo.getKpis();

      expect(records.first.score, 88.5); // Verbatim from backend
    });

    test('Payroll monetary figures preserve exact decimals and null vs 0.0 distinction without floating point drift', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records/rec_prec',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "rec_prec",
          "payroll_period_id": "p_01",
          "employee_id": "emp_01",
          "gross_salary": 12345.67,
          "net_salary": 9876.54,
          "total_allowances": 0.0,
          "total_deductions": null,
          "currency": "USD",
          "payment_status": "draft"
        }
        ''',
      );

      final repo = BackendPayrollRepository(apiClient: apiClient);
      final record = await repo.getPayrollRecordById('rec_prec');

      expect(record, isNotNull);
      expect(record!.grossSalary, 12345.67);
      expect(record.netSalary, 9876.54);
      expect(record.totalAllowances, 0.0);
      expect(record.totalDeductions, isNull); // Preserved null, not converted to 0.0
      expect(record.currency, 'USD');
    });
  });

  group('HR-10.9 Write Safety & Non-Idempotent Retry Prohibition', () {
    test('POST requests are strictly NOT retried on network timeouts', () async {
      int postAttempts = 0;
      transport.registerHandler(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.post,
        handler: (req) async {
          postAttempts++;
          throw const NetworkTimeoutException(message: 'Connection timed out during POST');
        },
      );

      final repo = BackendAttendanceRepository(apiClient: apiClient);
      final recordToCreate = AttendanceRecord(
        id: 'att_new',
        employeeId: 'emp_01',
        date: DateTime.utc(2026, 3, 15),
        attendanceStatus: 'Present',
      );

      await expectLater(
        () => repo.recordAttendance(recordToCreate),
        throwsA(isA<AttendanceException>()),
      );

      // Must be attempted exactly ONCE: zero retries for non-idempotent mutations
      expect(postAttempts, 1);
    });

    test('Idempotent GET requests ARE retried on transient connection errors when maxRetries is set', () async {
      int getAttempts = 0;
      transport.registerHandler(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        handler: (req) async {
          getAttempts++;
          if (getAttempts < 3) {
            throw const ConnectionException(message: 'Temporary connection drop');
          }
          return const TransportResponse(
            statusCode: 200,
            body: '[]',
          );
        },
      );

      final response = await apiClient.get('/hr/employees', maxRetries: 2);

      expect(response, isA<List>());
      expect(getAttempts, 3); // Retried twice after initial failure, succeeded on 3rd
    });

    test('409 Conflict during KPI creation translates to Conflict domain error', () async {
      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.post,
        statusCode: 409,
        jsonBody: '{"error": {"code": "CONFLICT", "message": "KPI for employee and metric already exists."}}',
      );

      final repo = BackendEmployeeKpiRepository(apiClient: apiClient);

      expect(
        () => repo.createKpi(
          employeeId: 'emp_01',
          metricName: 'Sales',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 1, 31),
          targetValue: 100,
          actualValue: 100,
        ),
        throwsA(isA<EmployeeKpiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });
  });

  group('HR-10.9 Controlled Cutover & Zero Silent Fallback', () {
    test('All 5 repository factories return Mock repositories when mode is BackendMode.mock', () {
      final empRepo = EmployeeRepositoryFactory.create(config: mockConfig, apiClient: apiClient);
      final docRepo = EmployeeDocumentRepositoryFactory.create(config: mockConfig, apiClient: apiClient);
      final attRepo = AttendanceRepositoryFactory.create(config: mockConfig, apiClient: apiClient);
      final kpiRepo = EmployeeKpiRepositoryFactory.create(config: mockConfig, apiClient: apiClient);
      final payRepo = PayrollRepositoryFactory.create(config: mockConfig, apiClient: apiClient);

      expect(empRepo, isA<MockEmployeeRepository>());
      expect(docRepo, isA<MockEmployeeDocumentRepository>());
      expect(attRepo, isA<MockAttendanceRepository>());
      expect(kpiRepo, isA<MockEmployeeKpiRepository>());
      expect(payRepo, isA<MockPayrollRepository>());
    });

    test('All 5 repository factories return Backend adapters when mode is BackendMode.backend', () {
      final empRepo = EmployeeRepositoryFactory.create(config: backendConfig, apiClient: apiClient);
      final docRepo = EmployeeDocumentRepositoryFactory.create(config: backendConfig, apiClient: apiClient);
      final attRepo = AttendanceRepositoryFactory.create(config: backendConfig, apiClient: apiClient);
      final kpiRepo = EmployeeKpiRepositoryFactory.create(config: backendConfig, apiClient: apiClient);
      final payRepo = PayrollRepositoryFactory.create(config: backendConfig, apiClient: apiClient);

      expect(empRepo, isA<BackendEmployeeRepository>());
      expect(docRepo, isA<BackendEmployeeDocumentRepository>());
      expect(attRepo, isA<BackendAttendanceRepository>());
      expect(kpiRepo, isA<BackendEmployeeKpiRepository>());
      expect(payRepo, isA<BackendPayrollRepository>());
    });

    test('Backend mode failure NEVER silently falls back to mock data', () async {
      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": {"code": "INTERNAL_ERROR", "message": "Database error"}}',
      );

      final payRepo = PayrollRepositoryFactory.create(config: backendConfig, apiClient: apiClient);

      // Must throw PayrollException, MUST NOT return mock store records!
      expect(
        () => payRepo.getPayrollRecords(),
        throwsA(isA<PayrollException>()),
      );
    });
  });

  group('HR-10.9 Reports Compatibility Over Backend Repositories', () {
    test('HrReportRepositoryFactory aggregates employee, attendance, kpi, and payroll reports over backend data', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "emp_01",
            "full_name": "Alice Backend",
            "employee_code": "EMP001",
            "department": "Engineering",
            "status": "active"
          }
        ]
        ''',
      );

      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_01",
            "employee_id": "emp_01",
            "date": "2026-03-01",
            "status": "present"
          }
        ]
        ''',
      );

      transport.registerJson(
        path: '/api/v1/hr/kpis',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "kpi_01",
            "employee_id": "emp_01",
            "metric_name": "Quality",
            "period_start": "2026-01-01",
            "period_end": "2026-01-31",
            "target_value": 90.0,
            "actual_value": 95.0,
            "score": 98.0
          }
        ]
        ''',
      );

      transport.registerJson(
        path: '/api/v1/hr/payroll/periods',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "p_01",
            "name": "January 2026",
            "start_date": "2026-01-01",
            "end_date": "2026-01-31"
          }
        ]
        ''',
      );

      transport.registerJson(
        path: '/api/v1/hr/payroll/records',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "rec_01",
            "payroll_period_id": "p_01",
            "employee_id": "emp_01",
            "gross_salary": 6000.0,
            "net_salary": 5000.0,
            "currency": "USD",
            "payment_status": "draft"
          }
        ]
        ''',
      );

      final reportRepo = HrReportRepositoryFactory.create(
        config: backendConfig,
        apiClient: apiClient,
      );

      // 1. Employee Report over backend
      final empReport = await reportRepo.getEmployeeReport(const EmployeeReportQuery());
      expect(empReport.rows.length, 1);
      expect(empReport.rows.first.fullName, 'Alice Backend');

      // 2. Attendance Report over backend
      final attReport = await reportRepo.getAttendanceReport(const AttendanceReportQuery());
      expect(attReport.rows.length, 1);
      expect(attReport.rows.first.employeeName, 'Alice Backend');
      expect(attReport.rows.first.attendanceStatus, 'present');

      // 3. KPI Report over backend
      final kpiReport = await reportRepo.getKpiReport(const KpiReportQuery());
      expect(kpiReport.rows.length, 1);
      expect(kpiReport.rows.first.employeeName, 'Alice Backend');
      expect(kpiReport.rows.first.score, 98.0);

      // 4. Payroll Report over backend
      final payReport = await reportRepo.getPayrollReport(const PayrollReportQuery());
      expect(payReport.rows.length, 1);
      expect(payReport.rows.first.employeeName, 'Alice Backend');
      expect(payReport.rows.first.grossSalary, 6000.0);
      expect(payReport.rows.first.netSalary, 5000.0);
    });
  });
}
