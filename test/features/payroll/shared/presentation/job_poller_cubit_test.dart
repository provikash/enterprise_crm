import 'package:enterprise_crm/core/failures/failure.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/job.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/job_repository.dart';
import 'package:enterprise_crm/features/payroll/shared/presentation/bloc/job_poller_cubit.dart';
import 'package:enterprise_crm/features/payroll/shared/presentation/bloc/job_poller_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements PayrollJobRepository {
  int calls = 0;

  @override
  Future<Result<PayrollJob>> getJob(String jobId) async {
    calls++;
    return Success(
      PayrollJob(
        id: jobId,
        status: calls == 1
            ? PayrollJobStatus.running
            : PayrollJobStatus.completed,
        completed: calls == 1 ? 1 : 2,
        total: 2,
      ),
    );
  }
}

void main() {
  test('polls until the job completes', () async {
    final repository = _Repository();
    final cubit = JobPollerCubit(
      repository: repository,
      baseInterval: Duration.zero,
    );
    await cubit.start('job-1');
    expect(repository.calls, 2);
    expect(cubit.state, isA<JobPollerCompleted>());
    await cubit.close();
  });

  test('cancel resets polling state', () async {
    final cubit = JobPollerCubit(repository: _Repository());
    cubit.cancel();
    expect(cubit.state, isA<JobPollerInitial>());
    await cubit.close();
  });
}
