class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  @override
  String toString() => '$runtimeType: $message (status: $statusCode, code: $code)';
}

/// Thrown when a network connection cannot be established or host cannot be resolved.
class ConnectionException extends NetworkException {
  const ConnectionException({
    super.message = 'Unable to connect to the server. Please check your network connection.',
    super.statusCode,
    super.code = 'CONNECTION_FAILURE',
    super.details,
  });
}

/// Thrown when a network request exceeds the configured connect or receive timeout.
class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException({
    super.message = 'The request timed out. Please try again later.',
    super.statusCode = 408,
    super.code = 'TIMEOUT',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 401 Unauthorized (session expired or invalid credentials).
class UnauthorizedException extends NetworkException {
  const UnauthorizedException({
    super.message = 'Your session has expired or you are not authenticated. Please log in again.',
    super.statusCode = 401,
    super.code = 'UNAUTHORIZED',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 403 Forbidden (insufficient module permissions).
class ForbiddenException extends NetworkException {
  const ForbiddenException({
    super.message = 'You do not have permission to access this resource.',
    super.statusCode = 403,
    super.code = 'FORBIDDEN',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 404 Not Found.
class NotFoundException extends NetworkException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
    super.code = 'NOT_FOUND',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 400 or 422 with input validation errors.
class ValidationException extends NetworkException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 409 Conflict (e.g. concurrent approval decision conflict).
class ConflictException extends NetworkException {
  const ConflictException({
    super.message = 'A conflict occurred with the current state of the resource.',
    super.statusCode = 409,
    super.code = 'CONFLICT',
    super.details,
  });
}

/// Thrown when an endpoint returns HTTP 500..599 server error.
class ServerException extends NetworkException {
  const ServerException({
    super.message = 'A server error occurred. Please contact system administrator.',
    super.statusCode = 500,
    super.code = 'SERVER_ERROR',
    super.details,
  });
}

/// Thrown when response parsing fails or the server returns an unexpected content type.
class InvalidResponseException extends NetworkException {
  const InvalidResponseException({
    super.message = 'Received an invalid or malformed response from the server.',
    super.statusCode,
    super.code = 'INVALID_RESPONSE',
    super.details,
  });
}
