import 'dart:math';

import 'package:dio/dio.dart';

class IdempotencyInterceptor extends Interceptor {
  final Random _random;

  IdempotencyInterceptor({Random? random})
    : _random = random ?? Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_requiresKey(options.method) &&
        !options.headers.containsKey('Idempotency-Key')) {
      options.headers['Idempotency-Key'] = _newKey();
    }
    handler.next(options);
  }

  bool _requiresKey(String method) =>
      const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());

  String _newKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      4,
      (_) => _random.nextInt(1 << 32).toRadixString(36),
    ).join();
    return '$timestamp-$randomPart';
  }
}
