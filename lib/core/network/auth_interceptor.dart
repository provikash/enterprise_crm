import 'package:dio/dio.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef RefreshAccessToken = Future<String?> Function();

class AuthInterceptor extends Interceptor {
  final AccessTokenProvider accessTokenProvider;
  final RefreshAccessToken? refreshAccessToken;
  final Dio retryClient;
  Future<String?>? _refreshing;

  AuthInterceptor({
    required this.accessTokenProvider,
    required this.retryClient,
    this.refreshAccessToken,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await accessTokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        refreshAccessToken == null ||
        request.extra['authRetried'] == true) {
      handler.next(err);
      return;
    }

    try {
      _refreshing ??= refreshAccessToken!();
      final token = await _refreshing;
      _refreshing = null;
      if (token == null || token.isEmpty) {
        handler.next(err);
        return;
      }
      request.extra['authRetried'] = true;
      request.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await retryClient.fetch<Object?>(request));
    } catch (_) {
      _refreshing = null;
      handler.next(err);
    }
  }
}
