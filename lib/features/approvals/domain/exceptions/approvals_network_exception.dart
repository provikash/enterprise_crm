/// Typed network exception for errors encountered during remote approvals API requests.
class ApprovalsNetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApprovalsNetworkException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'ApprovalsNetworkException(statusCode: $statusCode, message: $message)';
}
