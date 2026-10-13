import '../../domain/job.dart';

class PayrollJobDto {
  final String id;
  final String status;
  final int completed;
  final int total;
  final String? resultId;
  final String? message;

  const PayrollJobDto({
    required this.id,
    required this.status,
    required this.completed,
    required this.total,
    this.resultId,
    this.message,
  });

  factory PayrollJobDto.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid job response.');
    return PayrollJobDto(
      id: json['jobId'] as String,
      status: json['status'] as String,
      completed: json['completed'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      resultId: json['resultId'] as String?,
      message: json['message'] as String?,
    );
  }

  PayrollJob toDomain() => PayrollJob(
    id: id,
    status: switch (status.toLowerCase()) {
      'queued' => PayrollJobStatus.queued,
      'running' => PayrollJobStatus.running,
      'completed' => PayrollJobStatus.completed,
      'failed' => PayrollJobStatus.failed,
      'cancelled' => PayrollJobStatus.cancelled,
      _ => throw FormatException('Unknown job status: $status'),
    },
    completed: completed,
    total: total,
    resultId: resultId,
    message: message,
  );
}
