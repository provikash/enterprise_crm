import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../dto/payroll_period_dto.dart';
import '../dto/payroll_record_dto.dart';
import '../network/backend_adapter.dart';
import '../network/network_exception.dart';

/// Backend-backed implementation of [PayrollRepository].
///
/// Established in HR-10.8 as the production-compatible Payroll adapter.
/// Communicates with the instructor backend via the shared [ApiClient] transport.
///
/// Invariants:
/// - Connects to `/hr/payroll/periods` and `/hr/payroll/records` endpoints.
/// - Never silently falls back to mock fixtures in backend mode.
/// - Translates typed [NetworkException] into domain [PayrollException].
/// - Strictly read-only; mutation, disbursement, and finalization are prohibited.
/// - Preserves monetary figures and currency codes without rounding or fabrication.
/// - Missing compensation records are never fabricated as 0.0.
class BackendPayrollRepository extends BackendAdapter
    implements PayrollRepository {
  BackendPayrollRepository({required super.apiClient});

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async {
    try {
      final response = await apiClient.get('/hr/payroll/periods');

      final List<dynamic> rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          rawList = response['data'] as List;
        } else if (response['periods'] is List) {
          rawList = response['periods'] as List;
        } else {
          rawList = [response];
        }
      } else {
        throw const PayrollException(
          'Unexpected response format from payroll periods endpoint.',
        );
      }

      return rawList.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const PayrollException('Invalid item structure in payroll periods list.');
        }
        return PayrollPeriodDto.fromJson(item).toDomain();
      }).toList();
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw PayrollException('Payroll period serialization error: ${e.message}');
    }
  }

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async {
    if (id.trim().isEmpty) {
      throw const PayrollException('Payroll period ID cannot be empty.');
    }

    try {
      final response = await apiClient.get('/hr/payroll/periods/${id.trim()}');

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else {
        throw const PayrollException('Unexpected response format for single payroll period.');
      }

      return PayrollPeriodDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw PayrollException('Payroll period serialization error: ${e.message}');
    }
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) async {
    final queryParams = <String, String>{};
    if (payrollPeriodId != null && payrollPeriodId.trim().isNotEmpty) {
      queryParams['period_id'] = payrollPeriodId.trim();
    }
    if (employeeId != null && employeeId.trim().isNotEmpty) {
      queryParams['employee_id'] = employeeId.trim();
    }

    try {
      final response = await apiClient.get(
        '/hr/payroll/records',
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        if (response['data'] is List) {
          rawList = response['data'] as List;
        } else if (response['records'] is List) {
          rawList = response['records'] as List;
        } else {
          rawList = [response];
        }
      } else {
        throw const PayrollException(
          'Unexpected response format from payroll records endpoint.',
        );
      }

      return rawList.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const PayrollException('Invalid item structure in payroll records list.');
        }
        return PayrollRecordDto.fromJson(item).toDomain();
      }).toList();
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw PayrollException('Payroll record serialization error: ${e.message}');
    }
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async {
    return getPayrollRecords(payrollPeriodId: periodId);
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(
    String employeeId,
  ) async {
    return getPayrollRecords(employeeId: employeeId);
  }

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async {
    if (id.trim().isEmpty) {
      throw const PayrollException('Payroll record ID cannot be empty.');
    }

    try {
      final response = await apiClient.get('/hr/payroll/records/${id.trim()}');

      final Map<String, dynamic> rawMap;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          rawMap = response['data'] as Map<String, dynamic>;
        } else {
          rawMap = response;
        }
      } else {
        throw const PayrollException('Unexpected response format for single payroll record.');
      }

      return PayrollRecordDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _translateNetworkException(e);
    } on FormatException catch (e) {
      throw PayrollException('Payroll record serialization error: ${e.message}');
    }
  }

  PayrollException _translateNetworkException(NetworkException e) {
    if (e is UnauthorizedException) {
      return const PayrollException(
        'Authentication required to access payroll records.',
        code: 'UNAUTHORIZED',
      );
    }
    if (e is ForbiddenException) {
      return const PayrollException(
        'Insufficient permissions to access payroll records.',
        code: 'FORBIDDEN',
      );
    }
    if (e is NetworkTimeoutException) {
      return const PayrollException(
        'Payroll network request timed out. Please try again.',
        code: 'TIMEOUT',
      );
    }
    return PayrollException(
      e.message.isNotEmpty ? e.message : 'Failed to communicate with payroll service.',
    );
  }
}
