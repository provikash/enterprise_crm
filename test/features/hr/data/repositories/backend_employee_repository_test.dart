import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employment_status.dart';
import 'package:enterprise_crm/features/hr/domain/inputs/create_employee_input.dart';
import 'package:enterprise_crm/features/hr/domain/inputs/update_employee_input.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeRepository repository;

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
    repository = BackendEmployeeRepository(apiClient: apiClient);
  });

  group('BackendEmployeeRepository - getEmployees()', () {
    test('fetches and maps list of employees from direct JSON array', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "emp_001",
            "full_name": "Aarav Sharma",
            "department": "Engineering",
            "designation": "Lead Engineer",
            "status": "Active"
          },
          {
            "id": "emp_002",
            "full_name": "Priya Patel",
            "department": "Design",
            "status": "Probation"
          }
        ]
        ''',
      );

      final employees = await repository.getEmployees();

      expect(employees.length, 2);
      expect(employees[0].id, 'emp_001');
      expect(employees[0].fullName, 'Aarav Sharma');
      expect(employees[0].department, 'Engineering');
      expect(employees[0].employmentStatus, EmploymentStatus.active);
      expect(employees[1].id, 'emp_002');
      expect(employees[1].employmentStatus, EmploymentStatus.probation);
    });

    test('fetches and maps list of employees from paginated envelope', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "items": [
            {
              "id": "emp_003",
              "full_name": "Rohan Gupta",
              "status": "active"
            }
          ],
          "total": 1,
          "page": 1,
          "page_size": 20
        }
        ''',
      );

      final employees = await repository.getEmployees();

      expect(employees.length, 1);
      expect(employees.first.id, 'emp_003');
      expect(employees.first.fullName, 'Rohan Gupta');
    });

    test('attaches query parameters correctly', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final employees = await repository.getEmployees(
        search: 'Aarav',
        department: 'Engineering',
        status: 'Active',
        page: 1,
        pageSize: 10,
      );

      expect(employees, isEmpty);
      expect(transport.recordedRequests.length, 1);
      final recordedUri = transport.recordedRequests.first.uri;
      expect(recordedUri.queryParameters['search'], 'Aarav');
      expect(recordedUri.queryParameters['department'], 'Engineering');
      expect(recordedUri.queryParameters['status'], 'Active');
      expect(recordedUri.queryParameters['page'], '1');
      expect(recordedUri.queryParameters['page_size'], '10');
    });

    test('translates 401 Unauthorized to EmployeeException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 401,
        jsonBody: '{"error": "unauthorized"}',
      );

      expect(
        () => repository.getEmployees(),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('Unauthorized: Session has expired'),
          ),
        ),
      );
    });

    test('translates 403 Forbidden to EmployeeException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": "forbidden"}',
      );

      expect(
        () => repository.getEmployees(),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('Access denied'),
          ),
        ),
      );
    });

    test('translates network failure to EmployeeException without mock fallback', () async {
      transport.simulateConnectionFailure = true;

      expect(
        () => repository.getEmployees(),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('Connection failure'),
          ),
        ),
      );
    });

    test('translates server 500 error to EmployeeException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": "Internal server error"}',
      );

      expect(
        () => repository.getEmployees(),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('Backend server error (500)'),
          ),
        ),
      );
    });
  });

  group('BackendEmployeeRepository - getEmployeeById()', () {
    test('fetches single employee by ID successfully', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_001',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "emp_001",
          "full_name": "Aarav Sharma",
          "department": "Engineering",
          "status": "active"
        }
        ''',
      );

      final employee = await repository.getEmployeeById('emp_001');

      expect(employee, isNotNull);
      expect(employee!.id, 'emp_001');
      expect(employee.fullName, 'Aarav Sharma');
      expect(employee.department, 'Engineering');
    });

    test('fetches employee wrapped in "data" object envelope', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_002',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "data": {
            "id": "emp_002",
            "full_name": "Priya Patel",
            "status": "active"
          }
        }
        ''',
      );

      final employee = await repository.getEmployeeById('emp_002');

      expect(employee, isNotNull);
      expect(employee!.id, 'emp_002');
      expect(employee.fullName, 'Priya Patel');
    });

    test('returns null when server responds with 404 Not Found', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_999',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "not_found"}',
      );

      final employee = await repository.getEmployeeById('emp_999');

      expect(employee, isNull);
    });

    test('returns null immediately when empty ID is passed', () async {
      final employee = await repository.getEmployeeById('   ');

      expect(employee, isNull);
      expect(transport.recordedRequests, isEmpty);
    });
  });

  group('BackendEmployeeRepository - HR-10.3 Deferred Write Operations', () {
    test('createEmployee throws EmployeeException indicating deferral to HR-10.4', () async {
      const input = CreateEmployeeInput(fullName: 'New Employee');

      expect(
        () => repository.createEmployee(input),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('deferred to HR-10.4'),
          ),
        ),
      );
    });

    test('updateEmployee throws EmployeeException indicating deferral to HR-10.4', () async {
      const input = UpdateEmployeeInput(
        id: 'emp_001',
        fullName: 'Updated Name',
        employmentStatus: EmploymentStatus.active,
      );

      expect(
        () => repository.updateEmployee(input),
        throwsA(
          isA<EmployeeException>().having(
            (e) => e.message,
            'message',
            contains('deferred to HR-10.4'),
          ),
        ),
      );
    });
  });

  group('BackendEmployeeRepository - Invariants & Configuration', () {
    test('reports backend and mock modes accurately from config', () {
      expect(repository.isBackendMode, isTrue);
      expect(repository.isMockMode, isFalse);
      expect(repository.config.baseUrl, 'https://api.crm.example.com');
    });
  });
}
