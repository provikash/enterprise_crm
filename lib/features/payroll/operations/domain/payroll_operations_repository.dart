import 'payroll_operations.dart';
import '../../shared/domain/money.dart';

abstract interface class PayrollOperationsRepository {
  Future<PayrollOperationsSnapshot> load();

  Future<void> updateCompensation({
    required String employeeId,
    required Money basicSalary,
    required Money fixedAllowance,
    required Money fixedDeduction,
  });

  Future<void> setPayrollHold(String employeeId, bool value);

  Future<void> addInput({
    required String employeeId,
    required PayrollInputKind kind,
    required Money amount,
    required String note,
  });

  Future<void> deleteInput(String inputId);
  Future<PayRun> createRun(String periodLabel, String preparedBy);
  Future<PayRun> calculateRun(String runId, String actor);
  Future<PayRun> submitRun(String runId, String actor);
  Future<PayRun> approveRun(String runId, String actor);
  Future<PayRun> lockRun(String runId, String actor);
  Future<PaymentBatch> releasePayment(String batchId, String actor);
}
