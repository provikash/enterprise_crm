import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockPayrollStore store;
  late MockPayrollRepository repository;

  setUp(() {
    store = MockPayrollStore();
    repository = MockPayrollRepository(store: store);
  });

  group('MockPayrollRepository Period Tests (HR-6.3)', () {
    test('retrieves all seeded payroll periods in deterministic descending order', () async {
      final periods = await repository.getPayrollPeriods();

      expect(periods.length, 3);
      expect(periods.map((p) => p.id).toList(), [
        'period_2026_03',
        'period_2026_02',
        'period_2026_01',
      ]);
      expect(periods[0].name, 'March 2026');
      expect(periods[1].name, 'February 2026');
      expect(periods[2].name, 'January 2026');
    });

    test('getPayrollPeriodById returns matching period when exists', () async {
      final period = await repository.getPayrollPeriodById('period_2026_01');

      expect(period, isNotNull);
      expect(period!.id, 'period_2026_01');
      expect(period.name, 'January 2026');
      expect(period.startDate, DateTime.utc(2026, 1, 1));
      expect(period.endDate, DateTime.utc(2026, 1, 31));
      expect(period.paymentDate, DateTime.utc(2026, 2, 1));
      expect(period.formattedPeriod, '2026-01-01 – 2026-01-31');
      expect(period.formattedPaymentDate, '2026-02-01');
    });

    test('getPayrollPeriodById returns null when period ID is not found', () async {
      final period = await repository.getPayrollPeriodById('period_unknown');
      expect(period, isNull);
    });

    test('getPayrollPeriodById returns null for empty or whitespace ID', () async {
      final period = await repository.getPayrollPeriodById('   ');
      expect(period, isNull);
    });

    test('supports period with null paymentDate (Period 3)', () async {
      final period = await repository.getPayrollPeriodById('period_2026_03');

      expect(period, isNotNull);
      expect(period!.paymentDate, isNull);
      expect(period.formattedPaymentDate, isNull);
    });
  });

  group('MockPayrollRepository Record Tests (HR-6.3)', () {
    test('retrieves all seeded payroll records', () async {
      final records = await repository.getPayrollRecords();

      expect(records.length, 5);
      expect(records.map((r) => r.id).toList(), [
        'pay_rec_201',
        'pay_rec_202',
        'pay_rec_101',
        'pay_rec_102',
        'pay_rec_103',
      ]);
    });

    test('getPayrollRecordById returns matching record when exists', () async {
      final record = await repository.getPayrollRecordById('pay_rec_101');

      expect(record, isNotNull);
      expect(record!.id, 'pay_rec_101');
      expect(record.employeeId, 'emp_1');
      expect(record.payrollPeriodId, 'period_2026_01');
      expect(record.grossSalary, 85000.0);
      expect(record.netSalary, 72000.0);
      expect(record.totalAllowances, 10000.0);
      expect(record.totalDeductions, 23000.0);
      expect(record.currency, 'USD');
      expect(record.paymentStatus, 'Paid');
      expect(record.paymentDate, DateTime.utc(2026, 2, 1));
      expect(record.remarks, 'Regular monthly disbursement');
    });

    test('getPayrollRecordById returns null when record ID is not found', () async {
      final record = await repository.getPayrollRecordById('pay_rec_unknown');
      expect(record, isNull);
    });

    test('getPayrollRecordById returns null for empty or whitespace ID', () async {
      final record = await repository.getPayrollRecordById('   ');
      expect(record, isNull);
    });

    test('getPayrollRecordsForPeriod returns correct records for Period 1', () async {
      final records = await repository.getPayrollRecordsForPeriod('period_2026_01');

      expect(records.length, 3);
      expect(records.every((r) => r.payrollPeriodId == 'period_2026_01'), isTrue);
      expect(records.map((r) => r.employeeId).toList(), ['emp_1', 'emp_2', 'emp_3']);
    });

    test('getPayrollRecordsForPeriod returns correct records for Period 2', () async {
      final records = await repository.getPayrollRecordsForPeriod('period_2026_02');

      expect(records.length, 2);
      expect(records.every((r) => r.payrollPeriodId == 'period_2026_02'), isTrue);
      expect(records.map((r) => r.employeeId).toList(), ['emp_1', 'emp_2']);
    });

    test('getPayrollRecordsForPeriod returns empty list for empty period (Period 3)', () async {
      final records = await repository.getPayrollRecordsForPeriod('period_2026_03');
      expect(records, isEmpty);
    });

    test('getPayrollRecordsForPeriod returns empty list for unknown period', () async {
      final records = await repository.getPayrollRecordsForPeriod('period_nonexistent');
      expect(records, isEmpty);
    });

    test('getPayrollRecords with combined period and employee filters', () async {
      final records = await repository.getPayrollRecords(
        payrollPeriodId: 'period_2026_01',
        employeeId: 'emp_2',
      );

      expect(records.length, 1);
      expect(records.first.id, 'pay_rec_102');
      expect(records.first.employeeId, 'emp_2');
      expect(records.first.payrollPeriodId, 'period_2026_01');
    });

    test('getPayrollRecords with non-matching combined filter returns empty', () async {
      final records = await repository.getPayrollRecords(
        payrollPeriodId: 'period_2026_02',
        employeeId: 'emp_3',
      );
      expect(records, isEmpty);
    });
  });

  group('MockPayrollRepository Employee Association Tests (HR-6.3)', () {
    test('getPayrollRecordsForEmployee returns all records for emp_1', () async {
      final records = await repository.getPayrollRecordsForEmployee('emp_1');

      expect(records.length, 2);
      expect(records.every((r) => r.employeeId == 'emp_1'), isTrue);
      expect(records.map((r) => r.payrollPeriodId).toSet(), {
        'period_2026_01',
        'period_2026_02',
      });
    });

    test('getPayrollRecordsForEmployee returns all records for emp_3', () async {
      final records = await repository.getPayrollRecordsForEmployee('emp_3');

      expect(records.length, 1);
      expect(records.first.id, 'pay_rec_103');
      expect(records.first.employeeId, 'emp_3');
      expect(records.first.payrollPeriodId, 'period_2026_01');
    });

    test('getPayrollRecordsForEmployee returns empty for employee without payroll (emp_4)', () async {
      final records = await repository.getPayrollRecordsForEmployee('emp_4');
      expect(records, isEmpty);
    });

    test('getPayrollRecordsForEmployee returns empty for unknown employee', () async {
      final records = await repository.getPayrollRecordsForEmployee('emp_unknown');
      expect(records, isEmpty);
    });

    test('enforces cross-employee isolation: emp_1 records never leak to emp_2', () async {
      final emp1Records = await repository.getPayrollRecordsForEmployee('emp_1');
      final emp2Records = await repository.getPayrollRecordsForEmployee('emp_2');

      final emp1Ids = emp1Records.map((r) => r.id).toSet();
      final emp2Ids = emp2Records.map((r) => r.id).toSet();

      expect(emp1Ids.intersection(emp2Ids), isEmpty);
      expect(emp1Records.every((r) => r.employeeId == 'emp_1'), isTrue);
      expect(emp2Records.every((r) => r.employeeId == 'emp_2'), isTrue);
    });

    test('preserves employeeId referencing Employee.id without inference from other fields', () async {
      final record = await repository.getPayrollRecordById('pay_rec_101');
      expect(record!.employeeId, 'emp_1');
      // Verify no employee name or email is stored in PayrollRecord
      expect(record.employeeId, isNot(contains('@')));
      expect(record.employeeId, isNot(contains('Alice')));
    });
  });

  group('MockPayrollRepository Immutability & Consistency Tests (HR-6.3)', () {
    test('returned period lists are defensively copied and caller mutation does not leak', () async {
      final periods1 = await repository.getPayrollPeriods();
      expect(periods1.length, 3);

      periods1.clear();
      expect(periods1, isEmpty);

      final periods2 = await repository.getPayrollPeriods();
      expect(periods2.length, 3);
    });

    test('returned record lists are defensively copied and caller mutation does not leak', () async {
      final records1 = await repository.getPayrollRecords();
      expect(records1.length, 5);

      records1.clear();
      expect(records1, isEmpty);

      final records2 = await repository.getPayrollRecords();
      expect(records2.length, 5);
    });

    test('repeated reads remain deterministic across periods and records', () async {
      final periodsA = await repository.getPayrollPeriods();
      final periodsB = await repository.getPayrollPeriods();
      expect(periodsA, equals(periodsB));

      final recordsA = await repository.getPayrollRecords();
      final recordsB = await repository.getPayrollRecords();
      expect(recordsA, equals(recordsB));
    });

    test('reset restores initial deterministic state', () async {
      store.reset();
      final periods = await repository.getPayrollPeriods();
      final records = await repository.getPayrollRecords();

      expect(periods.length, 3);
      expect(records.length, 5);
    });
  });

  group('MockPayrollRepository Failure Handling Tests (HR-6.3)', () {
    test('throws PayrollException when simulated failure is enabled for getPayrollPeriods', () async {
      store.setSimulatedFailure(true);

      expect(
        () => repository.getPayrollPeriods(),
        throwsA(
          isA<PayrollException>().having(
            (e) => e.message,
            'message',
            contains('Simulated repository failure'),
          ),
        ),
      );
    });

    test('throws PayrollException when simulated failure is enabled for getPayrollPeriodById', () async {
      store.setSimulatedFailure(true);

      expect(
        () => repository.getPayrollPeriodById('period_2026_01'),
        throwsA(isA<PayrollException>()),
      );
    });

    test('throws PayrollException when simulated failure is enabled for getPayrollRecords', () async {
      store.setSimulatedFailure(true);

      expect(
        () => repository.getPayrollRecords(),
        throwsA(isA<PayrollException>()),
      );
    });

    test('throws PayrollException when simulated failure is enabled for getPayrollRecordById', () async {
      store.setSimulatedFailure(true);

      expect(
        () => repository.getPayrollRecordById('pay_rec_101'),
        throwsA(isA<PayrollException>()),
      );
    });

    test('recovers normally after simulated failure is disabled', () async {
      store.setSimulatedFailure(true);
      expect(() => repository.getPayrollPeriods(), throwsA(isA<PayrollException>()));

      store.setSimulatedFailure(false);
      final periods = await repository.getPayrollPeriods();
      expect(periods.length, 3);
    });
  });

  group('MockPayrollRepository Dependency Composition Tests (HR-6.3)', () {
    test('can instantiate repository with default store', () {
      final defaultRepo = MockPayrollRepository();
      expect(defaultRepo, isA<PayrollRepository>());
    });

    test('can instantiate repository with custom store instance', () {
      final customStore = MockPayrollStore(seedInitialData: false);
      final customRepo = MockPayrollRepository(store: customStore);
      expect(customRepo.store, equals(customStore));
    });
  });
}
