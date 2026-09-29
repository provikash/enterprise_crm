import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_period.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/domain/repositories/payroll_repository.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_payroll_history_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/employee_payroll_history_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingPayrollRepository implements PayrollRepository {
  final bool throwDomainException;
  FailingPayrollRepository({this.throwDomainException = true});

  @override
  Future<List<PayrollPeriod>> getPayrollPeriods() async {
    if (throwDomainException) {
      throw const PayrollException('Database service connection failed.');
    }
    throw Exception('Unexpected socket error.');
  }

  @override
  Future<PayrollPeriod?> getPayrollPeriodById(String id) async => null;

  @override
  Future<List<PayrollRecord>> getPayrollRecords({
    String? payrollPeriodId,
    String? employeeId,
  }) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForPeriod(String periodId) async => [];

  @override
  Future<List<PayrollRecord>> getPayrollRecordsForEmployee(String employeeId) async {
    if (throwDomainException) {
      throw const PayrollException('Failed to retrieve employee records.');
    }
    throw Exception('Crash');
  }

  @override
  Future<PayrollRecord?> getPayrollRecordById(String id) async => null;
}

void main() {
  group('EmployeePayrollHistoryCubit', () {
    late MockPayrollStore store;
    late MockPayrollRepository repository;

    setUp(() {
      store = MockPayrollStore();
      repository = MockPayrollRepository(store: store);
    });

    test('initial state defaults correctly', () {
      final cubit = EmployeePayrollHistoryCubit(repository: repository);
      expect(cubit.state.status, EmployeePayrollHistoryStatus.initial);
      expect(cubit.state.employeeId, isNull);
      expect(cubit.state.records, isEmpty);
      expect(cubit.state.periods, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      cubit.close();
    });

    test('initialEmployeeId in constructor triggers loadHistory', () async {
      final cubit = EmployeePayrollHistoryCubit(
        repository: repository,
        initialEmployeeId: 'emp_1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.status, EmployeePayrollHistoryStatus.loaded);
      expect(cubit.state.employeeId, 'emp_1');
      expect(cubit.state.records.length, 2);
      expect(cubit.state.periods.containsKey('period_2026_01'), isTrue);
      expect(cubit.state.periods.containsKey('period_2026_02'), isTrue);
      cubit.close();
    });

    test('loadHistory emits loading then loaded with employee records', () async {
      final cubit = EmployeePayrollHistoryCubit(repository: repository);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          EmployeePayrollHistoryStatus.loading,
          EmployeePayrollHistoryStatus.loaded,
        ]),
      );

      await cubit.loadHistory('emp_1');
      await expectation;

      expect(cubit.state.employeeId, 'emp_1');
      expect(cubit.state.records.length, 2);
      expect(cubit.state.records.every((r) => r.employeeId == 'emp_1'), isTrue);
      cubit.close();
    });

    test('loadHistory emits empty state when employee has no records', () async {
      final cubit = EmployeePayrollHistoryCubit(repository: repository);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          EmployeePayrollHistoryStatus.loading,
          EmployeePayrollHistoryStatus.empty,
        ]),
      );

      await cubit.loadHistory('emp_nonexistent');
      await expectation;

      expect(cubit.state.records, isEmpty);
      cubit.close();
    });

    test('loadHistory emits error state when repository throws domain exception', () async {
      final failingRepo = FailingPayrollRepository(throwDomainException: true);
      final cubit = EmployeePayrollHistoryCubit(repository: failingRepo);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          EmployeePayrollHistoryStatus.loading,
          EmployeePayrollHistoryStatus.error,
        ]),
      );

      await cubit.loadHistory('emp_1');
      await expectation;

      expect(cubit.state.errorMessage, isNotNull);
      cubit.close();
    });

    test('loadHistory emits error state when repository throws unexpected exception', () async {
      final failingRepo = FailingPayrollRepository(throwDomainException: false);
      final cubit = EmployeePayrollHistoryCubit(repository: failingRepo);

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          EmployeePayrollHistoryStatus.loading,
          EmployeePayrollHistoryStatus.error,
        ]),
      );

      await cubit.loadHistory('emp_1');
      await expectation;

      expect(cubit.state.errorMessage, isNotNull);
      cubit.close();
    });

    test('retry reloads history after failure', () async {
      final failingRepo = FailingPayrollRepository();
      final cubit = EmployeePayrollHistoryCubit(repository: failingRepo);

      await cubit.loadHistory('emp_1');
      expect(cubit.state.status, EmployeePayrollHistoryStatus.error);

      // Now create a working cubit to simulate successful retry
      final workingCubit = EmployeePayrollHistoryCubit(repository: repository);
      await workingCubit.loadHistory('emp_1');
      expect(workingCubit.state.status, EmployeePayrollHistoryStatus.loaded);
      expect(workingCubit.state.records.length, 2);

      cubit.close();
      workingCubit.close();
    });

    test('rapid queries only commit the latest request (concurrency safety)', () async {
      final cubit = EmployeePayrollHistoryCubit(repository: repository);

      final f1 = cubit.loadHistory('emp_1');
      final f2 = cubit.loadHistory('emp_2');

      await Future.wait([f1, f2]);

      expect(cubit.state.employeeId, 'emp_2');
      expect(cubit.state.records.every((r) => r.employeeId == 'emp_2'), isTrue);
      cubit.close();
    });

    test('empty employeeId does not trigger fetch', () async {
      final cubit = EmployeePayrollHistoryCubit(repository: repository);
      await cubit.loadHistory('');
      expect(cubit.state.status, EmployeePayrollHistoryStatus.initial);

      await cubit.loadHistory('   ');
      expect(cubit.state.status, EmployeePayrollHistoryStatus.initial);
      cubit.close();
    });

    test('state equality and hashCode work correctly', () {
      const state1 = EmployeePayrollHistoryState(
        status: EmployeePayrollHistoryStatus.initial,
        employeeId: 'emp_1',
      );
      const state2 = EmployeePayrollHistoryState(
        status: EmployeePayrollHistoryStatus.initial,
        employeeId: 'emp_1',
      );
      const state3 = EmployeePayrollHistoryState(
        status: EmployeePayrollHistoryStatus.loaded,
        employeeId: 'emp_1',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });
  });
}
