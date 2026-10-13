enum PayrollJobStatus { queued, running, completed, failed, cancelled }

class PayrollJob {
  final String id;
  final PayrollJobStatus status;
  final int completed;
  final int total;
  final String? resultId;
  final String? message;

  const PayrollJob({
    required this.id,
    required this.status,
    this.completed = 0,
    this.total = 0,
    this.resultId,
    this.message,
  });

  double? get progress => total <= 0 ? null : completed / total;
  bool get isTerminal => const {
    PayrollJobStatus.completed,
    PayrollJobStatus.failed,
    PayrollJobStatus.cancelled,
  }.contains(status);
}
