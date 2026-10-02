import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/employee_document.dart';
import '../../domain/inputs/upload_document_input.dart';
import '../../domain/repositories/employee_document_repository.dart';
import '../dto/employee_document_dto.dart';
import '../network/backend_adapter.dart';
import '../network/network_exception.dart';

/// Backend-backed implementation of [EmployeeDocumentRepository].
///
/// Established in HR-10.5 to connect Employee Documents workflows to the instructor backend.
/// Communicates with backend endpoints via the shared [ApiClient] transport.
///
/// Invariants:
/// - Communicates exclusively via [apiClient] using verified `/hr/employees/{id}/documents` routes.
/// - Never silently falls back to mock fixtures on network errors.
/// - Enforces local input validation and transforms network failures into [EmployeeDocumentException].
/// - Strips raw file binaries and sensitive auth tokens from diagnostics and exceptions.
class BackendEmployeeDocumentRepository extends BackendAdapter
    implements EmployeeDocumentRepository {
  BackendEmployeeDocumentRepository({required super.apiClient});

  @override
  Future<List<EmployeeDocument>> getDocumentsForEmployee(
    String employeeId,
  ) async {
    final sanitizedEmpId = employeeId.trim();
    if (sanitizedEmpId.isEmpty) {
      return const <EmployeeDocument>[];
    }

    try {
      final response = await apiClient.get('/hr/employees/$sanitizedEmpId/documents');

      final List<dynamic> rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        final items = response['items'] ?? response['results'] ?? response['data'];
        if (items is List) {
          rawList = items;
        } else {
          return const <EmployeeDocument>[];
        }
      } else {
        return const <EmployeeDocument>[];
      }

      return rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return EmployeeDocumentDto.fromJson(item).toDomain();
        } else if (item is Map) {
          return EmployeeDocumentDto.fromJson(Map<String, dynamic>.from(item)).toDomain();
        } else {
          throw const FormatException('Expected JSON map for employee document item.');
        }
      }).toList();
    } on NetworkException catch (e) {
      throw _mapNetworkException(
        e,
        operation: 'retrieving documents for employee "$sanitizedEmpId"',
      );
    } catch (e) {
      throw EmployeeDocumentException(
        'Failed to retrieve employee documents: $e',
        code: 'retrieval_error',
      );
    }
  }

  @override
  Future<EmployeeDocument?> getDocumentById(String documentId) async {
    final sanitizedDocId = documentId.trim();
    if (sanitizedDocId.isEmpty) {
      return null;
    }

    try {
      final response = await apiClient.get('/hr/documents/$sanitizedDocId');

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
        throw const FormatException('Expected JSON map for document details.');
      }

      return EmployeeDocumentDto.fromJson(rawMap).toDomain();
    } on NotFoundException {
      return null;
    } on NetworkException catch (e) {
      throw _mapNetworkException(
        e,
        operation: 'retrieving document "$sanitizedDocId"',
      );
    } catch (e) {
      throw EmployeeDocumentException(
        'Failed to retrieve document: $e',
        code: 'retrieval_error',
      );
    }
  }

  @override
  Future<EmployeeDocument> uploadDocument(UploadDocumentInput input) async {
    final validationError = input.validate();
    if (validationError != null) {
      throw EmployeeDocumentException(validationError, code: 'validation_error');
    }

    final sanitizedEmpId = input.employeeId.trim();
    final payload = <String, dynamic>{
      'employee_id': sanitizedEmpId,
      'title': input.title.trim(),
      'document_type': input.documentType.trim(),
      'file_name': input.fileName.trim(),
      'file_extension': input.fileExtension.trim(),
      'file_size_bytes': input.fileSizeBytes,
      'file_content_base64': base64Encode(input.fileBytes),
      if (input.expiryDate != null)
        'expiry_date':
            '${input.expiryDate!.year.toString().padLeft(4, '0')}-${input.expiryDate!.month.toString().padLeft(2, '0')}-${input.expiryDate!.day.toString().padLeft(2, '0')}',
      if (input.uploadedBy != null && input.uploadedBy!.trim().isNotEmpty)
        'uploaded_by': input.uploadedBy!.trim(),
    };

    try {
      final response = await apiClient.post(
        '/hr/employees/$sanitizedEmpId/documents',
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
        throw const FormatException('Expected JSON map in document upload response.');
      }

      return EmployeeDocumentDto.fromJson(rawMap).toDomain();
    } on NetworkException catch (e) {
      throw _mapNetworkException(
        e,
        operation: 'uploading document "${input.title}" for employee "$sanitizedEmpId"',
      );
    } catch (e) {
      throw EmployeeDocumentException(
        'Failed to upload document: $e',
        code: 'upload_error',
      );
    }
  }

  @override
  Future<Uint8List> downloadDocumentFile(String documentId) async {
    final sanitizedDocId = documentId.trim();
    if (sanitizedDocId.isEmpty) {
      throw const EmployeeDocumentException(
        'Document ID cannot be empty.',
        code: 'invalid_id',
      );
    }

    try {
      final response = await apiClient.get('/hr/documents/$sanitizedDocId/download');

      if (response == null) {
        throw const EmployeeDocumentException(
          'Document file is empty or unavailable.',
          code: 'empty_file',
        );
      }

      if (response is Map<String, dynamic>) {
        final base64Content = response['file_content_base64'] ?? response['data'];
        if (base64Content is String && base64Content.isNotEmpty) {
          return base64Decode(base64Content);
        }
      } else if (response is String) {
        try {
          return base64Decode(response);
        } catch (_) {
          return Uint8List.fromList(utf8.encode(response));
        }
      } else if (response is List<int>) {
        return Uint8List.fromList(response);
      }

      throw const EmployeeDocumentException(
        'Received unexpected response format for document download.',
        code: 'invalid_format',
      );
    } on NotFoundException {
      throw const EmployeeDocumentException(
        'Document file not found on backend server.',
        code: 'not_found',
      );
    } on NetworkException catch (e) {
      throw _mapNetworkException(
        e,
        operation: 'downloading document "$sanitizedDocId"',
      );
    } catch (e) {
      throw EmployeeDocumentException(
        'Failed to download document: $e',
        code: 'download_error',
      );
    }
  }

  /// Maps typed [NetworkException] to user-facing domain [EmployeeDocumentException].
  EmployeeDocumentException _mapNetworkException(
    NetworkException e, {
    required String operation,
  }) {
    if (e is UnauthorizedException) {
      return const EmployeeDocumentException(
        'Unauthorized: Session has expired or is invalid. Please log in again.',
        code: 'unauthorized',
      );
    }
    if (e is ForbiddenException) {
      return const EmployeeDocumentException(
        'Access denied: You do not have permission to access employee documents.',
        code: 'forbidden',
      );
    }
    if (e is NotFoundException) {
      return EmployeeDocumentException(
        'Document resource not found while $operation.',
        code: 'not_found',
      );
    }
    if (e is ConflictException) {
      return EmployeeDocumentException(
        'Conflict detected while $operation: document already exists.',
        code: 'conflict',
      );
    }
    if (e is NetworkTimeoutException) {
      return EmployeeDocumentException(
        'Network timeout while $operation. Please try again.',
        code: 'timeout',
      );
    }
    if (e is ConnectionException) {
      return EmployeeDocumentException(
        'Connection failure while $operation. Check your internet connection.',
        code: 'connection_error',
      );
    }
    if (e is ServerException) {
      return EmployeeDocumentException(
        'Backend server error (${e.statusCode}) while $operation. Please try again later.',
        code: 'server_error',
      );
    }
    if (e is ValidationException) {
      return EmployeeDocumentException(
        'Validation error: ${e.message}',
        code: 'validation_error',
      );
    }
    if (e is InvalidResponseException) {
      return const EmployeeDocumentException(
        'Received invalid response format from backend server.',
        code: 'invalid_response',
      );
    }
    return EmployeeDocumentException(e.message, code: 'network_error');
  }
}
