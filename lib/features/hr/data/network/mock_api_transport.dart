import 'dart:async';
import 'api_transport.dart';
import 'network_exception.dart';

/// Type definition for a mock route handler.
typedef MockRequestHandler = FutureOr<TransportResponse> Function(TransportRequest request);

/// Deterministic in-memory implementation of [ApiTransport] for automated unit,
/// integration, and security testing.
///
/// Features:
/// - Exact route registration matching HTTP method and path pattern.
/// - Configurable error injection (connectivity failures, timeouts, 4xx/5xx status codes).
/// - Request history recording for verifying authentication headers, queries, and bodies.
/// - Full copy isolation and state reset for session testing.
class MockApiTransport implements ApiTransport {
  final Map<String, MockRequestHandler> _handlers = {};
  final List<TransportRequest> _recordedRequests = [];
  bool simulateConnectionFailure = false;
  Duration simulatedLatency = Duration.zero;

  MockApiTransport();

  /// Recorded history of all sent requests.
  List<TransportRequest> get recordedRequests => List.unmodifiable(_recordedRequests);

  /// Registers a deterministic [handler] for a given [method] and [path].
  void registerHandler({
    required HttpMethod method,
    required String path,
    required MockRequestHandler handler,
  }) {
    final key = _routeKey(method, path);
    _handlers[key] = handler;
  }

  /// Convenience helper to register a static JSON response for a given [method] and [path].
  void registerJson({
    required HttpMethod method,
    required String path,
    int statusCode = 200,
    required String jsonBody,
    Map<String, String> headers = const {'content-type': 'application/json'},
  }) {
    registerHandler(
      method: method,
      path: path,
      handler: (_) => TransportResponse(
        statusCode: statusCode,
        headers: headers,
        body: jsonBody,
      ),
    );
  }

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    _recordedRequests.add(request);

    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    if (simulateConnectionFailure) {
      throw const ConnectionException();
    }

    // Check request timeout against simulated latency
    if (request.timeout != null && simulatedLatency > request.timeout!) {
      throw const NetworkTimeoutException();
    }

    final key = _routeKey(request.method, request.uri.path);
    final handler = _handlers[key];

    if (handler != null) {
      return await handler(request);
    }

    // Default fallback: 404 Not Found for unregistered routes
    return TransportResponse(
      statusCode: 404,
      headers: {'content-type': 'application/json'},
      body: '{"error": {"code": "NOT_FOUND", "message": "No mock handler registered for ${request.method.verb} ${request.uri.path}"}}',
    );
  }

  /// Clears recorded requests and registered handlers for test isolation.
  void reset() {
    _handlers.clear();
    _recordedRequests.clear();
    simulateConnectionFailure = false;
    simulatedLatency = Duration.zero;
  }

  String _routeKey(HttpMethod method, String path) {
    var normalizedPath = path.trim();
    if (!normalizedPath.startsWith('/')) {
      normalizedPath = '/$normalizedPath';
    }
    return '${method.name.toUpperCase()}:$normalizedPath';
  }
}
