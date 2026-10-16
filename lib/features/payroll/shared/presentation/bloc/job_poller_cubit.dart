import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/failures/failure.dart';
import '../../domain/job.dart';
import '../../domain/job_repository.dart';
import 'job_poller_state.dart';

class JobPollerCubit extends Cubit<JobPollerState> {
  final PayrollJobRepository _repository;
  final Duration baseInterval;
  int _generation = 0;

  JobPollerCubit({
    required PayrollJobRepository repository,
    this.baseInterval = const Duration(seconds: 2),
  }) : _repository = repository,
       super(const JobPollerInitial());

  Future<void> start(String jobId) async {
    final generation = ++_generation;
    var failures = 0;
    PayrollJob? lastJob;
    while (!isClosed && generation == _generation) {
      final result = await _repository.getJob(jobId);
      var shouldContinue = true;
      result.fold(
        success: (job) {
          failures = 0;
          lastJob = job;
          if (job.isTerminal) {
            shouldContinue = false;
            if (job.status == PayrollJobStatus.completed) {
              emit(JobPollerCompleted(job));
            } else {
              emit(
                JobPollerFailure(
                  const UnknownFailure('The background job did not complete.'),
                  lastJob: job,
                ),
              );
            }
          } else {
            emit(JobPollerPolling(job));
          }
        },
        failure: (failure) {
          failures++;
          if (failures >= 4) {
            shouldContinue = false;
            emit(JobPollerFailure(failure, lastJob: lastJob));
          } else if (lastJob != null) {
            emit(JobPollerPolling(lastJob!, consecutiveFailures: failures));
          }
        },
      );
      if (!shouldContinue || isClosed || generation != _generation) return;
      final multiplier = failures == 0 ? 1 : 1 << failures.clamp(0, 3);
      await Future<void>.delayed(baseInterval * multiplier);
    }
  }

  void cancel() {
    _generation++;
    emit(const JobPollerInitial());
  }

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
