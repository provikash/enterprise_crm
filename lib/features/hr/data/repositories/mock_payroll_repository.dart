import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../mock/mock_payroll_store.dart';

/// Mock implementation of [PayrollRepository] backed by [MockPayrollStore].
///
/// Follows project architecture and patterns from [MockEmployeeRepository],
/// [MockAttendanceRepository], and [MockEmployeeKpiRepository].
class MockPayrollRepository implements PayrollRepository {
  final MockPayrollStore _store;

  MockPayrollRepository({MockPayrollStore? store})
      : _store = store ?? MockPayrollStore();

  /// Access to underlying mock store for testing and resets.
  MockPayrollStore get store => _store;

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async {
    return _store.getPayrollPeriods();
  }

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async {
    return _store.getPayrollPeriodById(id);
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) async {
    return _store.getPayrollRecords(
      payrollPeriodId: payrollPeriodId,
      employeeId: employeeId,
    );
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async {
    return _store.getPayrollRecordsForPeriod(periodId);
  }

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(
    String employeeId,
  ) async {
    return _store.getPayrollRecordsForEmployee(employeeId);
  }

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async {
    return _store.getPayrollRecordById(id);
  }
}
