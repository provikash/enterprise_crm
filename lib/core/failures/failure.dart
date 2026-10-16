/// Typed, user-safe failures shared by API-backed features.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Check your connection and try again.',
  ]);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'You do not have permission to perform this action.',
  ]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item was not found.']);
}

final class ConflictFailure extends Failure {
  final String? currentVersion;
  const ConflictFailure(super.message, {this.currentVersion});
}

final class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

final class RateLimitedFailure extends Failure {
  final Duration? retryAfter;
  const RateLimitedFailure(super.message, {this.retryAfter});
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'The server could not complete the request.',
  ]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  });
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  R fold<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => success(value);
}

final class Failed<T> extends Result<T> {
  final Failure error;
  const Failed(this.error);

  @override
  R fold<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => failure(error);
}
