import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/job_poller_cubit.dart';
import '../bloc/job_poller_state.dart';

class JobProgressPanel extends StatelessWidget {
  final VoidCallback? onRetry;
  const JobProgressPanel({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<JobPollerCubit, JobPollerState>(
        builder: (context, state) => switch (state) {
          JobPollerInitial() => const SizedBox.shrink(),
          JobPollerPolling(:final job, :final consecutiveFailures) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(job.message ?? 'Processing…'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: job.progress),
                  const SizedBox(height: 4),
                  Text(
                    job.total > 0
                        ? '${job.completed}/${job.total}'
                        : 'Waiting for progress',
                  ),
                  if (consecutiveFailures > 0)
                    const Text(
                      'Connection interrupted; retrying automatically.',
                    ),
                ],
              ),
            ),
          ),
          JobPollerCompleted(:final job) => ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Completed'),
            subtitle: Text(job.message ?? 'The background job completed.'),
          ),
          JobPollerFailure(:final failure) => ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Job failed'),
            subtitle: Text(failure.message),
            trailing: onRetry == null
                ? null
                : TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        },
      );
}
