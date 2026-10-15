import '../../../../../core/failures/failure.dart';
import '../../domain/job.dart';
import '../../domain/job_repository.dart';

class MockPayrollJobRepository implements PayrollJobRepository {
  final Map<String, int> _pollCounts = {};
  final bool fail;

  MockPayrollJobRepository({this.fail = false});

  @override
  Future<Result<PayrollJob>> getJob(String jobId) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (fail) return const Failed(NetworkFailure('Simulated network failure.'));
    final count = (_pollCounts[jobId] ?? 0) + 1;
    _pollCounts[jobId] = count;
    final completed = (count * 25).clamp(0, 100);
    return Success(
      PayrollJob(
        id: jobId,
        status: completed >= 100
            ? PayrollJobStatus.completed
            : PayrollJobStatus.running,
        completed: completed,
        total: 100,
        resultId: completed >= 100 ? 'mock-result-$jobId' : null,
        message: completed >= 100 ? 'Completed' : 'Processing mock records',
      ),
    );
  }
}
