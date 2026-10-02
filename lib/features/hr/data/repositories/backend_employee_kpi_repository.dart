import '../../domain/entities/employee_kpi.dart';
import '../../domain/repositories/employee_kpi_repository.dart';
import '../dto/employee_kpi_dto.dart';
import '../network/backend_adapter.dart';
import '../network/network_exception.dart';

/// Backend-backed implementation of [EmployeeKpiRepository].
///
/// Established in HR-10.7 as the production-compatible KPI and Performance adapter.
/// Communicates with the instructor backend via the shared [ApiClient] transport.
///
/// Invariants:
/// - Connects to `/hr/kpis` endpoints.
/// - Never silently falls back to mock fixtures in backend mode.
/// - Translates typed [NetworkException] into domain [EmployeeKpiException].
/// - Normalizes all calendar dates to UTC midnight.
/// - Stored scores are preserved verbatim; zero client-side score computation.
/// - Missing KPI records are never fabricated.
class BackendEmployeeKpiRepository extends BackendAdapter
    implements EmployeeKpiRepository {
  BackendEmployeeKpiRepository({required super.apiClient});

  @override
  Future<List<EmployeeKpi>> getKpis({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      queryParams['employee_id'] = employeeId.trim();
    }
    if (startDate != null) {
      queryParams['start_date'] = _formatDate(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = _formatDate(endDate);
    }

    try {
      final response = await apiClient.get(
        '/hr/kpis',
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          rawList = response['data'] as List;
        } else if (response['kpis'] is List) {
          rawList = response['kpis'] as List;
        } else {
          rawList = [response];
        }
      } else {
        throw const EmployeeKpiException(
          'Unexpected response format from KPI listing endpoint.',
        );
      }

      return rawList.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const EmployeeKpiException('Invalid item structure in KPI response list.');
        }
        return EmployeeKpiDto.fromJson(item).toDomain();
      }).toList();
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw EmployeeKpiException('KPI data serialization error: ${e.message}');
    }
  }

  @override
  Future<List<EmployeeKpi>> getKpisForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return getKpis(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<EmployeeKpi?> getKpiById(String id) async {
    if (id.trim().isEmpty) {
      throw const EmployeeKpiException('KPI ID cannot be empty.');
    }

    try {
      final response = await apiClient.get('/hr/kpis/${id.trim()}');

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else {
        throw const EmployeeKpiException('Unexpected response format for single KPI record.');
      }

      return EmployeeKpiDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw EmployeeKpiException('KPI serialization error: ${e.message}');
    }
  }

  @override
  Future<EmployeeKpi> createKpi({
    required String employeeId,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    String? remarks,
  }) async {
    if (employeeId.trim().isEmpty) {
      throw const EmployeeKpiException('Employee ID cannot be empty.');
    }
    if (metricName.trim().isEmpty) {
      throw const EmployeeKpiException('Metric name cannot be empty.');
    }
    final normalizedStart = DateTime.utc(periodStart.year, periodStart.month, periodStart.day);
    final normalizedEnd = DateTime.utc(periodEnd.year, periodEnd.month, periodEnd.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const EmployeeKpiException('Period end date cannot precede start date.');
    }

    final payload = <String, dynamic>{
      'employee_id': employeeId.trim(),
      'metric_name': metricName.trim(),
      'period_start': _formatDate(normalizedStart),
      'period_end': _formatDate(normalizedEnd),
      'target_value': targetValue,
      'actual_value': actualValue,
    };
    if (score != null) {
      payload['score'] = score;
    }
    if (remarks != null && remarks.trim().isNotEmpty) {
      payload['remarks'] = remarks.trim();
    }

    try {
      final response = await apiClient.post(
        '/hr/kpis',
        body: payload,
      );

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else {
        throw const EmployeeKpiException('Unexpected response format when creating KPI.');
      }

      return EmployeeKpiDto.fromJson(rawMap).toDomain();
    } on ConflictException catch (e) {
      throw EmployeeKpiException(
        'A conflicting KPI record already exists for this metric and period: ${e.message}',
      );
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw EmployeeKpiException('KPI creation serialization error: ${e.message}');
    }
  }

  @override
  Future<EmployeeKpi> updateKpi({
    required String id,
    required String metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double targetValue,
    required double actualValue,
    double? score,
    bool clearScore = false,
    String? remarks,
    bool clearRemarks = false,
  }) async {
    if (id.trim().isEmpty) {
      throw const EmployeeKpiException('KPI ID cannot be empty.');
    }
    if (metricName.trim().isEmpty) {
      throw const EmployeeKpiException('Metric name cannot be empty.');
    }
    final normalizedStart = DateTime.utc(periodStart.year, periodStart.month, periodStart.day);
    final normalizedEnd = DateTime.utc(periodEnd.year, periodEnd.month, periodEnd.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const EmployeeKpiException('Period end date cannot precede start date.');
    }

    final payload = <String, dynamic>{
      'metric_name': metricName.trim(),
      'period_start': _formatDate(normalizedStart),
      'period_end': _formatDate(normalizedEnd),
      'target_value': targetValue,
      'actual_value': actualValue,
      'score': clearScore ? null : score,
      'remarks': clearRemarks
          ? null
          : (remarks != null && remarks.trim().isNotEmpty ? remarks.trim() : null),
    };

    try {
      final response = await apiClient.put(
        '/hr/kpis/${id.trim()}',
        body: payload,
      );

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else {
        throw const EmployeeKpiException('Unexpected response format when updating KPI.');
      }

      return EmployeeKpiDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      throw EmployeeKpiException('KPI record with id "$id" not found.');
    } on ConflictException catch (e) {
      throw EmployeeKpiException(
        'A conflicting KPI record was detected during update: ${e.message}',
      );
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw EmployeeKpiException('KPI update serialization error: ${e.message}');
    }
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  EmployeeKpiException _translateNetworkException(NetworkException e) {
    if (e is UnauthorizedException) {
      return const EmployeeKpiException(
        'Authentication required to access KPI records.',
        code: 'UNAUTHORIZED',
      );
    }
    if (e is ForbiddenException) {
      return const EmployeeKpiException(
        'Insufficient permissions to access or modify KPI records.',
        code: 'FORBIDDEN',
      );
    }
    if (e is ValidationException) {
      return EmployeeKpiException(
        'KPI validation failed: ${e.message}',
        code: 'VALIDATION_ERROR',
      );
    }
    if (e is NetworkTimeoutException) {
      return const EmployeeKpiException(
        'KPI network request timed out. Please try again.',
        code: 'TIMEOUT',
      );
    }
    return EmployeeKpiException(
      e.message.isNotEmpty ? e.message : 'Failed to communicate with KPI service.',
    );
  }
}
