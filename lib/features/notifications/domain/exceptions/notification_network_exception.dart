/// Typed network exception for errors encountered during remote notification API requests.
class NotificationNetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const NotificationNetworkException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'NotificationNetworkException(statusCode: $statusCode, message: $message)';
}
