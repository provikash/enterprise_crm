import '../../shared/domain/money.dart';
import '../domain/payroll_operations.dart';
import '../domain/payroll_operations_repository.dart';

class PayrollOperationException implements Exception {
  final String message;
  const PayrollOperationException(this.message);
  @override
  String toString() => message;
}

class MockPayrollOperationsRepository implements PayrollOperationsRepository {
  final Duration latency;
  final List<EmployeeCompensation> _employees;
  final List<PayrollInput> _inputs;
  final List<PayRun> _runs;
  final List<PaymentBatch> _payments;
  int _sequence = 10;

  MockPayrollOperationsRepository({
    this.latency = const Duration(milliseconds: 180),
  }) : _employees = [
         const EmployeeCompensation(
           employeeId: 'EMP-001',
           employeeName: 'Aarav Fernando',
           department: 'Sales',
           basicSalary: Money(8500000),
           fixedAllowance: Money(1500000),
           fixedDeduction: Money(350000),
           maskedBankAccount: '**** 1042',
         ),
         const EmployeeCompensation(
           employeeId: 'EMP-002',
           employeeName: 'Nimali Perera',
           department: 'Finance',
           basicSalary: Money(11000000),
           fixedAllowance: Money(2200000),
           fixedDeduction: Money(500000),
           maskedBankAccount: '**** 7718',
         ),
         const EmployeeCompensation(
           employeeId: 'EMP-003',
           employeeName: 'Kavindu Silva',
           department: 'Operations',
           basicSalary: Money(7200000),
           fixedAllowance: Money(900000),
           fixedDeduction: Money(275000),
           maskedBankAccount: '**** 3390',
         ),
       ],
       _inputs = [
         const PayrollInput(
           id: 'input-1',
           employeeId: 'EMP-001',
           kind: PayrollInputKind.bonus,
           amount: Money(500000),
           note: 'Quarterly sales bonus',
         ),
         const PayrollInput(
           id: 'input-2',
           employeeId: 'EMP-003',
           kind: PayrollInputKind.overtime,
           amount: Money(225000),
           note: 'Approved overtime',
         ),
       ],
       _runs = [],
       _payments = [] {
    final seededLines = _calculateLines();
    final run = PayRun(
      id: 'run-seeded',
      periodLabel: 'September 2026',
      status: PayRunStatus.underReview,
      preparedBy: 'payroll-maker',
      lines: seededLines,
      createdAt: DateTime(2026, 9, 25),
      auditTrail: const [
        'Created by payroll-maker',
        'Calculated by payroll-maker',
        'Submitted for review by payroll-maker',
      ],
    );
    _runs.add(run);
  }

  @override
  Future<PayrollOperationsSnapshot> load() async {
    await _delay();
    return PayrollOperationsSnapshot(
      employees: List.unmodifiable(_employees),
      inputs: List.unmodifiable(_inputs),
      runs: List.unmodifiable(_runs.reversed),
      payslips: List.unmodifiable(_buildPayslips()),
      payments: List.unmodifiable(_payments.reversed),
    );
  }

  @override
  Future<void> updateCompensation({
    required String employeeId,
    required Money basicSalary,
    required Money fixedAllowance,
    required Money fixedDeduction,
  }) async {
    await _delay();
    if (basicSalary.paise <= 0 ||
        fixedAllowance.paise < 0 ||
        fixedDeduction.paise < 0) {
      throw const PayrollOperationException(
        'Amounts must be valid and non-negative.',
      );
    }
    final index = _employeeIndex(employeeId);
    _employees[index] = _employees[index].copyWith(
      basicSalary: basicSalary,
      fixedAllowance: fixedAllowance,
      fixedDeduction: fixedDeduction,
    );
  }

  @override
  Future<void> setPayrollHold(String employeeId, bool value) async {
    await _delay();
    final index = _employeeIndex(employeeId);
    _employees[index] = _employees[index].copyWith(onHold: value);
  }

  @override
  Future<void> addInput({
    required String employeeId,
    required PayrollInputKind kind,
    required Money amount,
    required String note,
  }) async {
    await _delay();
    _employeeIndex(employeeId);
    if (amount.paise <= 0) {
      throw const PayrollOperationException(
        'Input amount must be greater than zero.',
      );
    }
    _inputs.add(
      PayrollInput(
        id: 'input-${_sequence++}',
        employeeId: employeeId,
        kind: kind,
        amount: amount,
        note: note.trim(),
      ),
    );
  }

  @override
  Future<void> deleteInput(String inputId) async {
    await _delay();
    _inputs.removeWhere((input) => input.id == inputId);
  }

  @override
  Future<PayRun> createRun(String periodLabel, String preparedBy) async {
    await _delay();
    final normalized = periodLabel.trim();
    if (normalized.isEmpty) {
      throw const PayrollOperationException('Enter a payroll period.');
    }
    if (_runs.any(
      (run) => run.periodLabel.toLowerCase() == normalized.toLowerCase(),
    )) {
      throw const PayrollOperationException(
        'A pay run already exists for this period.',
      );
    }
    final run = PayRun(
      id: 'run-${_sequence++}',
      periodLabel: normalized,
      status: PayRunStatus.draft,
      preparedBy: preparedBy,
      lines: const [],
      createdAt: DateTime.now(),
      auditTrail: ['Created by $preparedBy'],
    );
    _runs.add(run);
    return run;
  }

  @override
  Future<PayRun> calculateRun(String runId, String actor) async {
    await _delay();
    final index = _runIndex(runId);
    final run = _runs[index];
    if (run.status != PayRunStatus.draft &&
        run.status != PayRunStatus.calculated) {
      throw const PayrollOperationException(
        'Only a draft run can be calculated.',
      );
    }
    final updated = run.copyWith(
      status: PayRunStatus.calculated,
      lines: _calculateLines(),
      audit: 'Calculated by $actor',
    );
    _runs[index] = updated;
    return updated;
  }

  @override
  Future<PayRun> submitRun(String runId, String actor) async {
    await _delay();
    final index = _runIndex(runId);
    final run = _runs[index];
    if (run.status != PayRunStatus.calculated) {
      throw const PayrollOperationException('Calculate the run before review.');
    }
    return _runs[index] = run.copyWith(
      status: PayRunStatus.underReview,
      audit: 'Submitted for review by $actor',
    );
  }

  @override
  Future<PayRun> approveRun(String runId, String actor) async {
    await _delay();
    final index = _runIndex(runId);
    final run = _runs[index];
    if (run.status != PayRunStatus.underReview) {
      throw const PayrollOperationException(
        'Only a run under review can be approved.',
      );
    }
    if (run.preparedBy == actor) {
      throw const PayrollOperationException(
        'The preparer cannot approve their own pay run.',
      );
    }
    return _runs[index] = run.copyWith(
      status: PayRunStatus.approved,
      audit: 'Approved by $actor',
    );
  }

  @override
  Future<PayRun> lockRun(String runId, String actor) async {
    await _delay();
    final index = _runIndex(runId);
    final run = _runs[index];
    if (run.status != PayRunStatus.approved) {
      throw const PayrollOperationException(
        'Approve the run before locking it.',
      );
    }
    final updated = run.copyWith(
      status: PayRunStatus.locked,
      audit: 'Locked by $actor',
    );
    _runs[index] = updated;
    _payments.add(
      PaymentBatch(
        id: 'payment-${_sequence++}',
        runId: run.id,
        periodLabel: run.periodLabel,
        employeeCount: run.lines.length,
        amount: run.net,
        status: PaymentBatchStatus.pendingApproval,
      ),
    );
    return updated;
  }

  @override
  Future<PaymentBatch> releasePayment(String batchId, String actor) async {
    await _delay();
    final index = _payments.indexWhere((batch) => batch.id == batchId);
    if (index < 0) {
      throw const PayrollOperationException('Payment batch not found.');
    }
    final batch = _payments[index];
    if (batch.status == PaymentBatchStatus.released) return batch;
    final runIndex = _runIndex(batch.runId);
    if (_runs[runIndex].preparedBy == actor) {
      throw const PayrollOperationException(
        'The pay run preparer cannot release its payment batch.',
      );
    }
    final released = batch.released(
      'PAY-${DateTime.now().millisecondsSinceEpoch}-$actor',
    );
    _payments[index] = released;
    _runs[runIndex] = _runs[runIndex].copyWith(
      status: PayRunStatus.paid,
      audit: 'Payment released by $actor',
    );
    return released;
  }

  List<PayrollLine> _calculateLines() => _employees
      .where((employee) => !employee.onHold)
      .map((employee) {
        var additions = const Money.zero();
        var variableDeductions = const Money.zero();
        for (final input in _inputs.where(
          (item) => item.employeeId == employee.employeeId,
        )) {
          if (input.kind.earning) {
            additions = additions + input.amount;
          } else {
            variableDeductions = variableDeductions + input.amount;
          }
        }
        final gross =
            employee.basicSalary + employee.fixedAllowance + additions;
        // Demonstration rule only. Production tax must be supplied by the backend.
        final taxablePaise = gross.paise > 10000000
            ? gross.paise - 10000000
            : 0;
        final tax = Money((taxablePaise * 10) ~/ 100);
        final deductions = employee.fixedDeduction + variableDeductions;
        return PayrollLine(
          employeeId: employee.employeeId,
          employeeName: employee.employeeName,
          gross: gross,
          deductions: deductions,
          tax: tax,
          net: gross - deductions - tax,
        );
      })
      .toList(growable: false);

  List<Payslip> _buildPayslips() => [
    for (final run in _runs)
      if (run.status == PayRunStatus.locked || run.status == PayRunStatus.paid)
        for (final line in run.lines)
          Payslip(
            id: '${run.id}-${line.employeeId}',
            runId: run.id,
            periodLabel: run.periodLabel,
            line: line,
            generatedAt: DateTime.now(),
          ),
  ];

  int _employeeIndex(String employeeId) {
    final index = _employees.indexWhere(
      (item) => item.employeeId == employeeId,
    );
    if (index < 0) throw const PayrollOperationException('Employee not found.');
    return index;
  }

  int _runIndex(String runId) {
    final index = _runs.indexWhere((run) => run.id == runId);
    if (index < 0) throw const PayrollOperationException('Pay run not found.');
    return index;
  }

  Future<void> _delay() => Future<void>.delayed(latency);
}
