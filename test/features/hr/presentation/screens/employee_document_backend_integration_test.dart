import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/features/auth/domain/entities/account_type.dart';
import 'package:enterprise_crm/features/auth/domain/entities/crm_module.dart';
import 'package:enterprise_crm/features/auth/domain/entities/current_user.dart';
import 'package:enterprise_crm/features/hr/data/network/api_client.dart';
import 'package:enterprise_crm/features/hr/data/network/api_transport.dart';
import 'package:enterprise_crm/features/hr/data/network/backend_config.dart';
import 'package:enterprise_crm/features/hr/data/network/mock_api_transport.dart';
import 'package:enterprise_crm/features/hr/data/repositories/backend_employee_document_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/employee.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_documents_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/screens/employee_documents_screen.dart';

void main() {
  late MockApiTransport transport;
  late BackendConfig config;
  late ApiClient apiClient;
  late BackendEmployeeDocumentRepository repository;

  final adminUser = const CurrentUser(
    id: 'usr_admin',
    displayName: 'Admin User',
    accountType: AccountType.admin,
    modules: {CrmModule.hrPayroll},
    permissions: {'hr_view', 'hr_edit'},
  );

  const testEmployee = Employee(
    id: 'emp_101',
    fullName: 'Aarav Sharma',
    department: 'Engineering',
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
      authTokenProvider: () => 'valid_jwt_token',
    );
    repository = BackendEmployeeDocumentRepository(apiClient: apiClient);
  });

  group('HR-10.5 Employee Documents - Cubit & Screen Integration', () {
    test('EmployeeDocumentsCubit loads documents via BackendEmployeeDocumentRepository', () async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "doc_001",
            "employee_id": "emp_101",
            "title": "Master Degree",
            "file_name": "degree.pdf",
            "file_extension": "pdf",
            "file_size_bytes": 1048576,
            "document_type": "Education"
          }
        ]
        ''',
      );

      final cubit = EmployeeDocumentsCubit(repository, employeeId: 'emp_101');
      await cubit.loadDocuments();

      expect(cubit.state.documents.length, 1);
      expect(cubit.state.documents.first.title, 'Master Degree');

      await cubit.close();
    });

    testWidgets('EmployeeDocumentsScreen renders backend documents and handles retry on failure', (tester) async {
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 500,
        jsonBody: '{"error": "server_down"}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDocumentsScreen(
            user: adminUser,
            employee: testEmployee,
            repository: repository,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Backend server error (500)'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now register success on transport and tap Retry
      transport.registerJson(
        path: '/api/v1/hr/employees/emp_101/documents',
        method: HttpMethod.get,
        statusCode: 200,
        jsonBody: '''
        [
          {
            "id": "doc_001",
            "employee_id": "emp_101",
            "title": "Master Degree",
            "file_name": "degree.pdf",
            "file_extension": "pdf",
            "file_size_bytes": 1048576,
            "document_type": "Education"
          }
        ]
        ''',
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Master Degree'), findsOneWidget);
    });
  });
}
