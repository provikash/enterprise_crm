import '../../../../core/failures/failure.dart';
import 'job.dart';

abstract interface class PayrollJobRepository {
  Future<Result<PayrollJob>> getJob(String jobId);
}
