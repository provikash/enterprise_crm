import 'package:dio/dio.dart';

import '../../../../../core/failures/failure.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/job.dart';
import '../../domain/job_repository.dart';
import '../dto/payroll_job_dto.dart';

class ApiPayrollJobRepository implements PayrollJobRepository {
  final ApiClient _client;
  final CancelToken _cancelToken = CancelToken();

  ApiPayrollJobRepository(this._client);

  @override
  Future<Result<PayrollJob>> getJob(String jobId) => _client.request(
    () => _client.dio.get<Object?>(
      '/api/v1/payroll/jobs/$jobId',
      cancelToken: _cancelToken,
    ),
    (json) => PayrollJobDto.fromJson(json).toDomain(),
  );

  void dispose() {
    if (!_cancelToken.isCancelled) _cancelToken.cancel('Repository disposed');
  }
}
