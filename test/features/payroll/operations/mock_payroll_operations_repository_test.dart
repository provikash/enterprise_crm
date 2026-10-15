import 'package:enterprise_crm/features/payroll/operations/data/mock_payroll_operations_repository.dart';
import 'package:enterprise_crm/features/payroll/operations/domain/payroll_operations.dart';
import 'package:enterprise_crm/features/payroll/shared/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockPayrollOperationsRepository repository;

  setUp(() {
    repository = MockPayrollOperationsRepository(latency: Duration.zero);
  });

  test(
    'calculates gross, deductions, tax and net from compensation and inputs',
    () async {
      final run = await repository.createRun('October 2026', 'maker');
      final calculated = await repository.calculateRun(run.id, 'maker');

      expect(calculated.status, PayRunStatus.calculated);
      expect(calculated.lines, hasLength(3));
      final first = calculated.lines.firstWhere(
        (line) => line.employeeId == 'EMP-001',
      );
      expect(first.gross, const Money(10500000));
      expect(first.deductions, const Money(350000));
      expect(first.tax, const Money(50000));
      expect(first.net, const Money(10100000));
    },
  );

  test('prevents duplicate pay periods', () async {
    await repository.createRun('October 2026', 'maker');
    expect(
      () => repository.createRun('october 2026', 'maker'),
      throwsA(isA<PayrollOperationException>()),
    );
  });

  test('enforces maker-checker approval', () async {
    final run = await repository.createRun('October 2026', 'maker');
    await repository.calculateRun(run.id, 'maker');
    await repository.submitRun(run.id, 'maker');

    expect(
      () => repository.approveRun(run.id, 'maker'),
      throwsA(
        isA<PayrollOperationException>().having(
          (error) => error.message,
          'message',
          contains('cannot approve'),
        ),
      ),
    );
    final approved = await repository.approveRun(run.id, 'checker');
    expect(approved.status, PayRunStatus.approved);
  });

  test('locking creates payslips and payment release marks run paid', () async {
    var snapshot = await repository.load();
    final seeded = snapshot.runs.single;
    await repository.approveRun(seeded.id, 'checker');
    await repository.lockRun(seeded.id, 'checker');

    snapshot = await repository.load();
    expect(snapshot.payslips, hasLength(3));
    expect(snapshot.payments, hasLength(1));
    expect(snapshot.payments.single.status, PaymentBatchStatus.pendingApproval);

    await repository.releasePayment(snapshot.payments.single.id, 'treasury');
    snapshot = await repository.load();
    expect(snapshot.payments.single.status, PaymentBatchStatus.released);
    expect(snapshot.runs.single.status, PayRunStatus.paid);
  });

  test('prevents the pay run preparer from releasing payment', () async {
    final run = await repository.createRun('October 2026', 'maker');
    await repository.calculateRun(run.id, 'maker');
    await repository.submitRun(run.id, 'maker');
    await repository.approveRun(run.id, 'checker');
    await repository.lockRun(run.id, 'checker');
    final snapshot = await repository.load();
    final payment = snapshot.payments.firstWhere(
      (batch) => batch.runId == run.id,
    );

    expect(
      () => repository.releasePayment(payment.id, 'maker'),
      throwsA(
        isA<PayrollOperationException>().having(
          (error) => error.message,
          'message',
          contains('cannot release'),
        ),
      ),
    );
  });

  test(
    'employee hold excludes that employee from future calculations',
    () async {
      await repository.setPayrollHold('EMP-002', true);
      final run = await repository.createRun('October 2026', 'maker');
      final calculated = await repository.calculateRun(run.id, 'maker');
      expect(calculated.lines, hasLength(2));
      expect(
        calculated.lines.any((line) => line.employeeId == 'EMP-002'),
        isFalse,
      );
    },
  );
}
