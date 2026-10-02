import 'api_client.dart';
import 'backend_config.dart';

/// Base contract for feature-level backend repository adapters.
///
/// Established in HR-10.2 to define the architectural boundary for subsequent
/// HR-10 checkpoints (HR-10.3 Employee, HR-10.4 Attendance, etc.).
///
/// Invariants:
/// - Repository adapters communicate with the backend exclusively via [apiClient].
/// - When [config.mode] is [BackendMode.mock], mock implementations are utilized.
/// - When [config.mode] is [BackendMode.backend], backend adapters execute live requests
///   and NEVER silently fall back to mock data on error.
abstract class BackendAdapter {
  final ApiClient apiClient;

  const BackendAdapter({required this.apiClient});

  /// The active backend configuration.
  BackendConfig get config => apiClient.config;

  /// Returns `true` if configured to execute requests against the live backend API.
  bool get isBackendMode => config.mode.isBackend;

  /// Returns `true` if configured in deterministic mock mode.
  bool get isMockMode => config.mode.isMock;
}
