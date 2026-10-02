/// HTTP methods supported by the CRM API transport.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete;

  String get verb => name.toUpperCase();
}

/// Normalized, transport-level HTTP request representation.
class TransportRequest {
  final HttpMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
  final Duration? timeout;

  const TransportRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
    this.timeout,
  });

  TransportRequest copyWith({
    HttpMethod? method,
    Uri? uri,
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
  }) {
    return TransportRequest(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  String toString() => 'TransportRequest(${method.verb} $uri, headers: ${headers.keys})';
}

/// Normalized, transport-level HTTP response representation.
class TransportResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  const TransportResponse({
    required this.statusCode,
    this.headers = const {},
    required this.body,
  });

  /// Returns `true` if the status code is in the 2xx success range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() => 'TransportResponse(status: $statusCode, length: ${body.length})';
}

/// Abstract contract for low-level HTTP network transport.
///
/// Decouples higher-level API clients and repository adapters from platform networking
/// libraries (`http`, `dio`, `HttpClient`) and enables deterministic test injection.
abstract interface class ApiTransport {
  /// Sends [request] over the network transport and returns the raw [TransportResponse].
  ///
  /// Throws [NetworkException] if connection, timeout, or low-level transport errors occur.
  Future<TransportResponse> send(TransportRequest request);
}
