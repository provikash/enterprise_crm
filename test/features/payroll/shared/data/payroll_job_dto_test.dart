import 'package:enterprise_crm/features/payroll/shared/data/dto/payroll_job_dto.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the job API fixture to a domain job', () {
    final dto = PayrollJobDto.fromJson({
      'jobId': 'job-1',
      'status': 'running',
      'completed': 340,
      'total': 1200,
      'message': 'Calculating',
    });
    final job = dto.toDomain();
    expect(job.id, 'job-1');
    expect(job.status, PayrollJobStatus.running);
    expect(job.completed, 340);
    expect(job.total, 1200);
  });

  test('rejects unknown statuses', () {
    final dto = PayrollJobDto.fromJson({
      'jobId': 'job-1',
      'status': 'mystery',
      'completed': 0,
      'total': 1,
    });
    expect(dto.toDomain, throwsFormatException);
  });
}
