import '../mock/mock_employee_document_store.dart';
import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/employee_document_repository.dart';
import 'backend_employee_document_repository.dart';
import 'mock_employee_document_repository.dart';

/// Factory for instantiating the appropriate [EmployeeDocumentRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.5 to govern the controlled cutover for Employee Documents.
///
/// Invariants:
/// - When [config.mode] is [BackendMode.backend], creates [BackendEmployeeDocumentRepository] bound to [apiClient].
/// - When [config.mode] is [BackendMode.mock], creates [MockEmployeeDocumentRepository].
/// - Strictly prohibits silent mock fallback when in backend mode.
class EmployeeDocumentRepositoryFactory {
  static EmployeeDocumentRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockEmployeeDocumentStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendEmployeeDocumentRepository(apiClient: apiClient);
    }
    return MockEmployeeDocumentRepository(store: mockStore);
  }
}
