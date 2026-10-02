import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/network_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BackendConfig config;
  late MockApiTransport transport;
  late ApiClient client;
  String? activeToken;

  setUp(() {
    config = BackendConfig.development(
      baseUrl: 'https://test-api.crm.example.com',
    );
    transport = MockApiTransport();
    activeToken = 'mock_jwt_token_123';
    client = ApiClient(
      config: config,
      transport: transport,
      authTokenProvider: () => activeToken,
    );
  });

  group('HR-10.2 — ApiClient HTTP Operations & JSON Parsing', () {
    test('successful GET request parses JSON payload', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees',
        jsonBody: '{"items": [{"id": "emp_1", "name": "John Doe"}]}',
      );

      final result = await client.get('/hr/employees');

      expect(result, isA<Map<String, dynamic>>());
      expect(result['items'], isA<List>());
      expect(result['items'].first['name'], 'John Doe');

      // Verify request header attachment
      expect(transport.recordedRequests.length, 1);
      final req = transport.recordedRequests.first;
      expect(req.headers['accept'], 'application/json');
      expect(req.headers['authorization'], 'Bearer mock_jwt_token_123');
    });

    test('GET request appends query parameters cleanly', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees',
        jsonBody: '{"items": []}',
      );

      await client.get(
        '/hr/employees',
        queryParams: {'department': 'Engineering', 'page': '1'},
      );

      expect(transport.recordedRequests.length, 1);
      final req = transport.recordedRequests.first;
      expect(req.uri.queryParameters['department'], 'Engineering');
      expect(req.uri.queryParameters['page'], '1');
    });

    test('successful POST serializes request body and returns JSON', () async {
      transport.registerJson(
        method: HttpMethod.post,
        path: '/api/v1/hr/employees',
        statusCode: 201,
        jsonBody: '{"id": "emp_99", "name": "Alice Smith"}',
      );

      final payload = {'name': 'Alice Smith', 'department': 'HR'};
      final result = await client.post('/hr/employees', body: payload);

      expect(result['id'], 'emp_99');
      final req = transport.recordedRequests.first;
      expect(req.headers['content-type'], contains('application/json'));
      expect(req.body, contains('"name":"Alice Smith"'));
    });

    test('successful PUT, PATCH, and DELETE execute with correct HTTP methods', () async {
      transport.registerJson(
        method: HttpMethod.put,
        path: '/api/v1/hr/employees/emp_1',
        jsonBody: '{"id": "emp_1", "status": "active"}',
      );
      transport.registerJson(
        method: HttpMethod.patch,
        path: '/api/v1/hr/employees/emp_1',
        jsonBody: '{"id": "emp_1", "status": "on_leave"}',
      );
      transport.registerJson(
        method: HttpMethod.delete,
        path: '/api/v1/hr/employees/emp_1',
        statusCode: 204,
        jsonBody: '',
      );

      final putResult = await client.put('/hr/employees/emp_1', body: {'status': 'active'});
      expect(putResult['status'], 'active');

      final patchResult = await client.patch('/hr/employees/emp_1', body: {'status': 'on_leave'});
      expect(patchResult['status'], 'on_leave');

      final deleteResult = await client.delete('/hr/employees/emp_1');
      expect(deleteResult, isNull);

      expect(transport.recordedRequests.map((r) => r.method).toList(), [
        HttpMethod.put,
        HttpMethod.patch,
        HttpMethod.delete,
      ]);
    });
  });

  group('HR-10.2 — Typed Network Error Handling', () {
    test('HTTP 400 maps to ValidationException', () async {
      transport.registerJson(
        method: HttpMethod.post,
        path: '/api/v1/hr/employees',
        statusCode: 400,
        jsonBody: '{"error": {"code": "VALIDATION_FAILED", "message": "Email is invalid"}}',
      );

      expect(
        () => client.post('/hr/employees', body: {}),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Email is invalid',
        )),
      );
    });

    test('HTTP 401 maps to UnauthorizedException', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees',
        statusCode: 401,
        jsonBody: '{"error": {"code": "TOKEN_EXPIRED", "message": "Session expired"}}',
      );

      expect(
        () => client.get('/hr/employees'),
        throwsA(isA<UnauthorizedException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('HTTP 403 maps to ForbiddenException', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/payroll',
        statusCode: 403,
        jsonBody: '{"error": {"code": "FORBIDDEN", "message": "Missing payrollView permission"}}',
      );

      expect(
        () => client.get('/hr/payroll'),
        throwsA(isA<ForbiddenException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });

    test('HTTP 404 maps to NotFoundException', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees/emp_unknown',
        statusCode: 404,
        jsonBody: '{"error": {"code": "NOT_FOUND", "message": "Employee not found"}}',
      );

      expect(
        () => client.get('/hr/employees/emp_unknown'),
        throwsA(isA<NotFoundException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('HTTP 409 maps to ConflictException', () async {
      transport.registerJson(
        method: HttpMethod.post,
        path: '/api/v1/hr/approvals/appr_1/decision',
        statusCode: 409,
        jsonBody: '{"error": {"code": "DUPLICATE_DECISION", "message": "Request already terminal"}}',
      );

      expect(
        () => client.post('/hr/approvals/appr_1/decision', body: {}),
        throwsA(isA<ConflictException>().having(
          (e) => e.statusCode,
          'statusCode',
          409,
        )),
      );
    });

    test('HTTP 500 maps to ServerException', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/hr/attendance',
        statusCode: 500,
        jsonBody: '{"error": {"code": "INTERNAL_ERROR", "message": "Database error"}}',
      );

      expect(
        () => client.get('/hr/attendance'),
        throwsA(isA<ServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('malformed JSON response on 200 OK throws InvalidResponseException', () async {
      transport.registerHandler(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees',
        handler: (_) => const TransportResponse(
          statusCode: 200,
          headers: {'content-type': 'text/html'},
          body: '<html><body>Error</body></html>',
        ),
      );

      expect(
        () => client.get('/hr/employees'),
        throwsA(isA<InvalidResponseException>().having(
          (e) => e.message,
          'message',
          contains('not valid JSON'),
        )),
      );
    });

    test('transport connectivity failure maps to ConnectionException', () async {
      transport.simulateConnectionFailure = true;

      expect(
        () => client.get('/hr/employees'),
        throwsA(isA<ConnectionException>()),
      );
    });
  });

  group('HR-10.2 — Authentication & Dynamic Session Attachment', () {
    test('omits Authorization header when tokenProvider returns null or empty', () async {
      activeToken = null;

      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/public/info',
        jsonBody: '{"status": "ok"}',
      );

      await client.get('/public/info');

      final req = transport.recordedRequests.first;
      expect(req.headers.containsKey('authorization'), isFalse);
    });

    test('reads dynamic token at request time across session changes', () async {
      transport.registerJson(
        method: HttpMethod.get,
        path: '/api/v1/user/profile',
        jsonBody: '{"id": "usr_1"}',
      );

      // Session 1: User A
      activeToken = 'token_user_a';
      await client.get('/user/profile');
      expect(transport.recordedRequests[0].headers['authorization'], 'Bearer token_user_a');

      // Session 2: User B logs in
      activeToken = 'token_user_b';
      await client.get('/user/profile');
      expect(transport.recordedRequests[1].headers['authorization'], 'Bearer token_user_b');
    });
  });

  group('HR-10.2 — Retry Behavior & Idempotency Controls', () {
    test('GET request retries transient failure up to maxRetries', () async {
      var callCount = 0;
      transport.registerHandler(
        method: HttpMethod.get,
        path: '/api/v1/hr/employees',
        handler: (_) {
          callCount++;
          if (callCount < 3) {
            throw const ConnectionException();
          }
          return const TransportResponse(
            statusCode: 200,
            headers: {'content-type': 'application/json'},
            body: '{"status": "recovered"}',
          );
        },
      );

      final result = await client.get('/hr/employees', maxRetries: 2);
      expect(result['status'], 'recovered');
      expect(callCount, 3);
    });

    test('POST requests are NEVER retried automatically on failure', () async {
      var callCount = 0;
      transport.registerHandler(
        method: HttpMethod.post,
        path: '/api/v1/hr/payroll/disburse',
        handler: (_) {
          callCount++;
          throw const ConnectionException();
        },
      );

      await expectLater(
        client.post('/hr/payroll/disburse', body: {}),
        throwsA(isA<ConnectionException>()),
      );
      expect(callCount, 1);
    });
  });
}
