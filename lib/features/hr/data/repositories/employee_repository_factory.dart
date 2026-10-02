import '../mock/mock_employee_store.dart';
import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/employee_repository.dart';
import 'backend_employee_repository.dart';
import 'mock_employee_repository.dart';

/// Factory for instantiating the appropriate [EmployeeRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.4 to govern the controlled cutover between deterministic mock repositories
/// and live backend adapters.
///
/// Invariants:
/// - When [config.mode] is [BackendMode.backend], creates [BackendEmployeeRepository] bound to [apiClient].
/// - When [config.mode] is [BackendMode.mock], creates [MockEmployeeRepository].
/// - Strictly prohibits silent mock fallback when in backend mode.
class EmployeeRepositoryFactory {
  static EmployeeRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockEmployeeStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendEmployeeRepository(apiClient: apiClient);
    }
    return MockEmployeeRepository(store: mockStore);
  }
}
