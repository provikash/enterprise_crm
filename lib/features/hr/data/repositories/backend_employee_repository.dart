import '../../domain/entities/employee.dart';
import '../../domain/inputs/create_employee_input.dart';
import '../../domain/inputs/update_employee_input.dart';
import '../../domain/repositories/employee_repository.dart';
import '../dto/employee_dto.dart';
import '../network/backend_adapter.dart';
import '../network/network_exception.dart';

/// Backend-backed implementation of [EmployeeRepository].
///
/// Established in HR-10.3 as the first production-compatible HR repository adapter.
/// Communicates with the instructor backend via the shared [ApiClient] transport.
///
/// Invariants:
/// - Executes requests against the configured backend base URL and `/hr/employees` route.
/// - Never silently falls back to mock fixtures in backend mode.
/// - Maps strongly typed [NetworkException] into the domain [EmployeeException].
/// - Preserves stable [Employee.id] and [CurrentUser.id] identity boundaries.
class BackendEmployeeRepository extends BackendAdapter
    implements EmployeeRepository {
  BackendEmployeeRepository({required super.apiClient});

  @override
  Future<List<Employee>> getEmployees({
    String? search,
    String? department,
    String? status,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (department != null && department.trim().isNotEmpty) {
      queryParams['department'] = department.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (page != null && page > 0) {
      queryParams['page'] = page.toString();
    }
    if (pageSize != null && pageSize > 0) {
      queryParams['page_size'] = pageSize.toString();
    }

    try {
      final response = await apiClient.get(
        '/hr/employees',
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        final items = response['items'] ?? response['results'] ?? response['data'];
        if (items is List) {
          rawList = items;
        } else {
          return const <Employee>[];
        }
      } else {
        return const <Employee>[];
      }

      return rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return EmployeeDto.fromJson(item).toDomain();
        } else if (item is Map) {
          return EmployeeDto.fromJson(Map<String, dynamic>.from(item)).toDomain();
        } else {
          throw const FormatException('Expected JSON map for employee item.');
        }
      }).toList();
    } on NetworkException catch (e) {
      throw _mapNetworkException(e, operation: 'loading employee directory');
    } catch (e) {
      throw EmployeeException('Failed to load employee directory: $e');
    }
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final sanitizedId = id.trim();
    if (sanitizedId.isEmpty) {
      return null;
    }

    try {
      final response = await apiClient.get('/hr/employees/$sanitizedId');

      if (response == null) {
        return null;
      }

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else if (response is Map) {
        rawMap = Map<String, dynamic>.from(response);
      } else {
        throw const FormatException('Expected JSON map for employee details.');
      }

      return EmployeeDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _mapNetworkException(
        e,
        operation: 'loading employee details for id "$sanitizedId"',
      );
    } catch (e) {
      throw EmployeeException('Failed to load employee details: $e');
    }
  }

  @override
  Future<Employee> createEmployee(CreateEmployeeInput input) async {
    // In HR-10.3, write operations are deferred to HR-10.4.
    throw const EmployeeException(
      'Employee creation via backend is deferred to HR-10.4.',
    );
  }

  @override
  Future<Employee> updateEmployee(UpdateEmployeeInput input) async {
    // In HR-10.3, write operations are deferred to HR-10.4.
    throw const EmployeeException(
      'Employee update via backend is deferred to HR-10.4.',
    );
  }

  /// Maps typed [NetworkException] to user-facing domain [EmployeeException].
  EmployeeException _mapNetworkException(
    NetworkException e, {
    required String operation,
  }) {
    if (e is UnauthorizedException) {
      return const EmployeeException(
        'Unauthorized: Session has expired or is invalid. Please log in again.',
      );
    }
    if (e is ForbiddenException) {
      return const EmployeeException(
        'Access denied: You do not have permission to view employee records.',
      );
    }
    if (e is NetworkTimeoutException) {
      return EmployeeException(
        'Network timeout while $operation. Please try again.',
      );
    }
    if (e is ConnectionException) {
      return EmployeeException(
        'Connection failure while $operation. Check your internet connection.',
      );
    }
    if (e is ServerException) {
      return EmployeeException(
        'Backend server error (${e.statusCode}) while $operation. Please try again later.',
      );
    }
    if (e is ValidationException) {
      return EmployeeException('Validation error: ${e.message}');
    }
    if (e is InvalidResponseException) {
      return const EmployeeException('Received invalid response format from backend server.');
    }
    return EmployeeException(e.message);
  }
}
