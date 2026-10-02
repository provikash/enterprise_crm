import 'dart:async';
import 'dart:convert';
import 'api_transport.dart';
import 'backend_config.dart';
import 'network_exception.dart';

/// Function interface for dynamically retrieving the active user session or JWT token.
typedef AuthTokenProvider = FutureOr<String?> Function();

/// High-level client for communicating with the CRM backend REST API.
///
/// Features (HR-10.2):
/// - Strong typing: translates raw transport responses into parsed JSON or throws typed [NetworkException]s.
/// - Dynamic authentication: automatically injects `Authorization: Bearer <token>` if a token is provided.
/// - Controlled idempotency: allows retries only on safe, read-only `GET` requests; mutating operations are never retried.
/// - Privacy-safe error reporting: strips internal stack traces and server credentials from user diagnostics.
/// - Zero platform dependence: operates via abstract [ApiTransport], making it 100% compatible with Android, Web, and desktop.
class ApiClient {
  final BackendConfig _config;
  final ApiTransport _transport;
  final AuthTokenProvider? _authTokenProvider;

  ApiClient({
    required BackendConfig config,
    required ApiTransport transport,
    AuthTokenProvider? authTokenProvider,
  })  : _config = config,
        _transport = transport,
        _authTokenProvider = authTokenProvider;

  /// Active backend configuration.
  BackendConfig get config => _config;

  /// Underlying network transport.
  ApiTransport get transport => _transport;

  /// Sends a `GET` request to [path].
  ///
  /// [queryParams] are appended to the resolved URI.
  /// [maxRetries] can be specified for idempotent transient failure recovery (capped at 3).
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = 0,
  }) async {
    final effectiveRetries = maxRetries.clamp(0, 3);
    var attempts = 0;

    while (true) {
      attempts++;
      try {
        return await _sendRequest(
          method: HttpMethod.get,
          path: path,
          queryParams: queryParams,
          headers: headers,
          timeout: timeout,
        );
      } on NetworkException catch (e) {
        final isTransient = e is ConnectionException ||
            e is NetworkTimeoutException ||
            (e is ServerException && (e.statusCode == 503 || e.statusCode == 504));

        if (isTransient && attempts <= effectiveRetries) {
          await Future<void>.delayed(Duration(milliseconds: 100 * attempts));
          continue;
        }
        rethrow;
      }
    }
  }

  /// Sends a `POST` request with optional [body] to [path].
  ///
  /// Strictly non-idempotent: never retried automatically.
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _sendRequest(
      method: HttpMethod.post,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a `PUT` request with [body] to [path].
  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _sendRequest(
      method: HttpMethod.put,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a `PATCH` request with partial [body] to [path].
  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _sendRequest(
      method: HttpMethod.patch,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
    );
  }

  /// Sends a `DELETE` request to [path].
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    return _sendRequest(
      method: HttpMethod.delete,
      path: path,
      headers: headers,
      timeout: timeout,
    );
  }

  Future<dynamic> _sendRequest({
    required HttpMethod method,
    required String path,
    Map<String, String>? queryParams,
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    // 1. Resolve URI
    var uri = _config.resolveUrl(path);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      });
    }

    // 2. Prepare headers
    final mergedHeaders = <String, String>{
      'accept': 'application/json',
      ...?headers,
    };

    // 3. Attach authentication credentials if available
    final tokenProvider = _authTokenProvider;
    if (tokenProvider != null) {
      final token = await tokenProvider();
      if (token != null && token.trim().isNotEmpty) {
        mergedHeaders['authorization'] = 'Bearer ${token.trim()}';
      }
    }

    // 4. Encode request body
    String? serializedBody;
    if (body != null) {
      mergedHeaders['content-type'] = 'application/json; charset=utf-8';
      try {
        serializedBody = jsonEncode(body);
      } catch (e) {
        throw ValidationException(
          message: 'Failed to serialize request payload to JSON: $e',
        );
      }
    }

    // 5. Construct transport request
    final request = TransportRequest(
      method: method,
      uri: uri,
      headers: mergedHeaders,
      body: serializedBody,
      timeout: timeout ?? _config.receiveTimeout,
    );

    // 6. Execute over transport
    final response = await _transport.send(request);

    // 7. Parse response and enforce HTTP status contracts
    return _handleResponse(response, method: method, uri: uri);
  }

  dynamic _handleResponse(
    TransportResponse response, {
    required HttpMethod method,
    required Uri uri,
  }) {
    final status = response.statusCode;
    final body = response.body.trim();

    // Check for success (2xx)
    if (response.isSuccess) {
      if (body.isEmpty || status == 204) {
        return null;
      }
      try {
        return jsonDecode(body);
      } catch (e) {
        throw InvalidResponseException(
          message: 'Server returned HTTP $status but the response body was not valid JSON.',
          statusCode: status,
        );
      }
    }

    // Parse error payload if available
    String? errorMessage;
    String? errorCode;
    Map<String, dynamic>? errorDetails;

    if (body.isNotEmpty) {
      try {
        final parsed = jsonDecode(body);
        if (parsed is Map<String, dynamic>) {
          if (parsed['error'] is Map<String, dynamic>) {
            final err = parsed['error'] as Map<String, dynamic>;
            errorMessage = err['message']?.toString();
            errorCode = err['code']?.toString();
            if (err['details'] is Map<String, dynamic>) {
              errorDetails = err['details'] as Map<String, dynamic>;
            }
          } else if (parsed['message'] != null) {
            errorMessage = parsed['message']?.toString();
            errorCode = parsed['code']?.toString();
          }
        }
      } catch (_) {
        // Fall back to status-based message if error body is not JSON
      }
    }

    // Map to typed exceptions
    switch (status) {
      case 400:
      case 422:
        throw ValidationException(
          message: errorMessage ?? 'Invalid request parameters.',
          statusCode: status,
          code: errorCode ?? 'VALIDATION_ERROR',
          details: errorDetails,
        );
      case 401:
        throw UnauthorizedException(
          message: errorMessage ?? 'Authentication session expired or invalid.',
          statusCode: 401,
          code: errorCode ?? 'UNAUTHORIZED',
        );
      case 403:
        throw ForbiddenException(
          message: errorMessage ?? 'Access denied. You lack required permissions for this action.',
          statusCode: 403,
          code: errorCode ?? 'FORBIDDEN',
        );
      case 404:
        throw NotFoundException(
          message: errorMessage ?? 'Requested resource was not found.',
          statusCode: 404,
          code: errorCode ?? 'NOT_FOUND',
        );
      case 409:
        throw ConflictException(
          message: errorMessage ?? 'Conflict with the current state of the resource.',
          statusCode: 409,
          code: errorCode ?? 'CONFLICT',
          details: errorDetails,
        );
      case >= 500 && < 600:
        throw ServerException(
          message: errorMessage ?? 'Server error occurred ($status).',
          statusCode: status,
          code: errorCode ?? 'SERVER_ERROR',
        );
      default:
        throw NetworkException(
          message: errorMessage ?? 'Unexpected HTTP status code: $status',
          statusCode: status,
          code: errorCode ?? 'UNEXPECTED_STATUS',
        );
    }
  }
}
