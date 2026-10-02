import '../mock/mock_payroll_store.dart';
import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/payroll_repository.dart';
import 'backend_payroll_repository.dart';
import 'mock_payroll_repository.dart';

/// Factory for instantiating the appropriate [PayrollRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.8 to govern the controlled cutover between deterministic mock repositories
/// and live backend adapters for Payroll and Compensation management.
///
/// Invariants:
/// - When [config.mode] is [BackendMode.backend], creates [BackendPayrollRepository] bound to [apiClient].
/// - When [config.mode] is [BackendMode.mock], creates [MockPayrollRepository].
/// - Strictly prohibits silent mock fallback when in backend mode.
class PayrollRepositoryFactory {
  static PayrollRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockPayrollStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendPayrollRepository(apiClient: apiClient);
    }
    return MockPayrollRepository(store: mockStore);
  }
}
