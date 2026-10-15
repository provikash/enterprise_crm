import 'package:dio/dio.dart';

import '../failures/failure.dart';

abstract final class ApiErrorMapper {
  static Failure fromDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      return const NetworkFailure();
    }

    final status = response.statusCode ?? 0;
    final body = response.data;
    final message = _message(body);
    return switch (status) {
      401 => UnauthorizedFailure(message ?? 'Your session has expired.'),
      403 => ForbiddenFailure(
        message ?? 'You do not have permission to perform this action.',
      ),
      404 => NotFoundFailure(message ?? 'The requested item was not found.'),
      409 => ConflictFailure(
        message ?? 'This item was updated by someone else.',
        currentVersion: _stringValue(body, 'currentVersion'),
      ),
      422 => ValidationFailure(
        message ?? 'Please correct the highlighted fields.',
        fieldErrors: _fieldErrors(body),
      ),
      429 => RateLimitedFailure(
        message ?? 'Too many requests. Please try again shortly.',
        retryAfter: _retryAfter(response.headers.value('retry-after')),
      ),
      >= 500 => ServerFailure(
        message ?? 'The server could not complete the request.',
      ),
      _ => UnknownFailure(message ?? 'The request could not be completed.'),
    };
  }

  static String? _message(Object? body) => _stringValue(body, 'message');

  static String? _stringValue(Object? body, String key) {
    if (body is Map && body[key] is String) return body[key] as String;
    return null;
  }

  static Map<String, List<String>> _fieldErrors(Object? body) {
    if (body is! Map || body['fieldErrors'] is! Map) return const {};
    final result = <String, List<String>>{};
    for (final entry in (body['fieldErrors'] as Map).entries) {
      final value = entry.value;
      if (value is Iterable) {
        result[entry.key.toString()] = value.map((e) => e.toString()).toList();
      }
    }
    return Map.unmodifiable(result);
  }

  static Duration? _retryAfter(String? value) {
    final seconds = int.tryParse(value ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
