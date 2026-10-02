import '../mock/mock_attendance_store.dart';
import '../network/api_client.dart';
import '../network/backend_config.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'backend_attendance_repository.dart';
import 'mock_attendance_repository.dart';

/// Factory for instantiating the appropriate [AttendanceRepository] based on [BackendConfig.mode].
///
/// Established in HR-10.6 to govern the controlled cutover between deterministic mock repositories
/// and live backend adapters.
///
/// Invariants:
/// - When [config.mode] is [BackendMode.backend], creates [BackendAttendanceRepository] bound to [apiClient].
/// - When [config.mode] is [BackendMode.mock], creates [MockAttendanceRepository].
/// - Strictly prohibits silent mock fallback when in backend mode.
class AttendanceRepositoryFactory {
  static AttendanceRepository create({
    required BackendConfig config,
    required ApiClient apiClient,
    MockAttendanceStore? mockStore,
  }) {
    if (config.mode.isBackend) {
      return BackendAttendanceRepository(apiClient: apiClient);
    }
    return MockAttendanceRepository(store: mockStore);
  }
}
