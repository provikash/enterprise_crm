import '../../shared/domain/money.dart';

enum PayrollInputKind {
  bonus('Bonus', true),
  overtime('Overtime', true),
  reimbursement('Reimbursement', true),
  deduction('Deduction', false);

  final String label;
  final bool earning;
  const PayrollInputKind(this.label, this.earning);
}

enum PayRunStatus {
  draft('Draft'),
  calculated('Calculated'),
  underReview('Under review'),
  approved('Approved'),
  locked('Locked'),
  paid('Paid');

  final String label;
  const PayRunStatus(this.label);
}

enum PaymentBatchStatus {
  pendingApproval('Pending approval'),
  released('Released');

  final String label;
  const PaymentBatchStatus(this.label);
}

class EmployeeCompensation {
  final String employeeId;
  final String employeeName;
  final String department;
  final Money basicSalary;
  final Money fixedAllowance;
  final Money fixedDeduction;
  final String maskedBankAccount;
  final bool onHold;

  const EmployeeCompensation({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.basicSalary,
    required this.fixedAllowance,
    required this.fixedDeduction,
    required this.maskedBankAccount,
    this.onHold = false,
  });

  EmployeeCompensation copyWith({
    Money? basicSalary,
    Money? fixedAllowance,
    Money? fixedDeduction,
    bool? onHold,
  }) => EmployeeCompensation(
    employeeId: employeeId,
    employeeName: employeeName,
    department: department,
    basicSalary: basicSalary ?? this.basicSalary,
    fixedAllowance: fixedAllowance ?? this.fixedAllowance,
    fixedDeduction: fixedDeduction ?? this.fixedDeduction,
    maskedBankAccount: maskedBankAccount,
    onHold: onHold ?? this.onHold,
  );
}

class PayrollInput {
  final String id;
  final String employeeId;
  final PayrollInputKind kind;
  final Money amount;
  final String note;

  const PayrollInput({
    required this.id,
    required this.employeeId,
    required this.kind,
    required this.amount,
    required this.note,
  });
}

class PayrollLine {
  final String employeeId;
  final String employeeName;
  final Money gross;
  final Money deductions;
  final Money tax;
  final Money net;

  const PayrollLine({
    required this.employeeId,
    required this.employeeName,
    required this.gross,
    required this.deductions,
    required this.tax,
    required this.net,
  });
}

class PayRun {
  final String id;
  final String periodLabel;
  final PayRunStatus status;
  final String preparedBy;
  final List<PayrollLine> lines;
  final DateTime createdAt;
  final List<String> auditTrail;

  const PayRun({
    required this.id,
    required this.periodLabel,
    required this.status,
    required this.preparedBy,
    required this.lines,
    required this.createdAt,
    this.auditTrail = const [],
  });

  Money get gross =>
      Money(lines.fold<int>(0, (sum, line) => sum + line.gross.paise));
  Money get deductions =>
      Money(lines.fold<int>(0, (sum, line) => sum + line.deductions.paise));
  Money get tax =>
      Money(lines.fold<int>(0, (sum, line) => sum + line.tax.paise));
  Money get net =>
      Money(lines.fold<int>(0, (sum, line) => sum + line.net.paise));

  PayRun copyWith({
    PayRunStatus? status,
    List<PayrollLine>? lines,
    String? audit,
  }) => PayRun(
    id: id,
    periodLabel: periodLabel,
    status: status ?? this.status,
    preparedBy: preparedBy,
    lines: lines ?? this.lines,
    createdAt: createdAt,
    auditTrail: [...auditTrail, ?audit],
  );
}

class Payslip {
  final String id;
  final String runId;
  final String periodLabel;
  final PayrollLine line;
  final DateTime generatedAt;

  const Payslip({
    required this.id,
    required this.runId,
    required this.periodLabel,
    required this.line,
    required this.generatedAt,
  });
}

class PaymentBatch {
  final String id;
  final String runId;
  final String periodLabel;
  final int employeeCount;
  final Money amount;
  final PaymentBatchStatus status;
  final String? reference;

  const PaymentBatch({
    required this.id,
    required this.runId,
    required this.periodLabel,
    required this.employeeCount,
    required this.amount,
    required this.status,
    this.reference,
  });

  PaymentBatch released(String paymentReference) => PaymentBatch(
    id: id,
    runId: runId,
    periodLabel: periodLabel,
    employeeCount: employeeCount,
    amount: amount,
    status: PaymentBatchStatus.released,
    reference: paymentReference,
  );
}

class PayrollOperationsSnapshot {
  final List<EmployeeCompensation> employees;
  final List<PayrollInput> inputs;
  final List<PayRun> runs;
  final List<Payslip> payslips;
  final List<PaymentBatch> payments;

  const PayrollOperationsSnapshot({
    required this.employees,
    required this.inputs,
    required this.runs,
    required this.payslips,
    required this.payments,
  });
}
