import 'package:dio/dio.dart';

import '../security/auth_token_vault.dart';

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

  /// Factory providing direct integration with [AuthTokenVault] for hardware-backed credentials.
  factory AuthInterceptor.fromVault({
    required AuthTokenVault vault,
    required Dio retryClient,
    RefreshAccessToken? refreshAccessToken,
  }) {
    return AuthInterceptor(
      accessTokenProvider: vault.getAccessToken,
      retryClient: retryClient,
      refreshAccessToken: refreshAccessToken ?? vault.getRefreshToken,
    );
  }

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
