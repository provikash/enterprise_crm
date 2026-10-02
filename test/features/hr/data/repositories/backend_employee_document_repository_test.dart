import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/employee_document_repository_factory.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/domain/inputs/upload_document_input.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/employee_document_repository.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeDocumentRepository repository;

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
    repository = BackendEmployeeDocumentRepository(apiClient: apiClient);
  });

  group('BackendEmployeeDocumentRepository - getDocumentsForEmployee()', () {
    test('fetches documents list from JSON array', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "doc_001",
            "employee_id": "emp_101",
            "title": "Resume",
            "file_name": "resume.pdf",
            "file_extension": "pdf",
            "file_size_bytes": 102400,
            "document_type": "Resume"
          }
        ]
        ''',
      );

      final documents = await repository.getDocumentsForEmployee('emp_101');

      expect(documents.length, 1);
      expect(documents.first.id, 'doc_001');
      expect(documents.first.employeeId, 'emp_101');
      expect(documents.first.title, 'Resume');
    });

    test('returns empty list immediately when employeeId is empty', () async {
      final documents = await repository.getDocumentsForEmployee('   ');

      expect(documents, isEmpty);
      expect(transport.recordedRequests, isEmpty);
    });

    test('translates 401 Unauthorized to EmployeeDocumentException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 401,
        jsonBody: '{"error": "unauthorized"}',
      );

      expect(
        () => repository.getDocumentsForEmployee('emp_101'),
        throwsA(
          isA<EmployeeDocumentException>().having(
            (e) => e.code,
            'code',
            'unauthorized',
          ),
        ),
      );
    });

    test('translates 403 Forbidden to EmployeeDocumentException', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 403,
        jsonBody: '{"error": "forbidden"}',
      );

      expect(
        () => repository.getDocumentsForEmployee('emp_101'),
        throwsA(
          isA<EmployeeDocumentException>().having(
            (e) => e.code,
            'code',
            'forbidden',
          ),
        ),
      );
    });

    test('translates network failure without mock fallback', () async {
      transport.simulateConnectionFailure = true;

      expect(
        () => repository.getDocumentsForEmployee('emp_101'),
        throwsA(
          isA<EmployeeDocumentException>().having(
            (e) => e.code,
            'code',
            'connection_error',
          ),
        ),
      );
    });
  });

  group('BackendEmployeeDocumentRepository - getDocumentById()', () {
    test('fetches document by ID successfully', () async {
      transport.registerJson(
        path: '/api/v1/hr/documents/doc_001',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        {
          "id": "doc_001",
          "employee_id": "emp_101",
          "title": "Resume",
          "file_name": "resume.pdf",
          "file_extension": "pdf",
          "file_size_bytes": 102400,
          "document_type": "Resume"
        }
        ''',
      );

      final doc = await repository.getDocumentById('doc_001');

      expect(doc, isNotNull);
      expect(doc!.id, 'doc_001');
      expect(doc.title, 'Resume');
    });

    test('returns null when document is not found (404)', () async {
      transport.registerJson(
        path: '/api/v1/hr/documents/doc_999',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "not_found"}',
      );

      final doc = await repository.getDocumentById('doc_999');

      expect(doc, isNull);
    });

    test('returns null immediately when empty documentId is passed', () async {
      final doc = await repository.getDocumentById('   ');

      expect(doc, isNull);
      expect(transport.recordedRequests, isEmpty);
    });
  });

  group('BackendEmployeeDocumentRepository - uploadDocument()', () {
    test('uploads document successfully via POST with base64 payload', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.post,
        statusCode: 201,
        jsonBody: '''
        {
          "id": "doc_new_01",
          "employee_id": "emp_101",
          "title": "National ID",
          "file_name": "id.png",
          "file_extension": "png",
          "file_size_bytes": 1024,
          "document_type": "Identity"
        }
        ''',
      );

      final input = UploadDocumentInput(
        employeeId: 'emp_101',
        title: 'National ID',
        documentType: 'Identity',
        fileName: 'id.png',
        fileExtension: 'png',
        fileSizeBytes: 1024,
        fileBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      final created = await repository.uploadDocument(input);

      expect(created.id, 'doc_new_01');
      expect(created.title, 'National ID');
      expect(transport.recordedRequests.length, 1);
      expect(transport.recordedRequests.first.method, HttpMethod.post);
    });

    test('validates input locally and throws EmployeeDocumentException before network call', () async {
      final input = UploadDocumentInput(
        employeeId: 'emp_101',
        title: '   ', // empty title
        documentType: 'Identity',
        fileName: 'id.png',
        fileExtension: 'png',
        fileSizeBytes: 1024,
        fileBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(
        () => repository.uploadDocument(input),
        throwsA(
          isA<EmployeeDocumentException>().having(
            (e) => e.code,
            'code',
            'validation_error',
          ),
        ),
      );
      expect(transport.recordedRequests, isEmpty);
    });
  });

  group('BackendEmployeeDocumentRepository - downloadDocumentFile()', () {
    test('downloads document binary and decodes base64 payload', () async {
      final rawBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final base64String = base64Encode(rawBytes);

      transport.registerJson(
        path: '/api/v1/hr/documents/doc_001/download',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '{"file_content_base64": "$base64String"}',
      );

      final bytes = await repository.downloadDocumentFile('doc_001');

      expect(bytes, rawBytes);
    });

    test('throws not found exception when download responds with 404', () async {
      transport.registerJson(
        path: '/api/v1/hr/documents/doc_404/download',
        method: HttpMethod.get,
        statusCode: 404,
        jsonBody: '{"error": "not_found"}',
      );

      expect(
        () => repository.downloadDocumentFile('doc_404'),
        throwsA(
          isA<EmployeeDocumentException>().having(
            (e) => e.code,
            'code',
            'not_found',
          ),
        ),
      );
    });
  });

  group('EmployeeDocumentRepositoryFactory - Controlled Cutover', () {
    test('returns BackendEmployeeDocumentRepository when config is BackendMode.backend', () {
      final repo = EmployeeDocumentRepositoryFactory.create(
        config: config,
        apiClient: apiClient,
      );

      expect(repo, isA<BackendEmployeeDocumentRepository>());
    });

    test('returns MockEmployeeDocumentRepository when config is BackendMode.mock', () {
      final mockConfig = BackendConfig.development(
        baseUrl: 'http://127.0.0.1:8000',
        mode: BackendMode.mock,
      );

      final repo = EmployeeDocumentRepositoryFactory.create(
        config: mockConfig,
        apiClient: apiClient,
      );

      expect(repo, isA<MockEmployeeDocumentRepository>());
    });
  });
}
