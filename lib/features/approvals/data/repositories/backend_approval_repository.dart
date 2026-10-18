import 'package:dio/dio.dart';

import '../../../../features/auth/domain/entities/crm_module.dart';
import '../../../../features/auth/domain/entities/current_user.dart';
import '../../domain/entities/approval_activity.dart';
import '../../domain/entities/approval_priority.dart';
import '../../domain/entities/approval_request.dart';
import '../../domain/entities/approval_status.dart';
import '../../domain/exceptions/approvals_network_exception.dart';
import '../../domain/inputs/create_approval_request_input.dart';
import '../../domain/repositories/approval_repository.dart';
import '../dto/approval_request_dto.dart';

/// Production REST API implementation of [ApprovalRepository] powered by Dio.
///
/// Adheres strictly to the Zero Silent Fallback rule: any network or server
/// failure throws an explicit [ApprovalsNetworkException] rather than masking errors.
class BackendApprovalRepository implements ApprovalRepository {
  final Dio dio;
  final String basePath;

  const BackendApprovalRepository({
    required this.dio,
    this.basePath = '/api/v1',
  });

  ApprovalsNetworkException _mapError(dynamic error) {
    if (error is ApprovalsNetworkException) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      String? message;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['message'] ?? data['error'])?.toString();
      }
      return ApprovalsNetworkException(
        message ?? error.message ?? 'Backend network failure in Approvals.',
        statusCode: status,
        originalError: error,
      );
    }
    return ApprovalsNetworkException(
      error.toString(),
      originalError: error,
    );
  }

  @override
  Future<List<ApprovalRequest>> getApprovals({
    ApprovalStatus? status,
    CrmModule? module,
    ApprovalPriority? priority,
    String? requesterId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null) 'status': status.name,
        if (module != null) 'module': module.name,
        if (priority != null) 'priority': priority.name,
        'requester_id': ?requesterId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await dio.get<dynamic>(
        '$basePath/approvals',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> rawList;
      if (data is Map<String, dynamic> && data['items'] is List<dynamic>) {
        rawList = data['items'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        rawList = data;
      } else {
        return const [];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => ApprovalRequestDto.fromJson(json).toDomain())
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest?> getApprovalById(String id) async {
    try {
      final response = await dio.get<dynamic>('$basePath/approvals/$id');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest> submitRequest(CreateApprovalRequestInput input) async {
    try {
      final payload = {
        'module': input.module.name,
        'entity_type': input.entityType,
        'entity_id': input.entityId,
        'entity_title': input.entityTitle,
        'requester_id': input.requesterId,
        'requester_name': input.requesterName,
        if (input.departmentId != null) 'department_id': input.departmentId,
        if (input.departmentName != null)
          'department_name': input.departmentName,
        'priority': input.priority.name,
        if (input.amount != null) 'amount': input.amount,
        if (input.currencyCode != null) 'currency_code': input.currencyCode,
        if (input.steps.isNotEmpty)
          'steps': input.steps
              .map((s) => ApprovalStepDto.fromDomain(s).toJson())
              .toList(),
        if (input.metadata.isNotEmpty) 'metadata': input.metadata,
      };

      final response = await dio.post<dynamic>(
        '$basePath/approvals',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      throw const ApprovalsNetworkException(
        'Invalid response payload from submit approval request endpoint.',
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest> approveRequest({
    required String requestId,
    required CurrentUser actor,
    String? comment,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        '$basePath/approvals/$requestId/approve',
        data: {
          'comment': ?comment,
          'actor_id': actor.id,
          'actor_name': actor.displayName,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      throw const ApprovalsNetworkException('Invalid approve response format.');
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest> rejectRequest({
    required String requestId,
    required CurrentUser actor,
    required String rejectionReason,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        '$basePath/approvals/$requestId/reject',
        data: {
          'rejection_reason': rejectionReason,
          'actor_id': actor.id,
          'actor_name': actor.displayName,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      throw const ApprovalsNetworkException('Invalid reject response format.');
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest> requestRevision({
    required String requestId,
    required CurrentUser actor,
    required String revisionNotes,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        '$basePath/approvals/$requestId/revision',
        data: {
          'revision_notes': revisionNotes,
          'actor_id': actor.id,
          'actor_name': actor.displayName,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      throw const ApprovalsNetworkException('Invalid revision response format.');
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ApprovalRequest> cancelRequest({
    required String requestId,
    required CurrentUser actor,
    String? reason,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        '$basePath/approvals/$requestId/cancel',
        data: {
          'reason': ?reason,
          'actor_id': actor.id,
          'actor_name': actor.displayName,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ApprovalRequestDto.fromJson(data).toDomain();
      }
      throw const ApprovalsNetworkException('Invalid cancel response format.');
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<ApprovalActivity>> getAuditTrail(String requestId) async {
    try {
      final response = await dio.get<dynamic>(
        '$basePath/approvals/$requestId/audit',
      );

      final data = response.data;
      final List<dynamic> rawList;
      if (data is Map<String, dynamic> && data['items'] is List<dynamic>) {
        rawList = data['items'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        rawList = data;
      } else {
        return const [];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => ApprovalActivityDto.fromJson(json).toDomain())
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }
}
