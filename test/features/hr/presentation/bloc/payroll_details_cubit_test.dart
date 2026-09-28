import 'package:enterprise_crm/features/hr/data/mock/mock_payroll_store.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_employee_repository.dart';
import 'package:enterprise_crm/features/hr/data/repositories/mock_payroll_repository.dart';
import 'package:enterprise_crm/features/hr/domain/entities/payroll_record.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_details_cubit.dart';
import 'package:enterprise_crm/features/hr/presentation/bloc/payroll_details_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayrollDetailsCubit Tests (HR-6.6)', () {
    late MockPayrollStore store;
    late MockPayrollRepository repository;
    late MockEmployeeRepository employeeRepository;

    setUp(() {
      store = MockPayrollStore(seedInitialData: true);
      repository = MockPayrollRepository(store: store);
      employeeRepository = MockEmployeeRepository();
    });

    test('initial state has correct default values', () {
      final cubit = PayrollDetailsCubit(repository: repository);
      expect(cubit.state.status, PayrollDetailsStatus.initial);
      expect(cubit.state.record, isNull);
      expect(cubit.state.period, isNull);
      expect(cubit.state.employee, isNull);
      expect(cubit.state.recordId, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.hasRecord, isFalse);
      cubit.close();
    });

    test('loads initial record if initialRecordId is provided in constructor', () async {
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
        initialRecordId: 'pay_rec_101',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.status, PayrollDetailsStatus.loaded);
      expect(cubit.state.recordId, 'pay_rec_101');
      expect(cubit.state.record?.id, 'pay_rec_101');
      expect(cubit.state.record?.grossSalary, 85000.0);
      expect(cubit.state.period?.id, 'period_2026_01');
      expect(cubit.state.employee?.id, 'emp_1');
      expect(cubit.state.hasRecord, isTrue);

      await cubit.close();
    });

    test('loadRecord emits loading and loaded with resolved period and employee', () async {
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          PayrollDetailsStatus.loading,
          PayrollDetailsStatus.loaded,
        ]),
      );

      await cubit.loadRecord('pay_rec_102');
      await expectation;

      expect(cubit.state.recordId, 'pay_rec_102');
      expect(cubit.state.record?.id, 'pay_rec_102');
      expect(cubit.state.record?.employeeId, 'emp_2');
      expect(cubit.state.period?.name, 'January 2026');
      expect(cubit.state.employee?.fullName, 'Bob Miller');

      await cubit.close();
    });

    test('loadRecord emits notFound when record does not exist', () async {
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          PayrollDetailsStatus.loading,
          PayrollDetailsStatus.notFound,
        ]),
      );

      await cubit.loadRecord('non_existent_rec');
      await expectation;

      expect(cubit.state.status, PayrollDetailsStatus.notFound);
      expect(cubit.state.recordId, 'non_existent_rec');
      expect(cubit.state.record, isNull);
      expect(cubit.state.hasRecord, isFalse);

      await cubit.close();
    });

    test('loadRecord ignores empty or whitespace record IDs', () async {
      final cubit = PayrollDetailsCubit(repository: repository);

      await cubit.loadRecord('   ');

      expect(cubit.state.status, PayrollDetailsStatus.initial);
      await cubit.close();
    });

    test('repository failure emits failure with safe user-facing message', () async {
      store.setSimulatedFailure(true);
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      final expectation = expectLater(
        cubit.stream.map((s) => s.status),
        emitsInOrder([
          PayrollDetailsStatus.loading,
          PayrollDetailsStatus.failure,
        ]),
      );

      await cubit.loadRecord('pay_rec_101');
      await expectation;

      expect(cubit.state.status, PayrollDetailsStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Failed to load payroll record details.',
      );
      // Ensure no raw exception strings leak
      expect(cubit.state.errorMessage?.contains('Exception'), isFalse);
      expect(cubit.state.errorMessage?.contains('Stack'), isFalse);

      await cubit.close();
    });

    test('retry reloads the current record ID', () async {
      store.setSimulatedFailure(true);
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      await cubit.loadRecord('pay_rec_101');
      expect(cubit.state.status, PayrollDetailsStatus.failure);

      // Resolve failure
      store.setSimulatedFailure(false);
      await cubit.retry();

      expect(cubit.state.status, PayrollDetailsStatus.loaded);
      expect(cubit.state.record?.id, 'pay_rec_101');

      await cubit.close();
    });

    test('concurrency guard prevents stale responses on rapid record switching', () async {
      final cubit = PayrollDetailsCubit(
        repository: repository,
        employeeRepository: employeeRepository,
      );

      final future1 = cubit.loadRecord('pay_rec_101');
      final future2 = cubit.loadRecord('pay_rec_102');

      await Future.wait([future1, future2]);

      expect(cubit.state.recordId, 'pay_rec_102');
      expect(cubit.state.record?.id, 'pay_rec_102');
      expect(cubit.state.record?.employeeId, 'emp_2');

      await cubit.close();
    });

    test('PayrollDetailsState copyWith and clear flags work correctly', () {
      final record = PayrollRecord(
        id: 'rec_1',
        employeeId: 'emp_1',
        payrollPeriodId: 'period_1',
      );

      final state = PayrollDetailsState(
        status: PayrollDetailsStatus.loaded,
        recordId: 'rec_1',
        record: record,
        errorMessage: 'err',
      );

      final cleared = state.copyWith(
        clearRecord: true,
        clearErrorMessage: true,
      );

      expect(cleared.record, isNull);
      expect(cleared.errorMessage, isNull);
      expect(cleared.recordId, 'rec_1');
    });

    test('PayrollDetailsState equality and hashCode work correctly', () {
      const state1 = PayrollDetailsState(
        status: PayrollDetailsStatus.initial,
        recordId: 'rec_1',
      );
      const state2 = PayrollDetailsState(
        status: PayrollDetailsStatus.initial,
        recordId: 'rec_1',
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });
}
