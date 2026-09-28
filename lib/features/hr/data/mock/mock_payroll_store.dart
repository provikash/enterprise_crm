import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/repositories/payroll_repository.dart';

/// In-memory thread-safe mock store for HR Payroll periods and records.
///
/// Follows HR-6 architectural constraints:
/// - Deterministic initial seed data across stable employee identifiers (`emp_1`, `emp_2`, `emp_3`).
/// - Full copy isolation so reads/mutations in tests or runtime do not leak.
/// - Normalized calendar dates (UTC midnight).
/// - No dependency on [DateTime.now] for seed data.
/// - No client-side salary arithmetic or statutory deduction logic.
class MockPayrollStore {
  final Map<String, PayrollPeriod> _periods = {};
  final Map<String, PayrollRecord> _records = {};
  bool _shouldThrow = false;

  MockPayrollStore({bool seedInitialData = true}) {
    if (seedInitialData) {
      _seed();
    }
  }

  void _seed() {
    // Seed periods
    final seedPeriods = [
      PayrollPeriod(
        id: 'period_2026_01',
        name: 'January 2026',
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 1, 31),
        paymentDate: DateTime.utc(2026, 2, 1),
        createdAt: DateTime.utc(2026, 1, 1, 9, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 17, 0),
      ),
      PayrollPeriod(
        id: 'period_2026_02',
        name: 'February 2026',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 2, 28),
        paymentDate: DateTime.utc(2026, 3, 1),
        createdAt: DateTime.utc(2026, 2, 1, 9, 0),
        updatedAt: DateTime.utc(2026, 3, 1, 17, 0),
      ),
      // Period C: Empty period for empty-state verification
      PayrollPeriod(
        id: 'period_2026_03',
        name: 'March 2026',
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 3, 31),
        paymentDate: null,
        createdAt: DateTime.utc(2026, 3, 1, 9, 0),
        updatedAt: DateTime.utc(2026, 3, 1, 9, 0),
      ),
    ];

    for (final period in seedPeriods) {
      _periods[period.id] = period;
    }

    // Seed records
    final seedRecords = [
      // Period 1 (January 2026) records
      PayrollRecord(
        id: 'pay_rec_101',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 85000.0,
        netSalary: 72000.0,
        totalAllowances: 10000.0,
        totalDeductions: 23000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 2, 1),
        remarks: 'Regular monthly disbursement',
        createdAt: DateTime.utc(2026, 2, 1, 10, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 17, 0),
      ),
      PayrollRecord(
        id: 'pay_rec_102',
        employeeId: 'emp_2',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 55000.0,
        netSalary: 47000.0,
        totalAllowances: 5000.0,
        totalDeductions: 13000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 2, 1),
        remarks: 'Regular monthly disbursement',
        createdAt: DateTime.utc(2026, 2, 1, 10, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 17, 0),
      ),
      PayrollRecord(
        id: 'pay_rec_103',
        employeeId: 'emp_3',
        payrollPeriodId: 'period_2026_01',
        grossSalary: 95000.0,
        netSalary: 80000.0,
        totalAllowances: 15000.0,
        totalDeductions: 30000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 2, 1),
        remarks: 'Regular monthly disbursement with sales incentive',
        createdAt: DateTime.utc(2026, 2, 1, 10, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 17, 0),
      ),

      // Period 2 (February 2026) records
      PayrollRecord(
        id: 'pay_rec_201',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_2026_02',
        grossSalary: 85000.0,
        netSalary: 72000.0,
        totalAllowances: 10000.0,
        totalDeductions: 23000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 3, 1),
        remarks: 'Regular monthly disbursement',
        createdAt: DateTime.utc(2026, 3, 1, 10, 0),
        updatedAt: DateTime.utc(2026, 3, 1, 17, 0),
      ),
      PayrollRecord(
        id: 'pay_rec_202',
        employeeId: 'emp_2',
        payrollPeriodId: 'period_2026_02',
        grossSalary: 55000.0,
        netSalary: 47000.0,
        totalAllowances: 5000.0,
        totalDeductions: 13000.0,
        currency: 'USD',
        paymentStatus: 'Paid',
        paymentDate: DateTime.utc(2026, 3, 1),
        remarks: 'Regular monthly disbursement',
        createdAt: DateTime.utc(2026, 3, 1, 10, 0),
        updatedAt: DateTime.utc(2026, 3, 1, 17, 0),
      ),
    ];

    for (final record in seedRecords) {
      _records[record.id] = record;
    }
  }

  /// Configures controlled simulated repository failure for testing.
  void setSimulatedFailure(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  /// Resets the store and re-seeds deterministic initial data.
  void reset() {
    _periods.clear();
    _records.clear();
    _shouldThrow = false;
    _seed();
  }

  /// Retrieves cloned payroll periods sorted chronologically descending by [startDate], then [id].
  List<PayrollPeriod> getPayrollPeriods() {
    if (_shouldThrow) {
      throw const PayrollException('Simulated repository failure retrieving payroll periods.');
    }
    final results = _periods.values.toList();
    results.sort((a, b) {
      final dateCmp = b.startDate.compareTo(a.startDate);
      if (dateCmp != 0) return dateCmp;
      return a.id.compareTo(b.id);
    });
    return results.map(_clonePeriod).toList();
  }

  /// Retrieves an individual payroll period by [id], or `null` if not found.
  PayrollPeriod? getPayrollPeriodById(String id) {
    if (_shouldThrow) {
      throw const PayrollException('Simulated repository failure retrieving payroll period.');
    }
    final period = _periods[id.trim()];
    return period != null ? _clonePeriod(period) : null;
  }

  /// Retrieves cloned payroll records with optional period and employee filtering.
  List<PayrollRecord> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) {
    if (_shouldThrow) {
      throw const PayrollException('Simulated repository failure retrieving payroll records.');
    }
    var results = _records.values.toList();

    if (payrollPeriodId != null && payrollPeriodId.trim().isNotEmpty) {
      final normalizedPeriodId = payrollPeriodId.trim();
      results = results.where((r) => r.payrollPeriodId == normalizedPeriodId).toList();
    }

    if (employeeId != null && employeeId.trim().isNotEmpty) {
      final normalizedEmployeeId = employeeId.trim();
      results = results.where((r) => r.employeeId == normalizedEmployeeId).toList();
    }

    // Sort deterministically: by payrollPeriodId descending, then employeeId ascending, then id ascending
    results.sort((a, b) {
      final periodCmp = b.payrollPeriodId.compareTo(a.payrollPeriodId);
      if (periodCmp != 0) return periodCmp;
      final empCmp = a.employeeId.compareTo(b.employeeId);
      if (empCmp != 0) return empCmp;
      return a.id.compareTo(b.id);
    });

    return results.map(_cloneRecord).toList();
  }

  /// Retrieves cloned records for an approved [periodId].
  List<PayrollRecord> getPayrollRecordsForPeriod(String periodId) {
    return getPayrollRecords(payrollPeriodId: periodId);
  }

  /// Retrieves cloned records for a specific [employeeId].
  List<PayrollRecord> getPayrollRecordsForEmployee(String employeeId) {
    return getPayrollRecords(employeeId: employeeId);
  }

  /// Retrieves an individual payroll record by [id], or `null` if not found.
  PayrollRecord? getPayrollRecordById(String id) {
    if (_shouldThrow) {
      throw const PayrollException('Simulated repository failure retrieving payroll record.');
    }
    final record = _records[id.trim()];
    return record != null ? _cloneRecord(record) : null;
  }

  PayrollPeriod _clonePeriod(PayrollPeriod p) => p.copyWith();
  PayrollRecord _cloneRecord(PayrollRecord r) => r.copyWith();
}
