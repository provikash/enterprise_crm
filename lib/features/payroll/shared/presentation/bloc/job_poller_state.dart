import '../../../../../core/failures/failure.dart';
import '../../domain/job.dart';

sealed class JobPollerState {
  const JobPollerState();
}

final class JobPollerInitial extends JobPollerState {
  const JobPollerInitial();
}

final class JobPollerPolling extends JobPollerState {
  final PayrollJob job;
  final int consecutiveFailures;
  const JobPollerPolling(this.job, {this.consecutiveFailures = 0});
}

final class JobPollerCompleted extends JobPollerState {
  final PayrollJob job;
  const JobPollerCompleted(this.job);
}

final class JobPollerFailure extends JobPollerState {
  final Failure failure;
  final PayrollJob? lastJob;
  const JobPollerFailure(this.failure, {this.lastJob});
}
