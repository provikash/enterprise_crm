import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../dto/attendance_record_dto.dart';
import '../network/backend_adapter.dart';
import '../network/network_exception.dart';

/// Backend-backed implementation of [AttendanceRepository].
///
/// Established in HR-10.6 as the production-compatible attendance adapter.
/// Communicates with the instructor backend via the shared [ApiClient] transport.
///
/// Invariants:
/// - Connects to `/hr/attendance` endpoints.
/// - Never silently falls back to mock fixtures in backend mode.
/// - Translates typed [NetworkException] into the domain [AttendanceException].
/// - Normalizes all calendar dates to UTC midnight.
/// - Missing attendance entries are NEVER fabricated as 'Absent'.
/// - Payroll calculations, overtime pay, and deduction formulas are strictly excluded.
class BackendAttendanceRepository extends BackendAdapter
    implements AttendanceRepository {
  BackendAttendanceRepository({required super.apiClient});

  @override
  Future<List<AttendanceRecord>> getAttendanceRecords({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
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
    if (status != null && status.trim().isNotEmpty && status.trim().toLowerCase() != 'all') {
      queryParams['status'] = status.trim();
    }

    try {
      final response = await apiClient.get(
        '/hr/attendance',
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
          return const <AttendanceRecord>[];
        }
      } else {
        return const <AttendanceRecord>[];
      }

      return rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return AttendanceRecordDto.fromJson(item).toDomain();
        } else if (item is Map) {
          return AttendanceRecordDto.fromJson(Map<String, dynamic>.from(item)).toDomain();
        } else {
          throw const FormatException('Expected JSON map for attendance record item.');
        }
      }).toList();
    } on NetworkException catch (e) {
      throw _mapNetworkException(e, operation: 'loading attendance records');
    } catch (e) {
      throw AttendanceException('Failed to load attendance records: $e');
    }
  }

  @override
  Future<AttendanceRecord?> getAttendanceById(String id) async {
    final sanitizedId = id.trim();
    if (sanitizedId.isEmpty) {
      return null;
    }

    try {
      final response = await apiClient.get('/hr/attendance/$sanitizedId');
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
        throw const FormatException('Expected JSON map for attendance record.');
      }

      return AttendanceRecordDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _mapNetworkException(e, operation: 'loading attendance record "$sanitizedId"');
    } catch (e) {
      throw AttendanceException('Failed to load attendance record: $e');
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForEmployee(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sanitizedEmpId = employeeId.trim();
    if (sanitizedEmpId.isEmpty) {
      return const <AttendanceRecord>[];
    }

    return getAttendanceRecords(
      employeeId: sanitizedEmpId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return getAttendanceRecords(
      startDate: normalizedDate,
      endDate: normalizedDate,
    );
  }

  @override
  Future<AttendanceRecord> recordAttendance(AttendanceRecord record) async {
    final sanitizedEmpId = record.employeeId.trim();
    if (sanitizedEmpId.isEmpty) {
      throw const AttendanceException('Employee ID is required to record attendance.');
    }
    if (record.attendanceStatus.trim().isEmpty) {
      throw const AttendanceException('Attendance status is required.');
    }

    final dto = AttendanceRecordDto.fromDomain(record);
    final payload = dto.toJson();

    try {
      final response = await apiClient.post(
        '/hr/attendance',
        body: payload,
      );

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
        throw const FormatException('Expected JSON map in attendance recording response.');
      }

      return AttendanceRecordDto.fromJson(rawMap).toDomain();
    } on NetworkException catch (e) {
      throw _mapNetworkException(e, operation: 'recording attendance for employee "$sanitizedEmpId"');
    } catch (e) {
      throw AttendanceException('Failed to record attendance: $e');
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  AttendanceException _mapNetworkException(
    NetworkException e, {
    required String operation,
  }) {
    if (e is UnauthorizedException) {
      return const AttendanceException(
        'Unauthorized: Session has expired or is invalid. Please log in again.',
        code: 'UNAUTHORIZED',
      );
    }
    if (e is ForbiddenException) {
      return const AttendanceException(
        'Access denied: You do not have permission to view or manage attendance records.',
        code: 'FORBIDDEN',
      );
    }
    if (e is NotFoundException) {
      return AttendanceException(
        'Attendance record not found while $operation.',
        code: 'NOT_FOUND',
      );
    }
    if (e is ConflictException) {
      return AttendanceException(
        'Conflict detected while $operation: attendance record already exists for this date.',
        code: 'CONFLICT',
      );
    }
    if (e is NetworkTimeoutException) {
      return AttendanceException(
        'Network timeout while $operation. Please try again.',
        code: 'TIMEOUT',
      );
    }
    if (e is ConnectionException) {
      return AttendanceException(
        'Connection failure while $operation. Check your internet connection.',
        code: 'CONNECTION_FAILURE',
      );
    }
    if (e is ServerException) {
      return AttendanceException(
        'Backend server error (${e.statusCode}) while $operation. Please try again later.',
        code: 'SERVER_ERROR',
      );
    }
    if (e is ValidationException) {
      return AttendanceException('Validation error: ${e.message}', code: 'VALIDATION_ERROR');
    }
    if (e is InvalidResponseException) {
      return const AttendanceException('Received invalid response format from backend server.', code: 'INVALID_RESPONSE');
    }
    return AttendanceException(e.message, code: 'NETWORK_ERROR');
  }
}
