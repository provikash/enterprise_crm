import '../mock/mock_employee_kpi_store.dart';
import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import 'backend_employee_kpi_repository.dart';
import 'mock_employee_kpi_repository.dart';

/// Factory for instantiating the appropriate [EmployeeKpiRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.7 to govern the controlled cutover between deterministic mock repositories
/// and live backend adapters for KPI and Performance management.
///
/// Invariants:
/// - When [config.mode] is [BackendMode.backend], creates [BackendEmployeeKpiRepository] bound to [apiClient].
/// - When [config.mode] is [BackendMode.mock], creates [MockEmployeeKpiRepository].
/// - Strictly prohibits silent mock fallback when in backend mode.
class EmployeeKpiRepositoryFactory {
  static EmployeeKpiRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockEmployeeKpiStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendEmployeeKpiRepository(apiClient: apiClient);
    }
    return MockEmployeeKpiRepository(store: mockStore);
  }
}
