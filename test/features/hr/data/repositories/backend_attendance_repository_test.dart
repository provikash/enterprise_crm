import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/attendance_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_attendance_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/attendance_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/attendance_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendAttendanceRepository repository;

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
    repository = BackendAttendanceRepository(apiClient: apiClient);
  });

  group('BackendAttendanceRepository - getAttendanceRecords()', () {
    test('fetches attendance records list from direct JSON array', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "att_001",
            "employee_id": "emp_101",
            "date": "2026-09-21",
            "status": "Present",
            "check_in": "2026-09-21T09:00:00Z",
            "check_out": "2026-09-21T18:00:00Z"
          },
          {
            "id": "att_002",
            "employee_id": "emp_102",
            "date": "2026-09-21",
            "status": "Half-day"
          }
        ]
        ''',
      );

      final records = await repository.getAttendanceRecords();

      expect(records.length, 2);
      expect(records[0].id, 'att_001');
      expect(records[0].employeeId, 'emp_101');
      expect(records[0].attendanceStatus, 'Present');
      expect(records[1].id, 'att_002');
      expect(records[1].attendanceStatus, 'Half-day');
    });

    test('fetches attendance records from paginated envelope', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "items": [
            {
              "id": "att_003",
              "employee_id": "emp_103",
              "date": "2026-09-22",
              "status": "On Leave"
            }
          ],
          "total": 1
        }
        ''',
      );

      final records = await repository.getAttendanceRecords();

      expect(records.length, 1);
      expect(records.first.id, 'att_003');
      expect(records.first.attendanceStatus, 'On Leave');
    });

    test('attaches query parameters correctly', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      final records = await repository.getAttendanceRecords(
        employeeId: 'emp_104',
        startDate: DateTime.utc(2026, 9, 1),
        endDate: DateTime.utc(2026, 9, 30),
        status: 'Present',
      );

      expect(records, isEmpty);
      expect(transport.recordedRequests.length, 1);
      final recordedUri = transport.recordedRequests.first.uri;
      expect(recordedUri.queryParameters['employee_id'], 'emp_104');
      expect(recordedUri.queryParameters['start_date'], '2026-09-01');
      expect(recordedUri.queryParameters['end_date'], '2026-09-30');
      expect(recordedUri.queryParameters['status'], 'Present');
    });

    test('translates 401 Unauthorized to AttendanceException', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 401,
        jsonBody: '{"error": "unauthorized"}',
      );

      expect(
        () => repository.getAttendanceRecords(),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Unauthorized: Session has expired'),
          ),
        ),
      );
    });

    test('translates 403 Forbidden to AttendanceException', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": "forbidden"}',
      );

      expect(
        () => repository.getAttendanceRecords(),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Access denied'),
          ),
        ),
      );
    });

    test('translates network failure without mock fallback', () async {
      transport.simulateConnectionFailure = true;

      expect(
        () => repository.getAttendanceRecords(),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Connection failure'),
          ),
        ),
      );
    });
  });

  group('BackendAttendanceRepository - getAttendanceById()', () {
    test('fetches single attendance record by ID successfully', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance/att_001',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "att_001",
          "employee_id": "emp_101",
          "date": "2026-09-21",
          "status": "Present",
          "check_in": "2026-09-21T09:00:00Z",
          "check_out": "2026-09-21T18:00:00Z"
        }
        ''',
      );

      final record = await repository.getAttendanceById('att_001');

      expect(record, isNotNull);
      expect(record!.id, 'att_001');
      expect(record.employeeId, 'emp_101');
      expect(record.attendanceStatus, 'Present');
    });

    test('returns null when server responds with 404 Not Found', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance/att_999',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "not_found"}',
      );

      final record = await repository.getAttendanceById('att_999');

      expect(record, isNull);
    });

    test('returns null immediately when empty ID is passed', () async {
      final record = await repository.getAttendanceById('   ');

      expect(record, isNull);
      expect(transport.recordedRequests, isEmpty);
    });
  });

  group('BackendAttendanceRepository - getAttendanceForEmployee() & getAttendanceForDate()', () {
    test('getAttendanceForEmployee queries records with employee_id', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getAttendanceForEmployee('emp_101');

      expect(transport.recordedRequests.length, 1);
      expect(transport.recordedRequests.first.uri.queryParameters['employee_id'], 'emp_101');
    });

    test('getAttendanceForDate queries records with normalized start and end date', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '[]',
      );

      await repository.getAttendanceForDate(DateTime(2026, 9, 21, 14, 30));

      expect(transport.recordedRequests.length, 1);
      final params = transport.recordedRequests.first.uri.queryParameters;
      expect(params['start_date'], '2026-09-21');
      expect(params['end_date'], '2026-09-21');
    });
  });

  group('BackendAttendanceRepository - recordAttendance()', () {
    test('sends POST and returns authoritative attendance record', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.post,
        statusCode: 201,
        jsonBody: '''
        {
          "id": "att_new_101",
          "employee_id": "emp_101",
          "date": "2026-09-25",
          "status": "Present",
          "check_in": "2026-09-25T09:00:00Z"
        }
        ''',
      );

      final record = AttendanceRecord(
        id: 'att_temp',
        employeeId: 'emp_101',
        date: DateTime.utc(2026, 9, 25),
        attendanceStatus: 'Present',
        checkIn: DateTime.utc(2026, 9, 25, 9, 0),
      );

      final saved = await repository.recordAttendance(record);

      expect(saved.id, 'att_new_101');
      expect(saved.employeeId, 'emp_101');
      expect(saved.attendanceStatus, 'Present');
      expect(transport.recordedRequests.length, 1);
      expect(transport.recordedRequests.first.method, HttpMethod.post);
    });

    test('throws AttendanceException if employee ID is empty', () async {
      final record = AttendanceRecord(
        id: 'att_invalid',
        employeeId: '   ',
        date: DateTime.utc(2026, 9, 25),
        attendanceStatus: 'Present',
      );

      expect(
        () => repository.recordAttendance(record),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Employee ID is required'),
          ),
        ),
      );
      expect(transport.recordedRequests, isEmpty);
    });

    test('handles 409 Conflict gracefully', () async {
      transport.registerJson(
        path: '/api/v1/hr/attendance',
        method: HttpMethod.post,
        statusCode: 409,
        jsonBody: '{"error": "conflict", "message": "Attendance record already exists for date"}',
      );

      final record = AttendanceRecord(
        id: 'att_dup',
        employeeId: 'emp_101',
        date: DateTime.utc(2026, 9, 25),
        attendanceStatus: 'Present',
      );

      expect(
        () => repository.recordAttendance(record),
        throwsA(
          isA<AttendanceException>().having(
            (e) => e.message,
            'message',
            contains('Conflict detected'),
          ),
        ),
      );
    });
  });

  group('AttendanceRepositoryFactory - Controlled Cutover', () {
    test('returns BackendAttendanceRepository when config is BackendMode.backend', () {
      final repo = AttendanceRepositoryFactory.create(
        config: config,
        apiClient: apiClient,
      );

      expect(repo, isA<BackendAttendanceRepository>());
    });

    test('returns MockAttendanceRepository when config is BackendMode.mock', () {
      final mockConfig = BackendConfig.development(
        baseUrl: 'http://127.0.0.1:8000',
        mode: BackendMode.mock,
      );

      final repo = AttendanceRepositoryFactory.create(
        config: mockConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<MockAttendanceRepository>());
    });
  });
}
