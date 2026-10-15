import 'package:dio/dio.dart';

import '../failures/failure.dart';
import 'api_error_mapper.dart';
import 'auth_interceptor.dart';
import 'idempotency_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient({
    required Uri baseUri,
    required AccessTokenProvider accessTokenProvider,
    RefreshAccessToken? refreshAccessToken,
  }) {
    final retryClient = Dio(BaseOptions(baseUrl: baseUri.toString()));
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUri.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      AuthInterceptor(
        accessTokenProvider: accessTokenProvider,
        refreshAccessToken: refreshAccessToken,
        retryClient: retryClient,
      ),
      IdempotencyInterceptor(),
    ]);
    return ApiClient._(dio);
  }

  Future<Result<T>> request<T>(
    Future<Response<Object?>> Function() operation,
    T Function(Object? json) decode,
  ) async {
    try {
      final response = await operation();
      final body = response.data;
      final payload = body is Map && body.containsKey('data')
          ? body['data']
          : body;
      return Success(decode(payload));
    } on DioException catch (error) {
      return Failed(ApiErrorMapper.fromDioException(error));
    } catch (_) {
      return const Failed(UnknownFailure());
    }
  }
}
